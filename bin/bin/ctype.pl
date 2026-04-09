#!/usr/bin/env perl
use strict;
use warnings;
use FFI::Platypus 2.00;

my $ffi = FFI::Platypus->new(api => 2);
$ffi->lib(undef);

for my $name (qw(
    isalnum
    isalpha
    iscntrl
    isdigit
    isgraph
    islower
    isprint
    ispunct
    isspace
    isupper
    isascii
    isblank
    isxdigit
)) {
    $ffi->attach($name => ['int'] => 'int');
}

my %objects = (
    alnum  => \&isalnum,
    alpha  => \&isalpha,
    cntrl  => \&iscntrl,
    digit  => \&isdigit,
    graph  => \&isgraph,
    lower  => \&islower,
    print  => \&isprint,
    punct  => \&ispunct,
    space  => \&isspace,
    upper  => \&isupper,
    ascii  => \&isascii,
    blank  => \&isblank,
    xdigit => \&isxdigit,
);

sub usage {
    print <<'USAGE';
ctype - cli utility for character types as defined by POSIX

  Usage:
    ctype <type>          - print all characters belonging to <type>
    ctype is<type> <char> - return whether <char> belongs to <type>

  Types:
    alnum
    alpha
    cntrl
    digit
    graph
    lower
    print
    punct
    space
    upper
    ascii
    blank
    xdigit

USAGE
}

sub print_matching {
    my ($f) = @_;
    for my $i (0 .. 255) {
        print pack('C', $i) if $f->($i);
    }
}

sub main {
    my $argc = scalar(@ARGV) + 1;

    if ($argc < 2) {
        usage();
        exit 1;
    }

    my $verb    = $ARGV[0];
    my $subject = $ARGV[1];
    my $is_verb_found = 0;

    if ($verb eq '-h' || $verb eq '--help') {
        usage();
        exit 0;
    }

    if (index($verb, 'is') == 0) {
        if ($argc < 3) {
            print "Question without subject.\n";
            exit 3;
        }

        $verb = substr($verb, 2);

        {
            use bytes;
            if (length($subject) > 1) {
                print "Subject too long.\n";
                exit 4;
            }
        }

        if (exists $objects{$verb}) {
            my $ch;
            {
                use bytes;
                $ch = length($subject) ? substr($subject, 0, 1) : "\0";
            }

            exit($objects{$verb}->(ord($ch)) ? 0 : 1);
        }

        print "'$verb' is not a type.";
        exit 1;
    }

    if (exists $objects{$verb}) {
        print_matching($objects{$verb});
        $is_verb_found = 1;
    }

    if (!$is_verb_found) {
        print "'$verb' is not a type.";
        exit 1;
    }

    exit 0;
}

main();
