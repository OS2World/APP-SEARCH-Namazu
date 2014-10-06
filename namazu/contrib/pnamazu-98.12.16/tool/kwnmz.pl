#!/usr/local/bin/perl5
# kwnmz.pl - by furukawa@dkv.yamaha.co.jp
# NMZ.f �� keyword ���ղä���
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

# �ƥ�ݥ��ե����������
$W = 'WORD.tmp';
$FI = 'FLIST_I.tmp';
$FO = 'FLIST_O.tmp';

$| = 1;
&nmztxt::init('NMZ');
# �ǡ����١��� -> �ƥ����Ȥ��Ѵ�
&nmztxt::flist2txt($FI);
&nmztxt::word2txt($W);


# �Ĥ��ä��� Keywords �ο�
$KW = 10;

# �ҥåȤ���ʸ��¿�������ϡ�Keywords �Ȥ�����Ŭ
# �Ȥꤢ������ʸ�����Ⱦʬ�����
$lim = int($nmztxt::FILE / 2);


# �ƥ����Ȥβù�
$/ = '';
open(W, $W);
while (defined($welem = <W>)){
    # �������� 3 ʸ���ʾ塢���� 2 ʸ���ʾ�θ줬�о�
    if ($welem =~ /^(\xa5.){3}/ || $welem =~ /^([\xb0-\xf4].){2}/){
        ($word, @hits) = split(/\n/, $welem);
        $hitnum = scalar(@hits);

        # �ҥåȿ���¿�������ϡ��ʤꤳ�ߤ���Ω���ʤ�
        next if $hitnum > $lim;

        # �ҥåȿ��� 1 �θ�ϡ����θ��ޤ�¾��ʸ��¸�ߤ��ʤ����Ȥ�
        # ��̣����Τǡ���Ϣʸ�������Ф��Τ���Ω���ʤ�
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

    # tf idf ˡ��ɥ��˥�����
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

# �ǡ����١����˽��᤹
&nmztxt::txt2flist($FO);
&nmztxt::end;

unlink($W);
unlink($FI);
unlink($FO);

# �����ޤ���
