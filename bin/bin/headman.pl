#!/usr/bin/perl

=head1 NAME

headman.pl - show declaration for C/C++ symbol

=head1 SYNOPSIS

  headman.pl [options] <symbol>
      --cpath <PATH>         : append default search path list
      --git-max-basename <N> : set git repository search hight
      --no-filter            : do not skip private directories

=head1 DESCRIPTION

Some C libraries ship with no documentation,
but have well commented, self-documenting headers.
Headman is intended for quickly pulling up such headers.

Files are displayed using C<$HEADMAN_PAGER> or the user's preferred pager.

"Cpath" is commonly used to refer to the -usually colon separated- list of directories
in which C compilers will look for header files.
Headman has a hardcoded default cpath,
which can be expanded using C<--cpath>, C<$CPATH> and/or C<$HEADMAN_CPATH>.

To speed up the searching,
"private" directories are skipped by default.
Many C libraries have their own conventions of what is considered private,
such as C<bits/> or C<detail/>.

=cut

use strict;
use warnings;
use feature 'signatures';

use File::Basename qw(basename dirname);
use File::Find qw(find);
use File::Spec;
use Getopt::Long qw(GetOptions);
use Text::ParseWords qw(shellwords);

use Data::Dumper;
$Data::Dumper::Terse = 1;

my $result = undef;
my $cli_cpath;
my $git_max_basename = 3;
my $no_filter = 0;
my @cpath = ();
my $symbol;

# ---

sub usage() {
    system("perldoc", $0);
}

sub find_git_root($path, $max_height) {
    return undef unless defined $path && length $path;

    $path = File::Spec->rel2abs($path);

    for (my $i = 0; $i < $max_height; $i++) {
        return $path if -e File::Spec->catfile($path, '.git');

        my $parent = dirname($path);
        last if !defined($parent) || $parent eq $path;
        $path = $parent;
    }

    return undef;
}

sub look_in_directory($dir, $symbol) {
    my @private_dirs = (
        'bits',     # glibc style
        'detail',   # boost style
        'private',  # Qt style
        'impl',     # Qt style
        'internal', # python style
        'arch',     # architecture-specific
    );

    my @extensions     = qw(h hh hpp hxx inc inl);
    my @include_args   = map { "--include=*.$_" } @extensions;
    my $escaped_symbol = quotemeta($symbol);
    my @exclude_args   = map { "--exclude-dir=$_"} @private_dirs if !$no_filter;

    # grep
    #  -R: recursive
    #  -I: ignore binary
    #  -w: match whole word
    #  -n: print line numbers
    #  -F: fixed string
    my $cmd = join(
        ' ',
        'grep -RIwnF',
        @include_args,
        @exclude_args,
        $escaped_symbol,
        $dir,
        '2>/dev/null'
    );

    # "speeds up" grep
    local $ENV{LC_ALL} = 'C';
    local $ENV{LANG}   = 'C';

    open my $fh, "-|", $cmd or die "grep failed: $!";
    while (my $line = <$fh>) {
        if ($line =~ m{^(.+?):(\d+):(.*)$}) {
            my ($file, $line_no, $content) = ($1, $2, $3);

            # ignore comments
            next if $content =~ s{^\s*\*}{}; # * comment continuation
            $content =~ s{//.*$}{};          # // comments
            $content =~ s{/\*.*$}{};         # /* comments
            next if $content !~ /\b\Q$symbol\E\b/;

            $result = [ $file, $line_no ];
            close $fh;
            return 1;
        }
    }
    close $fh;
    return 0;
}

sub cpath_split($cpath) {
    return () unless defined $cpath && length $cpath;

    my @parts = split /:/, $cpath, -1;

    return @parts;
}

sub pager_lhs() {
    my @candidates = (
        $ENV{HEADMAN_PAGER},
        $ENV{MANPAGER},
        $ENV{PAGER},
        $ENV{PERLDOC_PAGER},
        'less',
        'more',
        'cat',
    );

    for my $candidate (@candidates) {
        next unless defined $candidate && length $candidate;
        return $candidate;
    }

    exit 3;
}

sub open_in_pager($file, $line) {
    my $pager = pager_lhs();

    exec "$pager +$line $file";
}

# ---

do {
    my $help = 0;

    GetOptions(
        'cpath=s'            => \$cli_cpath,
        'git-max-basename=i' => \$git_max_basename,
        'no-filter'          => \$no_filter,
        'help'               => \$help,
    ) or do {
        usage();
        exit 1;
    };

    if ($help) {
        usage();
        exit 0;
    }

    if (@ARGV < 1) {
        usage();
        exit 1;
    }

    $symbol = $ARGV[0];
};

do {
    @cpath = (
        '/usr/local/include',
        '/usr/include',
        cpath_split($cli_cpath),
        cpath_split($ENV{'HEADMAN_CPATH'}),
        cpath_split($ENV{'CPATH'}),
        '.',
    );

    my $git_root = find_git_root('.', $git_max_basename);
    push @cpath, $git_root if defined $git_root;

    my %seen;
    @cpath = grep {
        defined($_) && length($_) && !$seen{$_}++
    } @cpath;
};

for my $dir (@cpath) {
    # NOTE:
    #  running this in a loop is not a bottleneck,
    #  but it does help to prevent specifying too many arguments to forks
    last if look_in_directory($dir, $symbol);
}

if (defined $result) {
    open_in_pager($result->[0], $result->[1]);
    exit 0;
} else {
    print STDERR "Could not find the declaration of '$symbol'.\n"
               . "Heuristic filtering of private directories was " . ($no_filter ? "off" : "on") . ".\n"
               . "Looked at: " . Dumper(\@cpath);
    exit 2;
}
