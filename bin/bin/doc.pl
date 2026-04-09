#!/usr/bin/perl

# XXX TEMT IMPLEMENTATION !!!

use strict;
use warnings;

my ($filetype, $word) = @ARGV;

my $cmd = '';

if ($filetype eq 'c') {
    $cmd = "man -s 3,2 $word || headman.pl $word";
}
elsif ($filetype eq 'cpp') {
    $cmd = "man -s 3,2 $word || cppman $word || headman.pl $word";
}
elsif ($filetype eq 'python') {
    $cmd = "pydoc $word";
}
elsif ($filetype eq 'tcl') {
    $cmd = "man n $word";
}
elsif ($filetype eq 'perl') {
    $cmd = "perldoc $word";
}
elsif ($filetype eq 'bash' || $filetype eq 'sh') {
    $cmd = "man 1 $word";
}
else {
    $cmd = "man 3 $word";
}

exec("/bin/sh", "-c", $cmd)
