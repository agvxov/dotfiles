#!/usr/bin/perl

=head1 Headman

=head2 NAME

headman.pl - show declaration for C/C++ symbol

=head2 SYNOPSIS

   headman.pl [options] <symbol>
   --cpath <PATH>         : append default search path list
   --git-max-basename <N> : set git repository search hight
   --force-build          : uncoditionally rebuild ze cache

=head2 DESCRIPTION

Some C libraries ship with no documentation,
but have well commented, self-documenting headers.
Headman is intended for quickly pulling up such headers.

You query a C symbol and you will be presented
with the appropriate file opened at the appropriate line.

Files are displayed using C<$HEADMAN_PAGER> or the user's preferred pager.

"Cpath" is commonly used to refer to the -usually colon separated- list of directories
in which C compilers will look for header files.
Headman has a hardcoded default cpath,
which can be expanded using C<--cpath>, C<$CPATH> and/or C<$HEADMAN_CPATH>.

Headman also tries to look inside the I<current project>,
which will either be a resonably close parent that is a git repository,
or the current directory.

To speed up the searching,
Headman generates a ctags cache from cpath.
The cache is managed automatically (i.e. created, updated).

Many C libraries have their own conventions of what is considered private,
such as C<bits/> or C<detail/>
"Private" directories are emmited during cache creation.
The list of private directory names are currently hardcoded.

=head2 HISTORY

The original version simply tried looking for the pattern
by iterating the system headers.
It was too slow.

The first rewrite started using the system grep, giving a 4x speed up.
The next problem was that cold page caches would prove to be 50x slower than hot ones,
yielding instead of a comfortable 0.2 second response time on my machine,
a horrendious 10 second.
It was too slow.

The (current) second rewrite initializes a ctags cache and binary-searches it.
The main bottleneck -I think- is running C<rsync> to determine which files have changed.

=cut

use strict;
use warnings;
use feature 'signatures';

use File::Basename qw(basename dirname);
use File::Find qw(find);
use File::Spec;
use File::Path qw(make_path remove_tree);
use File::BaseDir qw(cache_home);
use Getopt::Long qw(GetOptions);
use Text::ParseWords qw(shellwords);
use IPC::System::Simple qw(systemx);
use Search::Dict;

use Data::Dumper;
$Data::Dumper::Terse = 1;

my $result = undef;
my $cli_cpath;
my $git_max_basename = 3;
my $force_build = 0;
my @cpath = ();
my $symbol;
my $cache_dir = cache_home("headman");
my $database = $cache_dir . 'headman.tags';
my $snapshot = $cache_dir . 'headman-snapshot.d/';

# ---

sub usage() {
    system("perldoc", $0);
}

sub qxx(@cmd) {
    # Mimic systemx, but collect the output
    #print STDERR "@cmd\n";
    my $r = qx(@cmd);

    if ($?) {
        my $exit = $? >> 8;
        die "'@cmd' failed: $exit)\n";
    }

    return $r;
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
    #my @exclude_args   = map { "--exclude-dir=$_"} @private_dirs;

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
        #@exclude_args,
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

            return [$file, $line_no];
            close $fh;
            return 1;
        }
    }
    close $fh;
    return undef;
}

sub cpath_split($cpath) {
    return () unless defined $cpath && length $cpath;

    my @parts = split ':', $cpath, -1;

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
        'help'               => \$help,
        'force-build'        => \$force_build,
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
    );

    my %seen;
    @cpath = grep {
        defined($_) && length($_) && !$seen{$_}++
    } @cpath;
};


sub ctags_append($path) {
    my $common_kinds = "+p-h-m";
    systemx(shellwords(qq(
        ctags
        --recurse
        --append
        --excmd=number
        --languages=C,C++
        --kinds-C=$common_kinds --kinds-C++=$common_kinds-M
        -f $database $path
    )));
}

sub ctags_remove($path) {
    $path =~ s/\//\\\//g;
    systemx(shellwords(qq(sed --in-place '/\t$path\t/d' '$database')));
}

sub ctags_lookup($name) {
    my @matches;
    open my $fh, '<', $database or die "$database: $!";

    look $fh, $name, 0, 0;

    my $line = <$fh>;

    return undef if index($line, "$name\t") != 0;

    my @r = split "\t", $line;

    return [$r[1], substr($r[2], 0, length($r[2]) - 2)];
}

sub snapshot_create($path) {
    make_path($snapshot);
    systemx(shellwords(qq(cp --recursive --parents --attributes-only $path $snapshot)));
    utime time, time, "$snapshot/$path";
}

sub snapshot_update($path) {
    my @files = ();

    my $out = qxx(shellwords(qq(
                rsync
                --dry-run
                --update
                --recursive
                --times
                --progress
                '$path/'
                '$snapshot/$path/'
    )));

    @files = split "\n", $out;
    @files = grep { $_ !~ "/\$" } @files;
    @files = grep { $_ !~ "skipping" } @files;
    @files = grep { $_ !~ "sending" } @files;

    #print "-- $path ";
    #print Dumper( \@files );

    for my $f (@files) {
        my $full_path = "$path/$f";
        ctags_remove($full_path);
        ctags_append($full_path);
        snapshot_create($full_path);
    }
}

if (! -d $cache_dir) {
    make_path($cache_dir);
}

if ($force_build) {
    unlink($database);
    remove_tree($snapshot);
}

if (! -f $database or ! -d $snapshot) {
    print STDERR "Database not found, creating it...";
    STDERR->flush();
    for my $path (@cpath) {
        ctags_append($path);
        snapshot_create($path);
    }
    print STDERR "Done.\n";
} else {
    for my $path (@cpath) {
        snapshot_update($path);
    }
}

$result = ctags_lookup($symbol);

if (!defined $result) {
    my $git_root = find_git_root('.', $git_max_basename);
    my $search_root = $git_root // '.';
    $result = look_in_directory($search_root, $symbol);
}

if (defined $result) {
    open_in_pager($result->[0], $result->[1]);
    exit 0;
} else {
    print STDERR "Could not find the declaration of '$symbol'.\n"
               . "Looked at: " . Dumper(\@cpath);
    exit 2;
}
