EXTPROC perl.exe -Sx
#!/usr/bin/perl
#
# vfnmz.pl - program to view the NMZ.f file as HTML with lynx
# Version 1.0.1    [10/24/1998]
#
# Copyright (C) 1997-1998 Satoru Takabayashi  All rights reserved.
#     This is free software with ABSOLUTELY NO WARRANTY.
#
# patch for OS/2 by Kaz SHiMZ <kshimz@sfc.co.jp> [10/24/1998]

$VERSION = "1.0.0";
$COPYRIGHT = "Copyright (C) 1997-1998 Satoru Takabayashi  All rights reserved.";

$LYNX   = "lynx" ;         # lynx path
$SYSTEM = $^O;             # $^O contains system name

if ($SYSTEM eq "os2") {
    $TMP =   $ENV{TMPDIR};
    $TMP =   $ENV{TMP}     unless  $TMP  ;
    $TMP =   $ENV{TEMP}    unless  $TMP  ;
    $TMP =   $TMP . "/vfnmz.$$.html" ;
    $TMP =~  s|\\|/|g ;
} else {
    $TMP = "/tmp/vfnmz.$$.html";
}

if (defined($ARGV[0])) {
    $FINFO = $ARGV[0];
} else {
    print <<EOFusage;
  vfnmz.pl v$VERSION - program to view the NMZ.f file as HTML with lynx
  $COPYRIGHT

  usage: vfnmz.pl NMZ.f

EOFusage
    exit(1);
}

open(TMP, ">$TMP") || die "$! : $TMP\n";
open(FINFO, "$FINFO") || die "$! : ./NMZ.f\n";

print TMP <<EOM;
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0//EN"
        "http://www.w3.org/TR/REC-html40/strict.dtd">
<HTML>
<HEAD>
<TITLE>$FINFO</TITLE>
</HEAD>
<BODY LANG="en">
<H1>$FINFO</H1>
<HR>
<DL>
EOM

print TMP join('', <FINFO>);


print TMP <<EOM;
</DL>
<HR>
<P>
(bottom)
</P>
</BODY>
</HTML>
EOM
close(FINFO);
close(TMP);

if ($SYSTEM eq "os2") {
    $TMP2  =  $TMP ;
    $TMP2  =~  s/:/;/g ;
    $TMP2  = '"' . $TMP2 . '"' ;
    system("$LYNX $TMP2");
} else {
    system("$LYNX $TMP");
}

unlink($TMP);
