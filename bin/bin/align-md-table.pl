#!/usr/bin/perl
use strict;
use warnings;
use feature 'signatures';

sub usage() {
    print "Usage: prettify_table.pl [-h|--help]\n";
    print "Reads a Markdown table from stdin and prints a prettified version.\n";
    exit 0;
}

for my $arg (@ARGV) {
    if ($arg eq '-h' || $arg eq '--help') {
        usage();
    } else {
        die "Unknown argument: $arg\nUse -h for help.\n";
    }
}

sub line2array($line) {
    chomp $line;
    $line =~ s/^\s*\|?\s*//;
    $line =~ s/\s*\|?\s*$//;

    my @cells = map { my $c = $_; $c =~ s/^\s+|\s+$//g; $c } split /\|/, $line;

    my $alignment_cell_pattern = qr/^:?-+:?$/;
    return undef if $cells[0] =~ $alignment_cell_pattern;

    return \@cells;
}

sub markdown2table($s) {
    my @rows;
    for my $line (split /\n/, $s) {
        last unless $line =~ /\|/;
        my $row = line2array($line);
        next unless defined $row;
        push @rows, $row;
    }
    return \@rows;
}

sub table2column_widths($table) {
    my @widths;
    my $last_idx = $#{$table->[0]};

    for my $row (@$table) {
        for my $i (0 .. ($last_idx - 1)) {
            my $len = length($row->[$i]);
            $widths[$i] = $len if !defined $widths[$i] || $len > $widths[$i];
        }
    }

    $widths[$last_idx] = length($table->[0][$last_idx]);

    return \@widths;
}

sub print_prettified_table($table) {
    return unless @$table;

    my $widths   = table2column_widths($table);
    my $ncols    = scalar @$widths;
    my $last_idx = $ncols - 1;

    sub fmt_row($cells, $widths, $last_idx, $is_header) {
        my @parts;
        for my $i (0 .. $last_idx) {
            my $cell = $cells->[$i] // '';
            if ($i == $last_idx) {
                push @parts, " $cell ";
            } elsif ($is_header || $i == 0) {
                push @parts, sprintf(" %-*s ", $widths->[$i], $cell);
            } else {
                push @parts, sprintf(" %*s ", $widths->[$i], $cell);
            }
        }
        return '|' . join('|', @parts) . '|';
    }

    sub fmt_align($widths, $last_idx) {
        my @parts;
        for my $i (0 .. $last_idx) {
            my $w = $widths->[$i];
            if ($i == 0
            ||  $i == $last_idx) {
                push @parts, ' :' . '-' x ($w - 1) . ' ';
            } else {
                push @parts, ' ' . '-' x ($w - 1) . ': ';
            }
        }
        return '|' . join('|', @parts) . '|';
    }

    print fmt_row($table->[0], $widths, $last_idx, 1) . "\n";
    print fmt_align($widths, $last_idx) . "\n";

    for my $row (@{$table}[1 .. $#$table]) {
        print fmt_row($row, $widths, $last_idx, 0) . "\n";
    }
}

my $input = do { local $/; <STDIN> };

my $table = markdown2table($input);

die "No valid Markdown table found in input.\n" unless @$table;

print_prettified_table($table);
