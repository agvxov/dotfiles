#!/usr/bin/tclsh

package require Thread
package require unix_sockets

# NOTE: the exit code might be useless because i think vim jobs are auto killed

# --- Configuration & CLI
if {$argc != 2} {
    puts "Usage: $argv0 <pid> <tags-file>"
    exit 1
}

set parent_pid [lindex $argv 0]
set input_file [lindex $argv 1]
set socket_path "/tmp/completion-server-$parent_pid.sock"
set MAX_RESULTS 200

# --- Shared State
tsv::set shared words {}
tsv::set shared filtered_words {}
tsv::set shared query ""

# ---
set worker [thread::create {
    package require Thread

    # --- Completion Generation
    proc filter_words_simple {query words} {
        set r {}
        foreach w $words {
            if {[string first $query $w] == 0} { lappend r $w }
        }
        return $r
    }

    proc filter_words_case_insensitive {query words} {
        set r {}
        set q_low [string tolower $query]
        foreach w $words {
            if {[string first $q_low [string tolower $w]] == 0} { lappend r $w }
        }
        return $r
    }

    proc filter_words_smart {query words} {
        # If any character is uppercase, use simple (case-sensitive)
        if {[string compare [string tolower $query] $query] != 0} {
            return [filter_words_simple $query $words]
        } else {
            return [filter_words_case_insensitive $query $words]
        }
    }
        
    proc filter_words {query words max} {
        if {$query eq ""} { return "" }

        # Hardcoded to smart for now as requested
        set filtered [filter_words_smart $query $words]
        
        set deduped [lsort -unique $filtered]
        
        return [join [lrange $deduped 0 [expr {$max - 1}]] " "]
    }

    proc do_ignore_tags_entry {line} {
        set i [string index $line 0]
        if {$i eq "!"} { return 1 }
        if {$i eq "_"} { return 1 }
        return 0
    }

    proc get_words {file} {
		# Ctags field type filter
		# C++ ["variable", "function", "prototype", "typedef",
		#      "struct", "class", "enum (value)", "union",
		#      "enum", "macro", "extern variable"]
        set targets "vfptsceugdx"
		# Ctags noise entry filter
		set targets "${targets}lmz"

        set r [dict create]
        if {[catch {open $file r} f]} { return {} }
        
        while {[gets $f line] >= 0} {
			if {[do_ignore_tags_entry $line]} { continue }

            set fields [split $line "\t"]
            if {[llength $fields] < 4} { continue }
            
            set name [lindex $fields 0]
            set type [lindex $fields 3]
            
            if {[string first "operator" $name] != -1} { continue }
            if {[string first $type $targets] != -1} {
                dict set r $name 1
            }
        }
        close $f
        return [dict keys $r]
    }

    proc background_work {action file max} {
        if {$action eq "load"} {
            set w [get_words $file]
            tsv::set shared words $w
        } elseif {$action eq "filter"} {
            set q [tsv::get shared query]
            set w [tsv::get shared words]
            set f [filter_words $q $w $max]
            tsv::set shared filtered_words $f
        }
    }

    thread::wait
}]

# --- Server Logic (Main Thread)
proc handle_client {sock} {
    fconfigure $sock -blocking 0 -buffering line -translation lf
    fileevent $sock readable [list process_input $sock]
}

proc process_input {sock} {
    global worker input_file MAX_RESULTS
    if {[eof $sock] || [catch {gets $sock line}]} {
        close $sock
        return
    }
    
    set line [string trim $line]
    if {$line eq ""} return
    
    set prefix [string index $line 0]
    set arg [string trim [string range $line 1 end]]

    switch -exact -- $prefix {
        "?" { # Conf
            if {[tsv::get shared query] ne $arg} {
                tsv::set shared query $arg
                tsv::set shared filtered_words ""
                thread::send -async $worker [list background_work filter $input_file $MAX_RESULTS]
            }
        }
        "<" { # Bump
            tsv::set shared words {}
            tsv::set shared filtered_words ""
            thread::send -async $worker [list background_work load $input_file $MAX_RESULTS]
        }
        "=" { # Poll
            set filtered [tsv::get shared filtered_words]
            if {$filtered ne ""} {
                puts $sock "> $filtered"
            } else {
                puts $sock "- "
            }
        }
        "*" { # Debug All
            puts $sock "> [join [tsv::get shared words] " "]"
        }
        "#" { # Debug Filtered
            puts $sock "> [tsv::get shared filtered_words]"
        }
    }
}

proc check_parent {pid} {
    if {![file exists "/proc/$pid"]} { exit 0 }
    after 1000 [list check_parent $pid]
}

# --- Initialization
file delete -force $socket_path

unix_sockets::listen $socket_path handle_client

thread::send -async $worker [list background_work load $input_file $MAX_RESULTS]
check_parent $parent_pid

vwait forever
