#!/usr/bin/env perl
# Progress bars (H/M/S) for the day.

use strict;
use warnings;
use Term::ANSIColor;
use POSIX qw(strftime);

sub progress_bar {
    use constant L => 38;
    my ($n, $max) = @_;

    my $filled = int(($n / $max) * L);
    my $empty = L - $filled;

    print color('bold yellow');
    print '━' x $filled;
    print color('reset');
    print color('black bold');
    print '━' x $empty;
    print color('reset');
    print "\n";
}

sub display_time {
    my ($time) = @_;
    my ($hour, $min, $sec) = split ' ', strftime("%H %M %S", localtime($time));

    progress_bar $hour, 24;
    progress_bar $min,  60;
    progress_bar $sec,  60;
}

display_time time;
