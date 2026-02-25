#!/usr/bin/env tclsh
# qckmv - For each image, ask what subdirectory of PWD it should be moved to.

# Collect image files
set items {}
foreach pattern {*.jpg *.png} {
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
    puts "$current:"
    set h 1
    foreach d $dirs {
        puts " $h) $d"
        incr h
    }

    # Handle choice
    gets stdin choice

    set h 1
    foreach d $dirs {
        if {$choice == $h} {
            file rename $current $d/
            break
        }
        incr h
    }

    catch {exec kill $pid}

    set items [lrange $items 1 end]
}
