#!%OPT_PATH_PERL%
#
# gtnmz.pl - program to check the number of total indexed files
#
# Copyright (C) 1999 Satoru Takabayashi  All rights reserved.
#     This is free software with ABSOLUTELY NO WARRANTY.
#
die "usage: gtnmz NMZ.r > NMZ.total\n" if @ARGV == 0;

@tmp     = <>;
@tmp     = grep {! /^\#\#/} @tmp; 
@tmp     = grep {! /^$/} @tmp;

@added   = grep {! /^\#/} @tmp;
@deleted = grep {  /^\#/} @tmp;

$total = @added - @deleted;

print $total, "\n";
