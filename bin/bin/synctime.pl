#!/usr/bin/perl

use strict;
use warnings;
use LWP::Simple;
use HTML::TreeBuilder;

die "You must be root to perform this operation.\n" unless $> == 0;

my $SERVER = "https://www.pontosido.com/";

sub GetServerTime {
    my $content = get($SERVER) or die "Failed to fetch server time\n";
    my $tree = HTML::TreeBuilder->new_from_content($content);
    my $time = $tree->look_down(id => "clock")->as_text;
    $tree->delete;
    return $time;
}

sub GetServerDate {
    my $content = get($SERVER) or die "Failed to fetch server date\n";
    my $tree = HTML::TreeBuilder->new_from_content($content);
    my $date = $tree->look_down(class => "date")->as_text;
    $tree->delete;
    return $date;
}

sub SyncTime {
    my $datetime = GetServerDate() . " " . GetServerTime();
    $datetime =~ s/\./-/g;
    $datetime =~ s/- / /g;

    `date --set \"$datetime\"`;
    `hwclock --systohc`;
    `date`;
}

print "Initial time: " . `date`;

SyncTime();

print "Updated time: " . `date`;
