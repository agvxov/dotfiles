#!/usr/bin/perl
# POSIX cal + marks
#
# The file at $ENV{SPECIAL_DATES} will be parsed for significant dates
#  and marked displayed with highlighting.
# The format of the special dates file is a series of lines as follows:
#   YYYY-MM-DD(:DESCRIPTION);
# Any date portion may be replaced with * to mark a recurring occasion.
use strict;
use warnings;
use POSIX qw(strftime);

my $cal_alias = "cal --monday --color=always";
my $highlight = "\033[31;46m";
# ---

my $month = strftime("%m", localtime) + 0;
my $year  = strftime("%Y", localtime) + 0;

my @special_dates;
for my $entry (split /;/, $ENV{SPECIAL_DATES}) {
    if ($entry =~ /^(\*|\d{4})-(\d{2})-(\d{2})(?::(.*))?$/) {
        push @special_dates, {
            year  => $1,
            month => $2 + 0,
            day   => $3 + 0,
            msg   => $4 // ''
        };
    }
}

my @cal = `$cal_alias $month $year`;

sub mark_day {
    my ($day, $mon, $yr, $dates) = @_;
    foreach my $date (@$dates) {
        next if $date->{month} != $mon;
        next if $date->{year} ne '*' && $date->{year} != $yr;
        return "$highlight$day\033[0m" if $date->{day} == $day;
    }
    return $day;
}

foreach my $line (@cal) {
    $line =~ s/\b(\d{1,2})\b/ mark_day($1, $month, $year, \@special_dates) /ge;
    print $line;
}

for my $d (@special_dates) {
    next if $d->{year} ne '*' && $d->{year} != $year;
    next if $d->{month} != $month;
    printf " [%2d]: %s\n", $d->{day}, $d->{msg} if $d->{msg};
}
