#!/usr/local/bin/perl5
# kwnmz.pl - by furukawa@dkv.yamaha.co.jp
# NMZ.f に keyword を付加する
{
    my($tmp) = $0;
    $tmp = "./$tmp" if $tmp !~ /[\/\\]/;
    while ($tmp =~ /^.*[\/\\]/){
        unshift(@INC, $&);
        last if !-l $tmp;
        $tmp = $& . $tmp if ($tmp = readlink($tmp)) !~ /^\//;
    }
}

require 'nmztxt.pl';

# テンポラリファイルの設定
$W = 'WORD.tmp';
$FI = 'FLIST_I.tmp';
$FO = 'FLIST_O.tmp';

$| = 1;
&nmztxt::init('NMZ');
# データベース -> テキストの変換
&nmztxt::flist2txt($FI);
&nmztxt::word2txt($W);


# つけ加える Keywords の数
$KW = 10;

# ヒットする文書が多すぎる語は、Keywords として不適
# とりあえず、文書数の半分を基準に
$lim = int($nmztxt::FILE / 2);


# テキストの加工
$/ = '';
open(W, $W);
while (defined($welem = <W>)){
    # カタカナ 3 文字以上、漢字 2 文字以上の語が対象
    if ($welem =~ /^(\xa5.){3}/ || $welem =~ /^([\xb0-\xf4].){2}/){
        ($word, @hits) = split(/\n/, $welem);
        $hitnum = scalar(@hits);

        # ヒット数が多すぎる語は、絞りこみに役立たない
        next if $hitnum > $lim;

        # ヒット数が 1 の語は、その語を含む他の文書が存在しないことを
        # 意味するので、関連文書を引き出すのに役立たない
        next if $hitnum <= 1;

        for $helem (@hits){
            ($fileno, $score) = split(/\s+/, $helem);
            $tfidf{$fileno}{$word} = $score / log($hitnum)
        }
    }
}

open(FI, $FI);
open(FO, ">$FO");
while (defined($felem = <FI>)){
    ($fileno, $r, $dt, $st, $summary, $dd) = split(/\n/, $felem, 6);
    $summary =~ s/\<\!\-\- KW \-\-\>.*//;
    $summary .= '<!-- KW --><BR><STRONG>Keywords</STRONG>:<EM>';
    $h = $hit{$fileno};
    $s = $score{$fileno};
    $t = $tfidf{$fileno};

    # tf idf 法モドキにソート
    @wlist = sort {($t->{$a} <=> $t->{$b}) || ($a cmp $b)} keys %$t;

    for $word (@wlist[0..($KW-1)]){
        $word =~ s/[\x80-\xff]+/\e\$B$&\e\(B/g;
        $word =~ tr/\x80-\xff/\x00-\x7f/;
        $summary .= " $word";
    }
    $summary .= '</EM>';
    $felem = "$fileno\n$r\n$dt\n$st\n$summary\n$dd";
    print FO "$felem\n\n";
}
close(FI);
close(FO);

# データベースに書き戻す
&nmztxt::txt2flist($FO);
&nmztxt::end;

unlink($W);
unlink($FI);
unlink($FO);

# おしまい。
