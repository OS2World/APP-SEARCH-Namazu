EXTPROC perl.exe -Sx
#!/usr/bin/perl
#
# clnmz.pl - protgram to replace URL in index
# Version 1.0.1    [06/18/1998]
#
# Copyright (C) 1997-1998 Satoru Takabayashi  All rights reserved.
#     This is free software with ABSOLUTELY NO WARRANTY.
#

$VERSION = "1.0.1";
$COPYRIGHT = "Copyright (C) 1998 Satoru Takabayashi  All rights reserved.";
$SYSTEM = "OS2";
$NKF    = "nkf2"; 

$USAGE  = <<EOFusage;
  clnmz.pl v$VERSION -  protgram to replace URL in index
  $COPYRIGHT

  usage: clnmz.pl orig_URL new_URL
       : replace orig_URL with new_URL in NMZ.f
EOFusage

&main;

sub main {
    if (!$opt_wordlist && ($SYSTEM eq "WIN32") || ($SYSTEM eq "OS2")) {
	open(SAVEOUT, ">&STDOUT");
	open(STDOUT, "|$NKF -s");
    }

    die &usage if @ARGV < 2;
    $from = $ARGV[0];
    $to   = $ARGV[1];

    # creat FLISTINDEX
    open(FLIST_IN , "NMZ.f") || die "NMZ.f: $!\n";
    open(FLIST_OUT , ">NMZ.f.$$") || die "NMZ.f_: $!\n";
    open(FLISTINDEX , ">NMZ.fi.$$") || die "NMZ.fi_: $!\n";
    binmode(FLISTINDEX);
    binmode(FLIST_IN);
    binmode(FLIST_OUT);

    $ptr = 0;
    $f = 1;
    $n = 0;
    while (<FLIST_IN>) {
	print FLISTINDEX pack("I", $ptr) if $f;
	if (($n % 5) == 1) {
	    s/<A HREF=\"$from(.*?)\">/<A HREF=\"$to$1\">/;
	} elsif (($n % 5) == 3) {
	    s/<A HREF=\"$from(.*?)\">$from(.*?)<\/A>/<A HREF=\"$to$1\">$to$2<\/A>/;
	}
	if (/^\n$/) { 
	    $f = 1;
	} else {
	    $f = 0;
	}
	print FLIST_OUT;
	$ptr += length;
	$n++;
    }
    close(FLIST_IN);
    close(FLIST_OUT);
    close(FLISTINDEX);
    Rename("NMZ.f.$$", "NMZ.f");
    Rename("NMZ.fi.$$", "NMZ.fi");
}

sub usage () {
    print $USAGE;
    exit;
}

# rename with consideration for OS/2
sub Rename($$) {
    my ($from, $to) = @_;

    unlink $to if ($SYSTEM eq "OS2") && (-f $from) && (-f $to);
    if (0 == rename($from, $to)) {
	die "rename($from, $to): $!\n";
    };
}
