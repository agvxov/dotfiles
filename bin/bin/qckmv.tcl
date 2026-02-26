#!/usr/bin/env tclsh
# qckmv - For each image, ask what subdirectory of PWD it should be moved to.

# Collect image files
set items {}
foreach pattern {*.jpg *.jpeg *.png *.gif *.webp} {
    foreach file [glob -nocomplain $pattern] {
        lappend items $file
    }
}

set items [lsort $items]

# Collect directories
set dirs {}
proc collect_dirs {path} {
    if {! [file isdirectory $path]} { return }

    lappend ::dirs $path

    foreach entry [glob -nocomplain -directory $path *] {
        collect_dirs $entry
    }
}
collect_dirs .

set dirs [lsort $dirs]

# Process each image
while {[llength $items] > 0} {
    set current [lindex $items 0]

    # Present image
    set pid [exec sh -c "nomacs \"$current\" > /dev/null 2>&1 & echo \$!"]

    after 500
    exec xdotool click 1

    # Print listing
    puts "\033\[34m$current:\033\[0m"
    set h 1
    foreach d $dirs {
        puts [format " %3d) %s" $h $d]
        incr h
    }

    # Handle choice
    set try_input 1
    while {$try_input} {
        gets stdin choice

        # skip command
        if {[regexp {^skip[[:space:]]+([0-9]+)$} $choice -> n]} {
            # Clamp N to list length
            catch { set items [lrange $items $n end] }
            set try_input 0
            break
        }

        # choice
        set h 1
        foreach d $dirs {
            if {$choice == $h} {
                # make move to . a nop
                if {$h != 1} {
                    file rename $current $d/
                }
                set try_input 0
                break
            }
            incr h
        }
    }

    catch {exec kill $pid}

    set items [lrange $items 1 end]
}
