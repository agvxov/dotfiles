#!/usr/bin/perl
use strict;
use warnings;
use POSIX qw(strftime);

my $start           = 2002;
my $end_of_the_line = 40;
my $current_year = strftime "%Y", localtime;

for my $i (0 .. $end_of_the_line - 1) {
    if ($i + $start < $current_year) {
        print "\033[31m▓\033[0m";
    } else {
        print "\033[35m░\033[0m";
    }
    print "\n" if $i % 10 == 9;
}
