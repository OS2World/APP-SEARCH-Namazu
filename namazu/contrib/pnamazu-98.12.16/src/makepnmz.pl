#!/usr/local/bin/perl5
# makepnmz.pl - by furukawa@dkv.yamaha.co.jp

$Makepnmz = $0;

$Magic = '#!/bin/sh';
$Source = 'namazu.pl';
$Ext = '.cgi';

$Pconfig = 'pconfig.pl';
@CmdLine = ('cmdline.pl', 'plain.pl');
@Bw = ('bw.pl', 'mb.pl', 'sb.pl');
@Reg = ('reg.pl');
@Remote = ('remote.pl');
@Field = ('field.pl');
@RmtFld = ('regconv.pl');

($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
$DATE = sprintf("%02d.%02d.%02d", $year, $mon+1, $mday);

while ($_ = shift){
    $lst = 1 if /lst/i;
    $strip = 1 if /strip/i;
    $zcat = 1 if /zcat/i;
    $cgi = 1 if /cgi/i;
    $nobw = 1 if /nobw/i;
    $noreg = 1 if /noreg/i;
    $noremote = 1 if /noremote/i;
    $nofield = 1 if /nofield/i;
    $zcat = 1, $Tail = $_ if /tail/i;
    $PerlPath = "#!$_\n" if /^\// && /perl/i;

    $Ext = '.' . (/^$/? shift: $_), next if s/^-e//;
    $Source = /^$/? shift: $_ if s/^-s//;
}
($Product = "p$Source") =~ s/\..*$//;

open(FH, $Source);
while (<FH>){
    $PerlPath = $_ if $. == 1 && /^\#\!/ && !$PerlPath;
    if (/^(\s*)require\s+['"](.*)["']/){
        $prespace = $1;
        $require = $2;

        if (!($cgi && grep(/$require/, @CmdLine))
            && !($nobw && grep(/$require/, @Bw))
            && !($noreg && grep(/$require/, @Reg))
            && !($noremote && grep(/$require/, @Remote))
            && !($nofield && grep(/$require/, @Field))
            && !($noremote && $nofield && grep(/$require/, @RmtFld))
            ){
            push(@Dist, "\n");
            open(FI, $require);
            while (<FI>){
                push(@Dist, "$prespace$_") if !/^#\!/ && !/^1/;
                eval($_) if ($require eq $Pconfig) && /^\s*\$Zcat\s*\=/;
            }
            close(FI);
            push(@Dist, "\n");
        }
        push(@Require, $require);
    }else{
        push(@Dist, $_);
    }
}
close(FH);

if ($lst){
    $Makepnmz =~ s/^.*\///;
    push(@Require, $Makepnmz) if -f $Makepnmz;
    push(@Require, $Source);
    foreach $_ (sort(@Require)){
        print "$_\n";
    }
}

if ($strip){
    my($tmp);

    @Dist = grep(!s/^\s*(\#.*)*$//, @Dist);
    while ($_ = shift(@Dist)){
        s/\s+\=\s+/\=/g;
        s/^\s*//;
        while (!/\#/ && $Dist[0] !~ /\<\</
               && !/require/ && $Dist[0] !~ /require/
               && ($Dist[0] =~ s/^\s+// || $Dist[0] =~ /^\}/)){
            chomp($_);
            s/\s+\=\s+/\=/g;

            if (length($_) + length($tmp = shift(@Dist)) < 1022){
                $_ .= ' ' if !/[\{\}\;,]$/;
                $_ .= $tmp;
            }else{
                push(@_, "$_\n");
                $_ = $tmp;
            }
        }
        push(@_, $_);
        if ($Dist[0] =~ /\<\<\s*\"([a-zA-Z_]\w*)\"/ ||
            $Dist[0] =~ /\<\<([a-zA-Z_]\w*)/){
            $str = $1;
            while ($_ = shift(@Dist)){
                push(@_, $_);
                last if /^$str/;
            }
        }
    }
    @Dist = @_;
}

if ($zcat){
    chomp($PerlPath);
    $PerlPath = "perl" if $PerlPath !~ s/^\#\!(\S+)/$1/;
    open(FO, ">$Product$Ext") || die;
    binmode(FO);
    print FO "$Magic\n";
    if ($Tail){
        print FO "$Tail +4 \$0|$Zcat|$PerlPath -\nexit\n";
        open(FO, "|gzip -9f>>$Product$Ext") || die;
    }else{
        print FO "$Zcat $Product.gz|$PerlPath -\n";
        open(FO, "|gzip -9f>$Product.gz") || die;
    }
}else{
    unshift(@Dist, $PerlPath) if $PerlPath;
    open(FO, ">$Product$Ext") || die;
}
binmode(FO);
print FO @Dist;
close(FO);
chmod 0755, "$Product$Ext";
