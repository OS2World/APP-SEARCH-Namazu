#!/usr/local/bin/perl5
# bwnmz.pl - by furukawa@dkv.yamaha.co.jp
{
    my($tmp) = $0;
    while ($tmp =~ /^.*[\/\\]/){
        unshift(@INC, $&);
        last if !-l $tmp;
        $tmp = $& . $tmp if ($tmp = readlink($tmp)) !~ /^\//;
    }
}

require 'pconfig.pl';
require 'db.pl';
require 'inttype.pl';

while ($ARGV[0] =~ s/^-//){
    $_ = shift;
    $quiet = 1 if /q/;
    $force = 1 if /f/;
}

$DbPath = shift if @ARGV;
$DbPath = "NMZ" if !$DbPath;
&set_inttype;

if (open(FR, "$DbPath.r") && open(FT, ">>$DbPath.t")){
    seek(FT, 0, 2);
    $Siz = tell(FT) / $IntSize;

    seek(FT, 0, 0) if $force;
    $Ndx = tell(FT) / $IntSize;

    $Line = 0;
    while (<FR>){
        next if /^\#/;
        next if /^\s*$/;
        next if $Line++ < $Ndx;

        chomp;
        my($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,$atime,$mtime) = stat($_);
        if ($mtime || $Line >= $Siz){
            print FT pack($IntType, $mtime);
        }else{
            fseek(FT, $IntSize, 1);
        }

        printf("%s: %X\n", $_, $mtime) if !$quiet;
    }
    close(FR);
    close(FT);
}
