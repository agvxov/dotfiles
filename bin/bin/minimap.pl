#!/usr/bin/env perl
use v5.36;
use utf8;
use strict;
use warnings;
use feature 'signatures';

binmode STDOUT, ':encoding(UTF-8)';

# Lines are padded and cropped according to this
my $forced_width = 80;

# --- CLI ---
my $fh;
if (@ARGV > 1) {
    die "usage: $0 [file]\n";
}
elsif (@ARGV == 1) {
    open($fh, '<:encoding(UTF-8)', $ARGV[0])
        or die "cannot open '$ARGV[0]': $!\n";
}
elsif (-t STDIN) {
    die "no input\n";
}
else {
    $fh = *STDIN;
}

# --- Parsing ---
my @matrix;
while (my $line = <$fh>) {
    chomp $line;

    my @chars = split //, $line;
    my @row   = (0) x $forced_width;

    my $limit = @chars < $forced_width ? @chars : $forced_width;
    for my $i (0 .. $limit - 1) {
        $row[$i] = ($chars[$i] =~ /\S/) ? 1 : 0;
    }

    push @matrix, \@row;
}

# pad height so it is divisible by 4
while (@matrix % 4 != 0) {
    push @matrix, [ (0) x $forced_width ];
}

# --- Rendering ---
sub cell2braille ($cell) {
    # $cell is an arrayref of 4 rows, each row contributing 2 columns:
    #   (x=0,y=0)->dot1   (x=1,y=0)->dot4
    #   (x=0,y=1)->dot2   (x=1,y=1)->dot5
    #   (x=0,y=2)->dot3   (x=1,y=2)->dot6
    #   (x=0,y=3)->dot7   (x=1,y=3)->dot8
    my $bits = 0;

    $bits |= 0x01 if $cell->[0][0];
    $bits |= 0x02 if $cell->[1][0];
    $bits |= 0x04 if $cell->[2][0];
    $bits |= 0x40 if $cell->[3][0];

    $bits |= 0x08 if $cell->[0][1];
    $bits |= 0x10 if $cell->[1][1];
    $bits |= 0x20 if $cell->[2][1];
    $bits |= 0x80 if $cell->[3][1];

    return chr(0x2800 + $bits);
}

for (my $y = 0; $y < @matrix; $y += 4) {
    my @out;

    for (my $x = 0; $x < $forced_width; $x += 2) {
        my $cell = [
            [ $matrix[$y + 0][$x + 0], $matrix[$y + 0][$x + 1] ],
            [ $matrix[$y + 1][$x + 0], $matrix[$y + 1][$x + 1] ],
            [ $matrix[$y + 2][$x + 0], $matrix[$y + 2][$x + 1] ],
            [ $matrix[$y + 3][$x + 0], $matrix[$y + 3][$x + 1] ],
        ];

        push @out, cell2braille($cell);
    }

    say join('', @out);
}
