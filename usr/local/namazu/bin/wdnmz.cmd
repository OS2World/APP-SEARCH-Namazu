EXTPROC perl.exe -Sx
#!/usr/bin/perl
#
# wdnmz.pl - program to output words list from index
# Version 1.0.6    [06/18/1998]
#
# Copyright (C) 1997-1998 Satoru Takabayashi  All rights reserved.
#     This is free software with ABSOLUTELY NO WARRANTY.
#

$VERSION = "1.0.6";
$COPYRIGHT = "Copyright (C) 1997-1998 Satoru Takabayashi  All rights reserved.";

$SYSTEM = "OS2";
$NKF    = "nkf2"; 
$LANGUAGE = "%OPT_LANGUAGE%";  # language of messages

$USAGE  = <<EOFusage;
  wdnmz.pl v$VERSION - program to output list of words from index
  $COPYRIGHT

  usage: wdnmz [-iw] NMZ.i
    (default): 'word'  TAB 'count of the word in index'
         -w: output list of words for regexp search
         -i: using NMZ.ii to process
  usually use: % wdnmz -w NMZ.i > NMZ.w)

EOFusage

&main;

sub main {
    while ($ARGV[0] =~ /^-/) {
	$opt_wordlist = 1 if $ARGV[0] =~ /w/;;
	$opt_with_nmz_ii = 1 if $ARGV[0] =~ /i/;;
	shift(@ARGV);
    }
    if ($LANGUAGE eq "ja" && 
	!$opt_wordlist && ($SYSTEM eq "WIN32") || ($SYSTEM eq "OS2")) {
	open(SAVEOUT, ">&STDOUT");
	open(STDOUT, "|$NKF -s");
    }

    die &usage if @ARGV == 0;
    $OBJFILE = shift (@ARGV);
    
    open(OBJFILE, $OBJFILE) || die "Can't open $OBJFILE!\n";
    binmode(OBJFILE);
    &getintsize;
    if ($opt_with_nmz_ii) {
	open(IDXFILE, $OBJFILE . "i") || die "Can't open $OBJFILEi!\n";
	binmode(IDXFILE);
	while (read(IDXFILE, $idx, $INTSIZE)) {
	    $idx = unpack("I", $idx);
	    seek(OBJFILE, $idx, 0);
	    $_ = <OBJFILE>;
	    read(OBJFILE, $n, $INTSIZE);
	    $nn = unpack("I", $n);
	    chop;
	    $nn /= 2;
	    if ($opt_wordlist) {
		print "$_\n";
	    } else {
		print "$_\t$nn\n";
	    }
	}
    } else {
	while(<OBJFILE>) {
	    read(OBJFILE, $n, $INTSIZE);
	    $nn = unpack("I", $n);
	    read(OBJFILE, $dummy, $INTSIZE * $nn);
	    <OBJFILE>;

	    chop;
	    $nn /= 2;
	    if ($opt_wordlist) {
		print "$_\n";
	    } else {
		print "$_\t$nn\n";
	    }
	}
    }
    if (($SYSTEM eq "WIN32") || ($SYSTEM eq "OS2")) {
	open(STDOUT, ">&SAVEOUT");
    }
}

sub usage () {
    print STDERR $USAGE;
    exit;
}

# checke the size of int
sub getintsize {
    $tmp = 0;
    $tmp = pack( "I", $tmp );
    $INTSIZE = length( $tmp );
}

