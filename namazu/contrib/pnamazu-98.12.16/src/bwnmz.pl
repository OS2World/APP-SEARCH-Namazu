#!/usr/local/bin/perl5
# bwnmz.pl - by furukawa@dkv.yamaha.co.jp
{
    my($tmp) = $0;
    $tmp = "./$tmp" if $tmp !~ /[\/\\]/;
    while ($tmp =~ /^.*[\/\\]/){
        unshift(@INC, $&);
        last if !-l $tmp;
        $tmp = $& . $tmp if ($tmp = readlink($tmp)) !~ /^\//;
    }
}

require 'pconfig.pl';
require 'db.pl';
require 'lang.pl';
require 'output.pl';
require 'bw.pl';
require 'mb.pl';
require 'sb.pl';
require 'inttype.pl';

while ($ARGV[0] =~ s/^-//){
    $_ = shift;
    $quiet = 1 if /q/;
    $do_s = 1 if /s/;
    $do_m = 1 if /m/;
}

$do_s = $do_m = 1 if !$do_s && !$do_m;

$DbPath = shift if @ARGV;
$DbPath = "NMZ" if !$DbPath;
&opendb($DbPath);
&set_inttype;

&bwnmz(*MB, *MBINDEX, 'm', \&mbchars, \&mbrev, $MbWordL, $MbWordR, $MbElem) if $do_m;
&bwnmz(*SB, *SBINDEX, 's', \&sbchars, \&sbrev, $SbWordL, $SbWordR, $SbElem) if $do_s;

sub mktbl{
    my($x) = @_;
    local($_);
    my($c1, $c2, $bigram, @bigram);
    $_ = &readindexindex($x);
    my($buf) = $_;

    &output("$_\n") if !$quiet;
    s/[^0-9A-Za-z\x80-\xff]/_/g;

    while (($c1, $c2) = &$Chars($_)){
        push(@bigram, "$c1$c2");
    }

    @bigram = sort(@bigram);
    foreach $_ (@bigram){
        next if $_ eq $bigram;
        $bigram = $_;
        $DAT{$_} .= pack($IntType, $x);
        $TBL{$_} .= "$buf " if !$quiet;
    }
}

sub mbrev{
    @Rev = ();
    for ($x = $MbByteL; $x <= $MbByteR; $x++){
        push(@Rev, chr($x));
    }
}

sub sbrev{
    @Rev = ();
    push(@Rev, '_');
    for ($x = ord('a'); $x <= ord('z'); $x++){
        push(@Rev, chr($x));
    }
    for ($x = 0; $x <= 9; $x++){
        push(@Rev, $x);
    }
}

sub bwnmz{
    local(*fH, *fHi, $ext, $chars, $rev, $wordL, $wordR, $elem) = @_;
    my($l) = &indexpointer(*HASH, $wordL);
    my($r) = &indexpointer(*HASH, $wordR + 1);
    my($exti) = $ext . 'i';
    my($hi, $lo, $strh, $str);
    my($offset) = 0;

    $Chars = $chars;
    @DAT = ();
    @TBL = ();

    &mktbl($l++) while $l < $r;

    if (open(fH, ">$DbPath.$ext") && open(fHi, ">$DbPath.$exti")){
        binmode(fH);
        binmode(fHi);

        &$rev;
        for ($hi = 0; $hi < $elem; $hi++){
            $strh = $Rev[$hi];
            for ($lo = 0; $lo < $elem; $lo++){
                $str = $strh . $Rev[$lo];
                print fHi pack($IntType, $offset);
                print fH $DAT{$str};
                &output("$str: $TBL{$str}\n") if $TBL{$str} && !$quiet;
                $offset += length($DAT{$str}) / $IntSize;
            }
        }
        close(fH);
        close(fHi);
    }
}
