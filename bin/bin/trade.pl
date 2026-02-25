#!/usr/bin/perl
# Display whether HU/US stock markets are currently open or not.
use strict;
use warnings;
use Time::Piece;

sub display_state {
    my ($state, $comment) = @_;

    if ($state) {
        print "\e[32m●\e[0m"; # green
    } else {
        print "\e[38;5;239m●\e[0m"; # gray
    }

    print "$comment\n";
}

my $hour = localtime->hour;
display_state((9 <= $hour && $hour <= 17),  "  9:00-17:00 HU");
display_state((16 <= $hour && $hour <= 22), " 16:00-22:00 US");
