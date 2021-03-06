EXTPROC perl.exe -Sx
#!/usr/bin/perl
#
# mailutimepl - program to unify the file time stamp with 
#               the RFC 822 'Date:' field
# Version 1.0.2    [12/12/1998]
#
# Copyright (C) 1998 Satoru Takabayashi  All rights reserved.
#     This is free software with ABSOLUTELY NO WARRANTY.
#
# USAGE:
#
#   usage: mailutime <Target_Files...>
#
#
# RECOMMENDED USAGE:
#
#   % find . -type f ~/Mail/ml/hoge |xargs mailutime
#
#   It is very useful way to modify all the time stamp of files in the 
#   specified mailbox (MH format).
#

require 5.004;
use strict;
use IO::File;
use Time::Local;
$| = 1;   # autoflush output 

my %month_names = ("Jan" => 0, "Feb" => 1, "Mar" => 2, "Apr" => 3, 
		   "May" => 4, "Jun" => 5, "Jul" => 6, "Aug" => 7, 
		   "Sep" => 8, "Oct" => 9, "Nov" => 10, "Dec" => 11);
my $re_month =  join '|', keys %month_names;
my $re_day   =  '(?:0?[1-9]|[12][0-9]|3[01])';
my $re_year  =  '(?:\d\d\d\d+|[0456789]\d)';  # allow 2 digit fomrat
my $re_hour  =  '(?:[01][0-9]|2[0-3])';
my $re_min   =  '(?:[012345][0-9])';
my $re_sec   =  '(?:[012345][0-9])';

my $DebugOpt = 0;
    
main();

sub main () {
    foreach my $file (@ARGV) {
	my $date;
	my ($fh) = new IO::File;
	$fh->open("$file") || die "$!: $file\n";
	while (<$fh>) {
	    last if /^$/;
	    $date = $1 if /^Date: (.*)/i;
	}
	unless (defined($date)) {
	    print STDERR "$file: 'Date:' not found!\n";
	    next;
	}
	$fh->close;

	my $time = rfc822time($date);
	if ($time == -1) {
	    print STDERR "Warning! $file: [$date] is not rfc822 format! \n";
	    print STDERR "\t\t\t\ttrying fuzzy mode...\n";
	    $time = get_date_fuzzily($date);
	}
	if ($time != -1) {
	    utime($time, $time, $file);
	    print "Complete! $file: $date -> $time\n";
	} else {
	    print STDERR "$file: [$date] malformed 'Date:' format! \n";
	    next;
	}
    }
}

# calculate time from the RFC 822 'Date: ' field string like:
#   'Thu, 18 Dec 1997 21:09:43 GMT'
# a timezone and its adjustment such as GMT or +0900 would be ignored.
sub rfc822time($) {
    my ($date) = @_;

    if ($date =~ /
	^\s*
	\w{3},\s+                          # a day of the week (ignored)
	($re_day)\s+                       # a day of the month
	($re_month)\s+                     # name of month
	($re_year)\s+                      # year
	($re_hour):($re_min):($re_sec)     # HH:MM:SS
	/x) 
    {
	my ($mday, $mon, $year, $hour, $min, $sec) = ($1, $2, $3, $4, $5, $6);
	$year += 2000 if $year < 50;
	$year += 1900 if 50 <= $year && $year <= 99;
	$mon = $month_names{$mon};
	my $mtime = timelocal($sec, $min, $hour, $mday, $mon, $year);
	return $mtime;
    } else {
	return -1; # return with error
    }
}

# calculate the time from string 
# INPUT is such as:  'Thu, 18 Dec 1997 21:09:43 GMT' (RFC 822 format)
# This routine allows a certain measure of fuzziness.
# timezone and its adjustment would be ignored such as GMT or +0900
sub get_date_fuzzily($) {
    my ($orig_str) = @_;
    my $str = $orig_str;
    my ($sec, $min, $hour, $mday, $mon, $year);
    my ($mtime);

    # remove a timezone adjustment such as '+0900'
    $str =~ s/(\+\d+)//;

    # get the hour, min and sec.
    if ($str =~ s/\b($re_hour):($re_min):($re_sec)\b//) {
	$hour = $1;
	$min  = $2;
	$sec  = $3;
    } else {
	print STDERR "[$orig_str]:: lacks 'hour:min:sec'\n" if $DebugOpt;
	$hour = 0;
	$min  = 0;
	$sec  = 0;
    }

    # get the month
    if ($str =~ s/\b($re_month)\b//i) {
	$mon = $month_names{$1};
    } else {
	print STDERR "[$orig_str]:: lacks 'month'\n" if $DebugOpt;
	$mon = 0;
    }

    # get the year
    # CAUTION: YEAR 10,000 problem is creeping :-)
    if ($str =~ s/\b($re_year)\b//i) {
	$year = $1;
    } else {
	print STDERR "[$orig_str]:: lacks 'year'\n" if $DebugOpt;
	$year = 1970;
    }

    # get the day using little bit tricky regex :-)
    # this SHOULD be tried at the last.
    if ($str =~ s/\b($re_day)\b//i) {
	$mday = $1;
    } else {
	print STDERR "[$orig_str]:: lacks 'day'\n" if $DebugOpt;
	$mday = 0;
    }

    # calculate
    $mtime = timelocal($sec, $min, $hour, $mday, $mon, $year);

    if ($DebugOpt) {
	print STDERR 
	    "DATE:: [$orig_str] -> $year, $mon, $mday, $hour, $min, $sec" .
		"->$mtime\n" if $DebugOpt;
    }
    return $mtime;
}

