#!/usr/local/bin/perl5
# wktndx.pl - by furukawa@dkv.yamaha.co.jp
{
    my($tmp) = $0;
    while ($tmp =~ /^.*\//){
        unshift(@INC, $&);
        last if !-l $tmp;
        $tmp = $& . $tmp if ($tmp = readlink($tmp)) !~ /^\//;
    }
}

require 'pconfig.pl';
require 'lang.pl';
require 'euc.pl';
require 'inttype.pl';

&set_inttype;
$WKT = 'WKT';

while ($ARGV[0] =~ s/^\-//){
    $_ = shift;
    while (s/^.//){
        $Hiragana = 1 if $& eq 'h';
        $Katakana = 1 if $& eq 'k';
        if ($& eq 'w'){
            $_ = shift if $_ eq '';
            $WKT = $_;
            $_ = '';
        }
    }
}

$Kana = ($Hiragana && $Katakana);

sub wordlist{
    local($_, @word) = @_;

    tr/ NTa-z/\x80-\x9c/;
    while (s/^.//){
        $okuri = $&;
        foreach $_ (@word){
            next if $okuri eq "\x80" && length($_) <= 2;
            push(@WordList, "$_$okuri") if /^[\xb0-\xf4]/ || ($Hiragana && /^\xa4/) || ($Katakana && /^\xa5/);
        }
    }
}

while (<>){
    $_ = toEuc($_);
    if (s/^(\xa4[\xa1-\xf3]+)([a-z]?)[,\s]*((\/?[\xa1-\xfe][\xa1-\xfe])+)//){
        $yomi = $1;
        $okuri = $2;
        @word = split(/\//, $3);

        &wordlist($okuri, @word), next if $okuri;
        &wordlist(' ', @word), next if !/[\xa1-\xfe]/;

        # 本当は 2 バイト文字の境界を care しないといけないが、
        # たぶん大丈夫と祈りつつ…

        if (/(\xcc\xbe|\xca\xd1|\xc3\xb1)/ || /\xb7\xc1.*\xc6\xb0/){
            # 「名」詞、「変」格活用動詞、「単」漢字、「形」容「動」詞
            # は送りがな無し(面倒なので)
            &wordlist(' ', @word);
            next;
        }

        &wordlist('ik', @word), next if /\xb7\xc1/; # 「形」容詞
        &wordlist('r ', @word), next if /\xb0\xec/; # 「一」段動詞

        if (/[\xa4\xa5]\xab/){  # 「か」
            &wordlist('ki', @word);
            &wordlist('T', @word) if $yomi =~ /\xa4\xa4$/;
            next;
        }

        &wordlist('s', @word), next if /[\xa4\xa5]\xb5/; # 「さ」
        &wordlist('t', @word), next if /[\xa4\xa5]\xbf/; # 「た」
        &wordlist('n', @word), next if /[\xa4\xa5]\xca/; # 「な」
        &wordlist('mN', @word), next if /[\xa4\xa5]\xde/; # 「ま」
        &wordlist('y', @word), next if /[\xa4\xa5]\xe4/; # 「や」
        &wordlist('rT', @word), next if /[\xa4\xa5]\xe9/; # 「ら」
        &wordlist('g', @word), next if /[\xa4\xa5]\xac/; # 「が」
        &wordlist('z', @word), next if /[\xa4\xa5]\xb6/; # 「ざ」
        &wordlist('d', @word), next if /[\xa4\xa5]\xc0/; # 「だ」
        &wordlist('bN', @word), next if /[\xa4\xa5]\xd0/; # 「ば」
        &wordlist('wT', @word), next if /[\xa4\xa5][\xa2\xef]/; # 「あ」「わ」
        &wordlist(' ', @word);
    }
}

open(DIC, ">$WKT.d");
open(DICINDEX, ">$WKT.di");
binmode(DIC);
binmode(DICINDEX);

$Offset = 0;
$Code = 0xa1a1;
foreach $_ (sort @WordList){
    next if $_ eq $pre;
    $pre = $_;
    if (/^(.)(.)/){
        &putdicindex((ord($1) << 8) | ord($2));
        print DIC $_;
        $Offset += length($_);
    }
}
close(DIC);

&putdicindex(0xfefe);
close(DICINDEX);

sub putdicindex{
    my($ord) = @_;
    while ($Code <= $ord){
        print DICINDEX pack($IntType, $Offset);
        $Code += (0x1a1 - 0x0ff) if 0xff == (0xff & ++$Code);
    }
}
