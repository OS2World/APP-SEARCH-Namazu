#!/usr/local/bin/perl5

# pnamazu.cgi-98.12.16
# Namazu Search (perl ��) by furukawa@dkv.yamaha.co.jp

# ���Υ�����ץȤ� Namazu Version 1.1.1.1 �� srnmz.c �򻲹ͤˡ�
# ���Ϸ�̤������褦�ʴ����ˤʤ�褦�ˡ�����������˽񤤤���ΤǤ���

# 1. �����餯�Х�������ޤ���
# 2. ��οȤΤޤ��Ρ������¤�줿�ǡ��������ƥ��Ȥ��Ƥ��ޤ���
# 3. ���顼��������ϡ����¤��Ƥ��ޤ���

# ���� 
#       '+': ��������
#       '?': �Ū����
#       '-': ���ͤκ��
#       '*': ���ΰʳ��λ���
#       '!': ����
# 98.12.16
#   ! ���٤� 2byte ʸ���������ɽ�������� 2 �İʾ夷�褦�Ȥ���ȡ�
#     2 ���ܰʹߤ����Ĥ���ʤ��Х�����
#   * nmztxt.pl �����ͤ˥��������Τ���
#   * nmztxt.pl ����NMZ.field.* �� .BAK, .BAK.BAK �� �����������Ƥ��ޤ�
#     �Զ��򡢱���@ascii ����Υѥå��ˤ�äƽ���
#   * kwnmz.pl �ǡ�������ɤ� EUC �ǥ����֤��Ƥ����Τ���
# 98.11.20
#   ! and �������Ǥ��ʤ������������ä�
#   * nmztxt.pl ��Ȥ��ݡ�¾�ˤ� db.pl �ʤɤ� require ���ʤ���Фʤ�ʤ��ä�
#     �Τ���ᡢnmztxt.pl ���� require ����Ф褤�褦�ˤ�����
#   * gcnmz.pl �ϡ��ܲȤ� src/ �˾��ʤ��뤳�Ȥˤʤä���
#   * nmztxt.pl ��Ȥä�����ץ�Ȥ��ơ�gcnmz.pl �����ꡢ
#     ����˥�����ɤ��ɲä��륹����ץ� kwnmz.pl ��ź��
#   + subquery �б�
#   + ���ܡ����ޥ�������Υѥå����Ȥˡ�ʸ���¸�ߤ���ǥ��쥯�ȥ�
#     �ؤ��󥯤Ǥ���褦�ˤ���
#   ! ¼�����Ӿ��̿�������Υѥå����Ȥˡ�LANGUAGE ��Ϣ�������
#     v1.3.0.0 Ū�ˤ���
#   + [1][2]... ������� [prev] [next] �Υ�󥯤�Ĥ���
# 98.10.01
#   + field �������б�
#   * �ǡ����١����ե�����򡢥ƥ����ȥե����������Ѵ�����
#     ���֥롼���� nmztxt.pl ���ä�
#   * nmztxt.pl ��Ȥä�����ץ�Ȥ��ơ��ǡ����١����Υ����ݽ��򤹤�
#     ������ץ� gcnmz.pl ��ź�� (v1.3.* �ʹ���)
#   + ����ɽ�����Ѵ������򡢤��ʤ�ޥ��ˤ���
#   - ����ɽ�������� NMZ.(m|s)i? ��Ȥ��Τ��᤿
#   + NMZ.w ��̵���Ƥ⡢����ɽ��/����/��ְ��׸������Ǥ���褦�ˤʤä�
#     (NMZ.i, NMZ.ii ��Ȥ� -> ���������٤�)
#   ! �Ķ��ѿ� NAMAZUCONF & NAMAZUCONFPATH ���ɤ�Ǥ��ʤ��ä��Τ���
#   + POST Method �Ǥ⸡���Ǥ���褦�ˤ���
#   ! ������֤ǥ�⡼�ȥ���������̵���ˤ����Ĥ�꤬���ʤäƤ��ʤ��ä���
#     ($RemoteEnable �Ȥ����ѿ����Ѱդ��Ƥ��������Ѱդ����������ä�)
#   - kakasi ��Ƥ֤Τ��᤿ (�����¢�Τ狼���񤭤�Ȥ�)
# 98.08.31
#   + NMZ.w ��ȤäƤ⡢����/��ְ��׸������Ǥ���褦�ˤʤä�
#   ? dbname=http:// �Ȥ���ȡ�¾�� host �ظ�����̤�ʹ���˹Ԥ��褦�ˤ���
# 98.07.30
#   + ʣ���� dbname ���б�
#   + �����ॹ����פ�Ͽ���� 'NMZ.t' �Ȥ����ե����뤬����С�
#     �����λ��֥����Ȥ��Ǥ���褦�ˤ�����
#   * ���Τ���Υǡ����١�������������ץ� 'tmnmz.pl' ź��
# 98.06.23
#   ! ����ɽ��������Ʊ���� 2 �İʾ夷���Ȥ��Ρ����ͥҥåȿ����ְ�ä�
#     �����Τ�����
#   ! ����ɽ��������������äȤ�����®�ˤʤä�����
#   + .ja �� .en �Ȥ��ä�������� suffix �ΤĤ����ե�������ɤ�褦�ˤ���
#   ! ���ޥ�ɥ饤��Ǥΰ����� v1.2 �ʹߤν�����ɤ��褦�ˤ�����
# 98.06.17
#   * wakati.pl < filename ���Ǥ��ʤ��ä��Τ���
#   + ¼�����Ӿ��̿�������Υѥå����Ȥˡ�LANGUAGE ����� veryshort
#     ���б�
#   ? ����ɽ�����б�������
#       2 �Х���ʸ����ϥ���С��Ȥ���
#       NMZ.w ������С������Ȥ�
#   + �ե졼�������б�
# 98.05.14
#   * ���֥롼�����ή�Ѥ��ơ��狼���񤭥�����ץ� (wakati.pl) ����ӡ�
#     ���Τ���Υǡ����١�������������ץ� (wktndx.pl) ���ä�
#   ! wsearch.pl ����� unsignedcmp ��ȤäƤ������������Ǥ���Ӥϡ�
#     1 �Х���ʸ��Ʊ�Τޤ��� 2 �Х���ʸ��Ʊ�Τ����顢�¤�ñ��� cmp
#     �Ǥ褤�ΤǤϤʤ������Ȼפ���unsignedcmp ��Ȥ�ʤ��褦�ˤ���
#     ���������ʤ���С�����ä�®���ʤ뤫��
# 98.05.06
#   ! ���̤����ǡ����١������ɤ�ʤ��ʤäƤ����Τ���
#   - �������ʸ����ְ��׸������ѻ�
#   + 1 �Х���ʸ����θ���/��ְ��׸������Ǥ���褦�ˤ���
#   * ��ְ��׸����ѥǡ����١�������������ץȤ����� (bwnmz.pl)
# 98.04.27 (proto)
#   + ����/���/�������פ�Ÿ����̤�ɽ������褦�ˤ�����
#   ! �Х�����
#   ? ������ַвᤷ���顢renice �� priority �򲼤�����褦�ˤ��Ƥߤ�
#   * NMZ.m �θ�Ψ�򾯤��夲�� (mbnmz.pl)
#   ! �٤�������
# 98.04.21 (proto)
#   ? 2 �Х���ʸ����θ���/��ְ��׸������Ǥ���褦�ˤ���
#   * ���Τ���Υǡ����١�������������ץ� 'mbnmz.pl' ź��
# 98.04.17
#   ! ������̤� 0 ��Ǥ� 1 ���ɽ������Ƥ����Τ���
# 98.04.16
#   ! �������׸������Ǥ��ʤ��ʤäƤ����Τ���
#   ! ñ��ʬ�򤬤��ޤ������ʤ������������ä��Τ���
#   ? �Ҥ餬�ʸ�ΰ�����ľ��
#   ? �������ʸ�˸¤ꡢ��ְ��׸������Ǥ���褦�ˤ���
#   * ���Τ���Υǡ����١�������������ץ� 'ktnmz.pl' ź��
# 98.04.09
#   + NMZ.(be|le) ���б�������
#   * ����ˤ�ä����̤˻Ȥ�ʬ�ˤ�������ѹ�����ɬ�פ�̵���ʤä�����
#     ��ȼ�������եǥ��쥯�ȥ깽¤�ʤɤ�ľ��
#   ! ����äȥХ�����
#   * �����˥ɥ�����Ƚ���
#   + NMZ.slog ��Ĥ��褦�ˤ���
# 98.03.25
#   + ¼�����Ӿ��̿�������Υѥå����Ȥˡ����ޥ�ɥ饤��
#     ����Ȥ���褦�ˤ���
#   ? namazu.conf �ǻ��ꤵ��Ƥ���� kakasi ��Ƥ٤�褦�ˤ��Ƥߤ�
#   ? ��������ʬ�䤷��
#   * �ޡ����ġ��� (makepnmz.pl) �����
# 98.03.16
#   + ���������Ȥ���褦�ˤʤä�
#   + ���̤����ǡ����١������Ȥ���褦�ˤʤä�
#   ! ����Ū�˥����ɸ�ľ��
# 98.03.06
#   + ����ɽ���� ON/OFF ���ڤ괹������褦�ˤ���
#   + NMZ.lock �򸫤�褦�ˤ�����
#   ! �������׸����ΥХ���ľ����
#   ! ��ʸ����ʸ�������̤���Ƥ����Τ�ľ����
#   ! ʣ�����������ܸ�Τߤ�Ŭ�Ѥ���褦�ˤ���
#   ! �����Υ����פ��ѿ��ˤ���
#   ! ����¾���٤����Х�����
#   + ¼�����Ӿ��̿�������Υѥå����Ȥˡ�ɽ���������
#     ����� dbname �����Ǥ���褦�ˤ�����
# 98.03.04
#   + ����

{
    my($tmp) = $0;

    $tmp = "./$tmp" if -e $tmp && $tmp !~ /[\/\\]/;
    while ($tmp =~ /^.*[\/\\]/){
        unshift(@INC, $&);
        last if !-l $tmp;
        $tmp = $& . $tmp if ($tmp = readlink($tmp)) !~ /^\//;
    }
}

sub config{
    $Pnamazu = '98.12.16';
    require 'pconfig.pl';
    $ScriptName = $ENV{'SCRIPT_FILENAME'} if !$ScriptName;
    $ScriptName = $0 if !$ScriptName && $0 ne '-';
    ($ScriptDir = $ScriptName) =~ s/[\\\/].*?$// if $ScriptName && !$ScriptDir;
}

require 'inttype.pl';
require 'wsearch.pl';
require 'hashop.pl';
require 'listop.pl';
require 'operate.pl';
require 'lang.pl';
require 'euc.pl';
require 'input.pl';
require 'output.pl';
require 'db.pl';
require 'plain.pl';
require 'ldnmzcnf.pl';
require 'cmdline.pl';
require 'bw.pl';
require 'mb.pl';
require 'sb.pl';
require 'reg.pl';
require 'phrase.pl';
require 'wlist.pl';
require 'field.pl';
require 'remote.pl';
require 'regconv.pl';

#--------------------------- 'main' Module ---------------------------
sub cgiparamget{
    # CGI �� QUERY_STRING ���ɤ�
    local($val, $key, $_);

    if ($PathInfo = $ENV{'PATH_INFO'}){
        ($val = $PathInfo) =~ s/^\///;
        push(@DbList, $val);
    }

    $val = $ENV{'QUERY_STRING'};
    $val = join('', <>) if !$val && $ENV{'REQUEST_METHOD'} =~ /post/i;

    @OriginalQuery = split(/&/, $val);
    for (@OriginalQuery){
        ($key, $val) = split(/=/, $_);
        $val =~ s/\+/ /g;
        $val =~ s/%([\dA-Fa-f][\dA-Fa-f])/pack("C",hex($1))/eg;

        $KeyStr = $ARGV = $val if $key =~ /key/i;
        $Sort = $val if $key =~ /sort/i;
        $Max = $val if $key =~ /max/i;
        $Whence = $val if $key =~ /whence/i;
        @DbList = (@DbList, split(/,/, $val)) if $key =~ /dbname/i && $val !~ /^\// && $val !~ /\.\.\//;
        $Format = $val if /format/i;
        $Detail= $val if /detail/i;
        $Subquery = $val if $key =~ /subquery/i;
        $Reference = $val if $key =~ /reference/i;
    }
    $ARGV =~ s/\s\&\&\s/ \& /g;
    $Subquery =~ s/\s\&\&\s/ \& /g;
    $ARGV = "( $Subquery ) && ( $ARGV )" if $Subquery;
}

sub pre_proc{
    $ARGV = &string_normalize($ARGV);
    @ARGV = split(/\s+/, $ARGV);

    &opendb();
    &set_inttype;
}

sub searchmain{
    local(*score);
    my($no, $key);
    # ñ��򤽤줾�측��
    @ARGV = split(/\s+/, ($ARGV = &searchwords(split(/\s+/, $ARGV))));
    # �黻����
    %score = %{&operate(@ARGV)};
    delete $score{'Disable'};
    delete $score{'phrase'};
    delete $score{'field_l'};
    delete $score{'field_r'};

    for (keys(%score)){
        $key = $_;
        $key .= "#$DbList" if $DbList;

        $Score{$key} = $score{$_};
    }
    $Keys = scalar(keys(%score));
}

sub searchsort{
    # ������̤Υ�����

    if ($Sort eq 'score'){
        @Keys = sort {$Score{$b} <=> $Score{$a}} keys(%Score);
    }elsif ($Sort eq 'earlier'){
        @Keys = sort {$Tim{$a} <=> $Tim{$b}} keys(%Score);
    }else{
        @Keys = sort {$Tim{$b} <=> $Tim{$a}} keys(%Score);
    }
    $Keys = scalar(@Keys);
}

sub tag_elem{
    local($_, $key, $val) = @_;

    if ($val ne ''){
        s/($key\s*\=\s*\")(.*?)(\")/$1$val$3/i
            || s/($key\s*\=\s*)(\S*)/$1$val/i
                || s/\s*\>/ $key=\"$val\"\>/;
        return $_;
    }else{
        $val = $2 if /($key\s*\=\s*\")(.*?)(\")/i || /($key\s*\=\s*)(\S*)/i;
#        $val =~ tr/A-Z/a-z/;
        return $val;
    }
}

sub tag_sel{
    local($_, $key, $val) = @_;
    if ($val){
        s/\s*\>/ $key\>/ if !/$key/i;
    }else{
        s/\s*$key//i;
    }
    $_;
}


sub headcat{
    # NMZ.head �ν���
    my($name, $form, $val);
    my($pre, $post);
    my($tag, $value);
    my($ptr, $select);
    my($db);

    local(%paramtbl) = ('max' => \$Max,
                        'sort' => \$Sort,
                        'format' => \$Format,
                        'detail' => \$Detail,
                        'dbname' => \@DbList,
                        'subquery' => \$Subquery,
                        'reference' => \$Reference,
                        );
    
    foreach $_ (@HEAD){
        s/\<title[^\>]*\>/$&pNamazu:$KeyStr \/ /i;
        if (/\<\/HEAD\>/i){
            &output("<META HTTP-EQUIV=\"Last-Modified\" CONTENT=\"$LastModified\">\n") if $LastModified;
            &output("<BASE HREF=\"$BASE_URL\">\n") if $BASE_URL;
        }
        $form = 1 if /\<FORM/i;
        if ($PrintForm || !$form){
            if (/\<\s*(option|select|input|\/select).*?\>/i){
                $pre = $`;
                $post = $';
                $_ = $&;
                
                ($tag = $1) =~ tr/A-Z/a-z/;

                $name = &tag_elem($_, 'name');
                $name =~ tr/A-Z/a-z/;
                $value = &tag_elem($_, 'value');

                $db = 1 if $name eq 'dbname';

                if ($tag eq 'input'){
                    my($type) = &tag_elem($_, 'type');
                    $type =~ tr/A-Z/a-z/;
                    if ($type eq 'text' && $name eq 'key'){
                        if ($RespTextOrig){
                            $_ = &tag_elem($_, 'value', $KeyStr);
                        }else{
                            my $tmp = $ARGV;
                            $tmp =~ s/^.* \&\& //;
                            my @tmp = split(/\s+/, $tmp);
                            if (@tmp = &reducep(@tmp)){
                                $_ = &tag_elem($_, 'value', join(' ', @tmp));
                            }
                        }
#                        $_ = &tag_elem($_, 'value', $ARGV);
                    }elsif ($type eq 'checkbox' && $name eq 'dbname'){
                        $_ = &tag_sel($_, 'checked',
                                      grep($value eq $_, @DbList));
                    }
                }elsif ($tag eq 'select'){
                    $ptr = $paramtbl{$name};
                    $select = (ref($ptr) ne 'SCALAR');
                }elsif ($tag eq '/select'){
                    if (!$select && ($ptr = $$ptr) ne ''){
                        &output("<option value=\"$ptr\" selected>$ptr\n");
                    }
                }elsif ($tag eq 'option'){
                    my($flag);
                    # sort, format, max �� VALUE ����

                    if (ref($ptr) eq 'ARRAY'){
                        $select = 1 if $flag = grep($value eq $_, @$ptr);
                        $_ = &tag_sel($_, 'selected', $flag);
                    }elsif (ref($ptr) eq 'SCALAR'){
                        $select = 1 if $flag = ($$ptr =~ /^$value$/i);
                        $_ = &tag_sel($_, 'selected', $flag);
                    }
                }
                $_ = "$pre$_$post";
            }
            if ($form && /\<\/FORM\>/i && !$db){
                for $db (@DbList){
                    &output("<input type=\"hidden\" name=\"dbname\" value=\"$db\">\n");
                }
            }
            &output($_);
        }
        $form = 0 if /\<\/FORM\>/i;
    }
}

sub putsubmes{
    &message("<H2>$MesResults:</H2>\n");
    if (@DbErrors){
        &message("Errors:\n");
        for (@DbErrors){
            &message("$_<BR>\n");
        }
    }
    &message("<P>\n<STRONG>$MesWordCount:</STRONG>\n<UL>\n");
}

sub putslist{
    my($dblist) = @_;
    my($detail) = ($Detail ne 'off' and %SubHit);
    my $ndx = -1;
    # ���ͥҥåȿ�����
    if (@Words){
        &output("<LI><STRONG>$dblist: $Keys</STRONG>: ") if $dblist;
        &message("<UL>\n") if $detail;
        foreach $_ (@Words){
            next if ++$ndx < $SubQueryWords && $Reference =~ /^off$/i;
            &message("<LI>\n") if $detail;
            if ($SubHit{$_} && $detail){
                &output(" [ $_: $Hit{$_} \(");
                &message("<UL>\n") if $detail;
                local($tmp) = $SubHit{$_};
                local(%tmp) = %$tmp;
                local(@Keys) = sort {$b <=> $a} keys(%tmp);
                $tmp = '';
                foreach $key (@Keys){
                    chop($tmp{$key});
                    $tmp .= "<LI>" if $detail;
                    $tmp .= "$key= $tmp{$key} \n";
                }
                chop($tmp);
                chop($tmp);
                $tmp .= "</UL>\n" if $detail;
                &output("$tmp\)] \n");
            }else{
                &output(" [ $_: $Hit{$_} ] ");
            }
        }
        &message("</UL>\n") if $detail;
        &message("\n");
    }

}

sub puthlist{
    &message("</UL>\n</P>\n<P><STRONG>$MesTotal <!-- HIT -->$Keys<!-- HIT --> $MesDoc</STRONG></P>\n");

    # ������̽���
    if ($Keys){
        my($offset, $next, $summary, $dt, $st, $dd);
        &message("<DL>\n");

        foreach $key (@Keys){
            $keyno = $key, $keydb = '' unless ($keyno, $keydb) = split(/\#/, $key);

            $offset = &indexpointer("FLISTINDEX$keydb", $keyno);
            $next = &lastSize("FLIST_____$keydb", $keyno + 1, "FLISTINDEX$keydb");

            ($dt, $st, $summary, $dd) =
                split(/\n/, &readdb("FLIST_____$keydb", $offset, $next - $offset), 4);
            if($Whence < ++$Ndx){
                if ($Replace && $ReplaceFrom && $ReplaceTo){
                    $st =~ s/$ReplaceFrom/$ReplaceTo/;
                    $dd =~ s/$ReplaceFrom/$ReplaceTo/g;
                }
                &output("$dt$Ndx. $st (score: $Score{$key})\n") if $Format ne 'veryshort';
                &output("$summary\n") if $Format eq 'long';
                if ($DecodeURL){
                    $dd =~ s/(\<A HREF=\")(.*?)(\")/$1.&decode_url($2).$3/ei;
                }elsif ($SplitLink){
                    $dd =~ s/\<A HREF=\"(.*?)\"[^<]+<\/A>/&splitlink($1)/ei;
                }
                $dd =~ s/\n+/\n/g, $dd =~ s/ size \(\d.*$//g if $Format eq 'veryshort';
                &output("$dd");
            }
            last if ($Whence + $Max) <= $Ndx && $Max;
        }
        &message("</DL>\n");
    }
}

sub splitlink{
    local($_) = @_;
    my($pre, $path, $ret);
    my(@elem, @link);

    if (s/^[a-zA-Z]+\:\/\/[^\/]*//){
        $pre = $&;
    }

    @elem = split(/\//, $_);
    $elem[0] .= $pre;

    while (defined($_ = shift(@elem))){
        $_ .= '/' if scalar(@elem);
        $path .= $_;
        $ret .= "<A HREF=\"$path\">$_</A>";
        
    }
    $ret;
}

sub putcurrentextent{
    if ($Keys){
        my($a, $b) = ($Whence + 1, $Whence + $Max);
        $b = $Keys if ($b > $Keys || !$Max);
        &message(sprintf("<STRONG>Current List: %d - %d</STRONG><BR>\n",
                         $a, $b));
    }
}

sub putpagelink{
    my($num, $str) = @_;
    push(@OriginalQuery, "whence=$num") if !(grep {s/^whence.*/whence=$num/} @OriginalQuery) && $num;

    &output(sprintf("<A HREF=\"%s?%s\">[%s]</A>\n",
                    $ENV{'SCRIPT_NAME'} . $PathInfo,
                    join('&', @OriginalQuery),
                    $str));
}

sub putpageindex{
    if ($Max){
        my($PAGE_MAX, $num, $i) = (0, 0, 0);
        &message("<STRONG>Page:</STRONG> ") if $Keys;

        if ($Keys > $Whence){
            if ($Max && ($Whence >= $Max)){
                &putpagelink($Whence - $Max, "prev");
            }
            while ((!$PAGE_MAX || $i < $PAGE_MAX) && $num < $Keys){
                $i++;
                if ($num == $Whence){
                    &output("<STRONG>[$i]</STRONG>\n");
                }else{
                    &putpagelink($num, $i);
                }
                $num += $Max;
            }
            if ($Whence + $Max  < $Keys){
                &putpagelink($Whence + $Max, "next");
            }
        }
    }
}

sub puthtmlheader{
    if ($Cgi && !$PutHead){
        $| = 1;
        print "Last-Modified: $LastModified\n" if $LastModified;
        print "Content-Type: text/html\n\n";
        $PutHead = 1;;
    }
}

sub slog{
    my($rhost);
    local(*SLOG);
    $rhost = ($ENV{'REMOTE_HOST'} || $ENV{'REMOTE_ADDR'});
    if (open(SLOG, ">>$DbPath.slog")){
        my($sec,$min,$hour,$mday,$mon,$year,$wday) = localtime(time);
        printf SLOG ("%s\t%d\t%s\t%s %s %2d %02d:%02d:%02d %4d\n", 
                     $ARGV, $Keys, $rhost,
                     ('Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat')[$wday],
                     ('Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec')[$mon],
                     $mday, $hour, $min, $sec, 1900+$year);
        close(SLOG);
    }
}

sub main{
    $Cgi = ($ENV{'GATEWAY_INTERFACE'} || !$CmdLineEna);
    $Replace = $LOGGING = 1;
    $PageIndex = $PrintForm = $Cgi;
    $PlainConv = $DecodeURL = !$Cgi;

    &config;
    if ($Cgi){
        &load_namazu_conf;
        &cgiparamget;
    }else{
        &command_line_opt;
        &load_namazu_conf;
    }

    if ($LANGUAGE =~ /ja|jp|jis/i){
        $MesResults = '�������', $MesWordCount = '���ͥҥåȿ�',
        $MesTotal = '�������˥ޥå�����', $MesDoc = '�Ĥι��ܤ����Ĥ���ޤ�����';
    }else{
        $MesResults = 'Results', $MesWordCount = 'Word count', 
        $MesTotal = 'Total', $MesDoc = 'documents match your query.';
    }
    &puthtmlheader;

    $IniPri = eval{getpriority(0, 0)};
    $SIG{'ALRM'} = \&alrm, alarm $ReniceTime if $Cgi && $ReniceTime > 0 && $RenicePri > 0;

    $DEFAULT_DIR .= '/' if $DEFAULT_DIR && $DEFAULT_DIR !~ /\/$/;

    if (@DbEnable){
        my(@tmp);
        for $tmp (@DbList){
            push(@tmp, $tmp) if grep {$tmp eq $_} @DbEnable;
        }
        @DbList = @tmp;
    }

    &remote_check(@DbList) if $REMOTE && $RemoteEnable;

    if ($MultiDb = (@DbList > 1 || @RemoteList)){
        $DbPath = $DEFAULT_DIR . $DbName;
    }else{
        if (@DbList){
            $DbPath = $DEFAULT_DIR . $DbList[0] . "/$DbName";
        }else{
            $DbPath = $DEFAULT_DIR . $DbName;
        }
    }

    &openfiles($DbPath);
    if (($OrigARGV = $ARGV) =~ /\S/){
        if ($MultiDb){
            &headcat if !$PlainConv;
            &putsubmes;
            if (@DbList){
                for $dblist (@DbList){
                    $DbList = &db_alias($dblist);
                    next if $DbList =~ /^http\:\/\//;

                    $DbPath = $DEFAULT_DIR . $DbList . "/$DbName";
                    &pre_proc;
                    &searchmain;
                    &putslist($dblist);
                    &slog if $LOGGING;
                    &closedb($DbPath);
                    $ARGV = $OrigARGV;
                }
                &searchsort;
                &puthlist;
            }

            if (@RemoteList){
                &remote_nmz();
                &output("<HR><BR>\n");
            }

            &putcurrentextent;
            &putpageindex if $PageIndex;
        }else{
            &pre_proc;
            &searchmain;
            &headcat if !$PlainConv;
            &putsubmes;
            &putslist;
            &searchsort;
            &puthlist;
            &putcurrentextent;
            &putpageindex if $PageIndex;
            &slog if $LOGGING;
        }
    }elsif (!$PlainConv){
        &headcat;
        if (&opentfile(*FH, "$DbPath.body")){
            &output(<FH>);
            close(FH);
        }
    }
    # NMZ.foot �ν���
    &output(@FOOT) if !$PlainConv && @FOOT;
}

sub alrm{
    eval {setpriority(0, 0, $IniPri + $RenicePri);};
}

sub db_alias{
    local($_) = @_;
    $_ = $DbAlias{$_} if defined($DbAlias{$_});
    $_;
}

&main;
#----------------------- End of 'main' Module ------------------------
