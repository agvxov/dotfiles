#!/usr/bin/perl

use strict;
use warnings;
use feature 'signatures';

use File::Slurp qw(write_file);
use Getopt::Long qw(GetOptionsFromArray);
use File::Basename qw(dirname);
use Cwd qw(abs_path);
use FindBin;

require "$FindBin::Bin/import-collector";

my $input_filename     = '';
my $tags_filename      = 'vim.tags';
my $polution_directory = './';
my $action             = 'hi';

# --- Console
sub print2($s) { print STDERR "$s\n" }

sub usage($exit_code) {
    print2("Usage: $0 <options> <verb>");
    print2("\t-h");
    print2("\t-i <file> : input");
    print2("\t-t <path> : polution directory");
    print2("\t---");
    print2("\thi");
    print2("\tsig");
    exit($exit_code);
}

sub opts(@args) {
    usage(1) if grep { $_ eq '--help' } @args;

    GetOptionsFromArray(
        \@args,
        'h|help' => sub { usage(0) },
        'i=s'    => \$input_filename,
        't=s'    => \$polution_directory,
    ) or usage(1);

    for my $arg (@args) { # this is terrible
        $action = 'hi'  if $arg eq 'hi';
        $action = 'sig' if $arg eq 'sig';
    }

    usage(1) if $input_filename eq '';
}

# --- Highlighting
sub hi($group) { return "syn keyword\t\tHiTag${group} %s" }

my @targets = (
    { type => 'v', out => hi('Special')    },
    { type => 'f', out => hi('Function')   },
    { type => 'p', out => hi('Function')   },
    { type => 't', out => hi('Type')       },
    { type => 's', out => hi('Type')       },
    { type => 'c', out => hi('Type')       },
    { type => 'e', out => hi('Type')       },
    { type => 'u', out => hi('Type')       },
    { type => 'g', out => hi('Type')       },
    { type => 'd', out => hi('Constant')   },
    { type => 'x', out => hi('Identifier') },
);

# --- Ctags
use constant {
    NAME_INDEX    => 0,
    PATTERN_INDEX => 2,
    TYPE_INDEX    => 3,
};

my @has_signature = ('f', 'p');

sub do_ignore($row) {
    my $IGNORE_IF_BEGINS_WITH = '!_';
    for my $i (split //, $IGNORE_IF_BEGINS_WITH) {
        return 1 if substr($row->[0] // '', 0, 1) eq $i;
    }
    return 1 if index($row->[NAME_INDEX] // '', 'operator') != -1;
    return 0;
}

sub filelist2tags(@filelist) {
    my $filelist_path = "$polution_directory/ctags-filelist.txt";
    write_file($filelist_path, join("\n", @filelist) . "\n");

    my $output = "$polution_directory/$tags_filename";

    my $cmd = "ctags --recurse --extras=+F --kinds-C=+px -o $output -L $filelist_path";
    system($cmd);
    return $output;
}

sub tags2hi($filename) {
    my %output;

    open(my $f, '<', $filename) or do {
        print2("$0: No such file or directory '$filename'.");
        exit(1);
    };

    while (my $line = <$f>) {
        chomp $line;
        my @row = split /\t/, $line;
        next if do_ignore(\@row);
        for my $t (@targets) {
            next unless defined $row[TYPE_INDEX];
            if ($t->{type} eq $row[TYPE_INDEX]) {
                my $pattern = quotemeta($row[NAME_INDEX]);
                $output{sprintf($t->{out}, $pattern)} = 1;
            }
        }
    }

    close($f);

    return keys %output;
}

sub pattern2signature($name, $pattern) {
    my $start = index($pattern, $name);
    my $end   = index($pattern, ')') != -1
              ? index($pattern, ')') + 1
              : index($pattern, '$');
    return substr($pattern, $start, $end - $start);
}

sub tags2sigs($filename) {
    my %output;
    my @order;

    open(my $f, '<', $filename) or die "$filename: $!";

    while (my $line = <$f>) {
        chomp $line;
        my @row = split /\t/, $line;
        next if do_ignore(\@row);
        next unless defined $row[TYPE_INDEX];
        if (grep { $_ eq $row[TYPE_INDEX] } @has_signature) {
            my $signature = pattern2signature($row[NAME_INDEX], $row[PATTERN_INDEX]);
            if (exists $output{$row[NAME_INDEX]}) {
                push @{$output{$row[NAME_INDEX]}}, $signature;
            } else {
                $output{$row[NAME_INDEX]} = [$signature];
                push @order, $row[NAME_INDEX];
            }
        }
    }

    close($f);

    return (\%output, \@order);
}

sub siglist2vimliteral($output, $order) {
    return '{' . join(', ', map {
        my $sigs = join(', ', map { "'$_'" } @{$output->{$_}});
        "'$_': [$sigs]"
    } @$order) . '}';
}

sub main(@argv) {
    opts(@argv);

    my $output;
    if ($action eq 'hi') {
        my @filelist = (
            $input_filename,
        );

        my ($collected, $error, @extra) = ImportCollector::collect_imports($input_filename);
        die $error if $error;
        push @filelist, @$collected;

        my $tags = filelist2tags(@filelist);
        $output = join("\n", sort(tags2hi($tags)));
    } elsif ($action eq 'sig') {
        my ($sigs, $order) = tags2sigs(filelist2tags($input_filename));
        $output = "let signatures = " . siglist2vimliteral($sigs, $order);
    }
    print "$output\n";
}

main(@ARGV);
