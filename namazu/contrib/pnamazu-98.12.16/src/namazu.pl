#!/usr/local/bin/perl5

# pnamazu.cgi-98.12.16
# Namazu Search (perl 版) by furukawa@dkv.yamaha.co.jp

# このスクリプトは Namazu Version 1.1.1.1 の srnmz.c を参考に、
# 出力結果が似たような感じになるように、いいかげんに書いたものです。

# 1. おそらくバグがあります。
# 2. 私の身のまわりの、ごく限られたデータしかテストしていません。
# 3. エラー処理の類は、充実していません。

# 履歴 
#       '+': 新規仕様
#       '?': 試験的仕様
#       '-': 仕様の削除
#       '*': 本体以外の仕様
#       '!': 修正
# 98.12.16
#   ! 一度に 2byte 文字列の正規表現検索を 2 つ以上しようとすると、
#     2 つ目以降が見つからないバグを修正
#   * nmztxt.pl が異様にメモリを喰うのを修正
#   * nmztxt.pl が、NMZ.field.* を .BAK, .BAK.BAK … と増殖させてしまう
#     不具合を、塩崎@ascii さんのパッチによって修正
#   * kwnmz.pl で、キーワードを EUC でセーブしていたのを修正
# 98.11.20
#   ! and 検索ができないケースがあった
#   * nmztxt.pl を使う際、他にも db.pl などを require しなければならなかった
#     のを改め、nmztxt.pl だけ require すればよいようにした。
#   * gcnmz.pl は、本家の src/ に昇格することになった。
#   * nmztxt.pl を使ったサンプルとして、gcnmz.pl に代わり、
#     要約にキーワードを追加するスクリプト kwnmz.pl を添付
#   + subquery 対応
#   + 森本＠イマジカさんのパッチをもとに、文書の存在するディレクトリ
#     へもリンクできるようにした
#   ! 村下＠池上通信機さんのパッチをもとに、LANGUAGE 関連の設定を
#     v1.3.0.0 的にした
#   + [1][2]... の前後に [prev] [next] のリンクをつけた
# 98.10.01
#   + field 検索に対応
#   * データベースファイルを、テキストファイルと相互変換する
#     サブルーチン群 nmztxt.pl を作った
#   * nmztxt.pl を使ったサンプルとして、データベースのゴミ掃除をする
#     スクリプト gcnmz.pl を添付 (v1.3.* 以降用)
#   + 正規表現の変換処理を、かなりマシにした
#   - 正規表現検索に NMZ.(m|s)i? を使うのをやめた
#   + NMZ.w が無くても、正規表現/後方/中間一致検索ができるようになった
#     (NMZ.i, NMZ.ii を使う -> ただし、遅い)
#   ! 環境変数 NAMAZUCONF & NAMAZUCONFPATH を読んでいなかったのを修正
#   + POST Method でも検索できるようにした
#   ! 初期状態でリモートアクセスを無効にしたつもりが、なっていなかった。
#     ($RemoteEnable という変数は用意していたが、用意しただけだった)
#   - kakasi を呼ぶのをやめた (常に内蔵のわかち書きを使う)
# 98.08.31
#   + NMZ.w を使っても、後方/中間一致検索ができるようになった
#   ? dbname=http:// とすると、他の host へ検索結果を聞きに行くようにした
# 98.07.30
#   + 複数の dbname に対応
#   + タイムスタンプを記録した 'NMZ.t' というファイルがあれば、
#     本当の時間ソートができるようにした。
#   * そのためのデータベース作成スクリプト 'tmnmz.pl' 添付
# 98.06.23
#   ! 正規表現検索を同時に 2 つ以上したときの、参考ヒット数が間違って
#     いたのを修正。
#   ! 正規表現検索が、ちょっとだけ高速になったかも
#   + .ja や .en といった言語指定 suffix のついたファイルを読むようにした
#   ! コマンドラインでの引数を v1.2 以降の順序で読めるようにした。
# 98.06.17
#   * wakati.pl < filename ができなかったのを修正
#   + 村下＠池上通信機さんのパッチをもとに、LANGUAGE および veryshort
#     に対応
#   ? 正規表現に対応した。
#       2 バイト文字列はコンバートする
#       NMZ.w があれば、それを使う
#   + フレーズ検索対応
# 98.05.14
#   * サブルーチンを流用して、わかち書きスクリプト (wakati.pl) および、
#     そのためのデータベース作成スクリプト (wktndx.pl) を作った
#   ! wsearch.pl の中で unsignedcmp を使っていたが、ここでの比較は、
#     1 バイト文字同士または 2 バイト文字同士だから、実は単純な cmp
#     でよいのではないか、と思い、unsignedcmp を使わないようにした
#     これで問題なければ、ちょっと速くなるかも
# 98.05.06
#   ! 圧縮したデータベースが読めなくなっていたのを修正
#   - カタカナ語の中間一致検索を廃止
#   + 1 バイト文字列の後方/中間一致検索ができるようにした
#   * 中間一致検索用データベース作成スクリプトを統一 (bwnmz.pl)
# 98.04.27 (proto)
#   + 前方/中間/後方一致の展開結果を表示するようにした。
#   ! バグ修正
#   ? 一定時間経過したら、renice で priority を下げられるようにしてみた
#   * NMZ.m の効率を少し上げた (mbnmz.pl)
#   ! 細かい改良
# 98.04.21 (proto)
#   ? 2 バイト文字列の後方/中間一致検索ができるようにした
#   * そのためのデータベース作成スクリプト 'mbnmz.pl' 添付
# 98.04.17
#   ! 検索結果が 0 件でも 1 件と表示されていたのを修正
# 98.04.16
#   ! 前方一致検索ができなくなっていたのを修正
#   ! 単語分解がうまくいかないケースがあったのを修正
#   ? ひらがな語の扱いを見直し
#   ? カタカナ語に限り、中間一致検索ができるようにした
#   * そのためのデータベース作成スクリプト 'ktnmz.pl' 添付
# 98.04.09
#   + NMZ.(be|le) に対応した。
#   * それによって普通に使う分には設定を変更する必要は無くなったこと
#     に伴い、配付ディレクトリ構造などを見直し
#   ! ちょっとバグ修正
#   * 大幅にドキュメント充実
#   + NMZ.slog を残すようにした
# 98.03.25
#   + 村下＠池上通信機さんのパッチをもとに、コマンドライン
#     から使えるようにした
#   ? namazu.conf で指定されていれば kakasi を呼べるようにしてみた
#   ? ソースを分割した
#   * マージツール (makepnmz.pl) を作成
# 98.03.16
#   + 検索式が使えるようになった
#   + 圧縮したデータベースが使えるようになった
#   ! 全体的にコード見直し
# 98.03.06
#   + 要約表示の ON/OFF を切り換えられるようにした
#   + NMZ.lock を見るようにした。
#   ! 前方一致検索のバグを直した
#   ! 大文字小文字が区別されていたのを直した
#   ! 複合語処理は日本語のみに適用するようにした
#   ! 整数のタイプを変数にした
#   ! その他、細かいバグ修正
#   + 村下＠池上通信機さんのパッチをもとに、表示件数指定
#     および dbname 指定をできるようにした。
# 98.03.04
#   + 初版

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
    # CGI の QUERY_STRING を読む
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
    # 単語をそれぞれ検索
    @ARGV = split(/\s+/, ($ARGV = &searchwords(split(/\s+/, $ARGV))));
    # 演算処理
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
    # 検索結果のソート

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
    # NMZ.head の出力
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
                    # sort, format, max の VALUE 設定

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
    # 参考ヒット数出力
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

    # 検索結果出力
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
        $MesResults = '検索結果', $MesWordCount = '参考ヒット数',
        $MesTotal = '検索式にマッチする', $MesDoc = '個の項目が見つかりました。';
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
    # NMZ.foot の出力
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
