EXTPROC perl.exe -Sx
#!/usr/bin/perl
#
# rvnmz.pl - program to change the byte order of index
# Version 1.0.2    [06/18/1998]
#
# Copyright (C) 1998 Satoru Takabayashi  All rights reserved.
#     This is free software with ABSOLUTELY NO WARRANTY.
#

$VERSION = "1.0.2";
$COPYRIGHT = "Copyright (C) 1997-1998 Satoru Takabayashi  All rights reserved.";

$SYSTEM = "OS2";
$NKF    = "nkf2"; 

$USAGE  = <<EOFusage;
  rvnmz.pl v$VERSION -  program to change the byte order of index
  $COPYRIGHT

  usage: rvnmz.pl Go
       : change the byte order of index
EOFusage

&main;

sub main {
    die &usage if @ARGV == 0;
    die &usage if $ARGV[0] ne "Go";
    &getintsize;

    if (-f "NMZ.le") {
	print "Change the byte order from little-endian to big-endian.\n";
	$OppositeEndian = 1 if (&is_big_endian());
    } elsif (-f "NMZ.be") {
	print "Change the byte order from big-endian to little-endian.\n";
	$OppositeEndian = 1 if (!&is_big_endian());
    }

    $in_file = "NMZ.i";
    $out_file = "$in_file.rv.$$";

    open(IN, "$in_file") || die "Can't open $in_file!\n";
    binmode(IN);
    open(OUT, "> $out_file") || die "Can't open $out_file!\n";
    binmode(OUT);

    print "Processing $in_file.\n";
    while(<IN>) {
	chop;
	read(IN, $n, $INTSIZE);
	$tmp = $n;
	$tmp = &reverse_byte_order($n) if $OppositeEndian;
	$nn = unpack("I", $tmp);
	read(IN, $buf, $INTSIZE * $nn);
	$buf = $n . $buf;
	$buf = &reverse_byte_order($buf);
	print OUT "$_\n$buf\n";
	<IN>;
    }
    close(IN);
    close(OUT);
    Rename($in_file, "$in_file.orig");
    Rename($out_file, $in_file);

    foreach $in_file ("NMZ.ii", "NMZ.fi", "NMZ.h", "NMZ.p", "NMZ.pi") {
	print "Processing $in_file.\n";
	$out_file = "$in_file.rv.$$";
	open(IN, "$in_file") || die "Can't open $in_file!\n";
	binmode(IN);
	open(OUT, "> $out_file") || die "Can't open $out_file!\n";
	binmode(OUT);
	read(IN, $buf, -s $in_file);
	$buf = &reverse_byte_order($buf);
	print OUT "$buf";
	close(IN);
	close(OUT);
	Rename($in_file, "$in_file.orig");
	Rename($out_file, $in_file);
    }
    print "done.\n";
    if (-f "NMZ.le") {
	Rename("NMZ.le", "NMZ.be");
    } elsif (-f "NMZ.be") {
	Rename("NMZ.be", "NMZ.le");
    }
}

sub usage () {
    print $USAGE;
    exit;
}

# check the size of int
sub getintsize {
    $tmp = 0;
    $tmp = pack( "I", $tmp );
    $INTSIZE = length( $tmp );
}

# rename with consideeration for OS/2
sub Rename($$) {
    my ($from, $to) = @_;

    unlink $to if ($SYSTEM eq "OS2") && (-f $from) && (-f $to);
    rename($from, $to);
}

# checke the byte order of the machine
sub is_big_endian() {
    if (ord(pack('I', 1)) == 1) {
	return 0;
    } else {
	return 1;
    }
}

sub reverse_byte_order($) {
    my ($buf) = @_;

    if ($INTSIZE == 4) {
	$buf =~ s/(.)(.)(.)(.)/$4$3$2$1/gs;
    } elsif ($INTSIZE == 8) {
	$buf =~ s/(.)(.)(.)(.)(.)(.)(.)(.)/$8$7$6$5$4$3$2$1/gs;
    } else {
	die "Your processor is not supported.\n";
    }
    $buf;
}
