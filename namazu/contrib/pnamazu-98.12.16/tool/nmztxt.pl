# nmztxt.pl -- by furukawa@dkv.yamaha.co.jp
#
# Namazu のデータベース <-> テキスト 変換サブルーチン群
#      データベースをテキストに変換し
#      そのテキストに加工を施して
#      データベースに書き戻す
#  という使用法を想定している。
#
# 書き換えたファイルについては、元のファイルを .BAK として残すようには
# してあるが、危険な作業であることは間違いないので、バックアップをとっ
# ておくこと
#
# pnamazu からの流用部分が多く、pnamazu の設計がよくないことから、ヘン
# なグローバル変数があるが、我慢のこと。
#
#
# 初期化 & 終了処理
#   sub nmztxt::init($dbpath)
#    データベースの拡張子の前までの名前を引数とする。例えば
#       &nmztxt::init('NMZ');
#       &nmztxt::init('dbname/NMZ');
#
#   sub nmztxt::end
#    実際にファイルを書き出す。各ルーチンでは、データベースの書き出しは、
#    テンポラリファイルに対しておこなわれている (NMZ.*.$$)
#    このサブルーチンでは、元のファイル (NMZ.*) を NMZ.*.BAK に rename し
#    新たに、テンポラリファイルをデータベースファイルに rename する。
#
# データベースをテキストに変換する
#   sub nmztxt::flist2txt($x)
#   sub nmztxt::phrase2txt($x)
#   sub nmztxt::word2txt($x)
#
#    いずれも、ref($x) eq 'ARRAY' のときには、@$x にデータをセットし、
#    そうでないときには、$x をファイル名とみなして、そのファイルに書き出す
#
#    ファイルに書き出したときには、要素は空行で区切られているので、
#       $/ = '';
#    とすることにより、<FH> で 1 要素づつ読み出せる。各要素の形式は、
#
#    flist2txt では、
#      [ファイル番号]           (0-origin)
#      [ファイル名]             (NMZ.r より)
#      [要約]                   (NMZ.fi, NMZ.f より)
#
#    word2txt では、
#      [語]                     (NMZ.ii, NMZ.i より)
#      [ファイル番号 スコア]
#       (ヒット数だけ続く)
#
#    phrase2txt では、
#      [ハッシュ値]             (NMZ.pi, NMZ.p より)
#      [ファイル番号]
#       (ヒット数だけ続く)
#
#
# テキストからデータベースを書き出す
#   sub nmztxt::txt2flist($x)
#   sub nmztxt::txt2word($x)
#   sub nmztxt::txt2phrase($x)
#
#    いずれも、ref($x) eq 'ARRAY' のときには、@$x にデータがセットされて
#    いるものとして、shift(@$x) しながら書きだす。
#    そうでないときには、$x をファイル名とみなして、そのファイルから要素
#    を読み出し、データベースに書き出す。
#
#    txt2flist の中で、ファイル番号と実際の対応表を作っているので、
#    リストからファイルを削除した場合には、txt2flist を、txt2(word|phrase)
#    よりも先にしないと、対応がおかしくなる。また、この順番を守れば、
#    ファイルを削除したときに、word や phrase のデータのファイル番号を
#    対応づける処理を、利用者がする必要はない (してはいけない)
#
#    (注意) リスト中のファイルや単語を削除/追加することはできるが、順序を
#           入れ換えられているものを正しく書き出すことはできない。
#           あらかじめ、昇順にソートしておくこと
#
#
#   sub nmztxt::nmzhead
#    NMZ.head* の中の、<!-- FILE --> や <!-- KEY --> の値を修正する。
#    これらの値は、txt2flist, txt2word で数えているので、そちらを先に
#    実行すること
#
#   sub nmztxt::dis_list($ptr, $opt)
#    $ptr として、hash へのポインタを渡すと、
#    NMZ.t から、値が -1 であるファイル番号をキーとして入れる。
#    $opt を真にしておくと、その要素を削除する
#    キーの数 (削除対象のファイル数) を戻り値として返す。
#
#   sub nmztxt::delete_int($ext, $ptr)
#    NMZ.t のように、int がファイルの数だけ並んだデータから、
#    $ptr の指す hash に従ってデータを削除する。
#
#   sub nmztxt::delete_line($ext, $ptr)
#    NMZ.field.* のように、行がファイルの数だけ並んだデータから、
#    $ptr の指す hash に従ってデータを削除する。
#
#   sub nmztxt::delete_field($ptr)
#    delete_line を使って、NMZ.field.* から該当行を削除する
#
#
#   sub nmztxt::log_aopen(*FH, $str)
#    NMZ.log を append open し、$str 及びスクリプト開始時刻を記録する。
#
#   sub nmztxt::log_close(*FH)
#    スクリプト実行時間を記録し、NMZ.log を close する


package nmztxt;

sub init{
    local(*FH);
    $DbPath = $_[0];
    &set_inttype;
    return 0 if -f "$DbPath.lock2";
    open(FH, ">$DbPath.lock2");
    print FH $$;
    close(FH);
    1;
}

sub end{
    local(*FH);
    open(FH, ">$DbPath.lock");
    close(FH);

    while (defined($_ = shift(@wlist))){
        if (-f "$_.$$") {
            rename($_, "$_.BAK");
            rename("$_.$$", $_);
        }
    }
    unlink "$DbPath.lock";
    unlink "$DbPath.lock2";
}

sub flist2txt{
    my($name) = @_;
    local(*FO);
    my($offset, $next, $buf, $wfunc);
    my($tmp) = $/;
    $/ = "\n";

    $FILE = 0;
    &openbfile("FLIST_____", "$DbPath.f") or die;
    &openbfile("FLISTINDEX", "$DbPath.fi") or die;
    open(FI, "$DbPath.r") or die;
    $wfunc = &aopenw(*FO, $name) or die;

    $next = &readint('FLISTINDEX');
    while (<FI>){
        next if /^\#/;
        next if /^\s*$/;

        $_ = sprintf("%d\n", $FILE++) . $_;
        $offset = $next;
        $next = $DbSize{'FLIST_____'} if !defined($next = &readint('FLISTINDEX'));
        read('FLIST_____', $buf, $next - $offset);
        &$wfunc(*FO, $_ .  $buf);
    }
    close(FI);
    close(FO);
    
    &closefile('FLIST_____');
    &closefile('FLISTINDEX');
    $/ = $tmp;
}

sub word2txt{
    my($name) = @_;
    local(*FO, $_);
    my($wfunc, $hit, $fileno, $filescore);
    my($tmp) = $/;
    $/ = "\n";

    &openbfile('INDEX', "$DbPath.i");
    $KEY = 0;
    if ($wfunc = &aopenw(*FO, $name)){
        while (<INDEX>){
            $hit = &readint('INDEX') / 2;
            while ($hit-- > 0){
                $fileno = &readint('INDEX');
                $filescore = &readint('INDEX');
                $_ .= "$fileno $filescore\n";
            }
            last unless defined <INDEX>;
            &$wfunc(*FO, "$_\n");
            ++$KEY;
        }
        close(FO);
    }
    &closefile('INDEX');
    $/ = $tmp;
}

sub phrase2txt{
    my($name) = @_;
    local(*FO);
    my($x, $n, $buf, $wfunc);

    &openbfile('PHRASE', "$DbPath.p");
    &openbfile('PHRASEINDEX', "$DbPath.pi");
    if ($wfunc = &aopenw(*FO, $name)){
        while ($x < 0x10000){
            if (&readint('PHRASEINDEX') ne $IntFF
                && ($n = &readint('PHRASE'))){
                $buf = sprintf("%04X\n", $x);
                $buf .= &readint('PHRASE') ."\n" while $n--;
                &$wfunc(*FO, "$buf\n");
            }
            $x++;
        }
        close(FO);
    }
    &closefile('PHRASE');
}

sub txt2flist{
    my($name) = @_;
    local(*FI, *FLIST_____, *FLISTINDEX, *R);
    my($offset) = 0;
    my($tmp) = $/;
    $/ = '';

    $FILE = 0;

    my $rfunc = &aopenr(*FI, $name) or die;
    &wopen(*FLIST_____, "$DbPath.f");
    &wopen(*FLISTINDEX, "$DbPath.fi");
    &wopen(*R, "$DbPath.r");

    while (defined($_ = &$rfunc(*FI))){
        if ((($no, $r, $f) = split(/\n/, $_, 3)) == 3){
            push(@FILE, $no);
            $FILE{$no} = $FILE;
            $FILE++;
            print FLIST_____ $f;
            print FLISTINDEX pack($IntType, $offset);
            print R "$r\n";
            $offset += length($f);
        }
    }
    $/ = $tmp;
    close(FLIST_____);
    close(FLISTINDEX);
    close(R);
}

sub txt2word{
    my($name) = @_;
    local(*FI);
    my($offset, $ii, $hval, $word, $key, $val);
    my($h) = -1;
    local(*HASH, *INDEX, *INDEXINDEX, *W);
    my($tmp) = $/;
    $/ = '';

    $KEY = 0;

    my $rfunc = &aopenr(*FI, $name) or die;
    &wopen(*HASH, "$DbPath.h");
    &wopen(*INDEX, "$DbPath.i");
    &wopen(*INDEXINDEX, "$DbPath.ii");
    &wopen(*W, "$DbPath.w");

    while (defined($_ = &$rfunc(*FI))){
        ($word, @list) = split(/\n/, $_);
        if (@list){
            $word =~ /^./;
            $hval = ord($word) << 8;
            $hval |= ord($1) if $word =~ /^.(.)/;
            
            $h++, print HASH pack($IntType, $ii) while $h < $hval;
            
            print INDEXINDEX pack($IntType, $offset);
            $ii++;
            print INDEX "$word\n";
            print W "$word\n";
            $offset += length("$word\n");
            print INDEX pack($IntType, 2 * scalar(@list));
            $offset += $IntSize;
            for (@list){
                ($key, $val) = split(/\s+/, $_);
                $key = $FILE{$key} if defined($FILE{$key});
                print INDEX pack($IntType, $key);
                $offset += $IntSize;
                print INDEX pack($IntType, $val);
                $offset += $IntSize;
            }
            print INDEX "\n";
            $offset += length("\n");
            ++$KEY;
        }
    }
    print HASH pack($IntType, $ii) while $h++ < 0x10000;

    close(HASH);
    close(INDEX);
    close(INDEXINDEX);
    close(W);
    close(FI);
    $/ = $tmp;
}

sub txt2phrase{
    my($name) = @_;
    local(*FI);
    my($offset, $x, $hval, @list);
    local(*PHRASE, *PHRASEINDEX);
    my($tmp) = $/;
    $/ = '';

    my $rfunc = &aopenr(FI, $name) or die;
    &wopen(*PHRASE, "$DbPath.p");
    &wopen(*PHRASEINDEX, "$DbPath.pi");

    while (defined($_ = &$rfunc(*FI))){
        ($hval, @list) = split(/\n/, $_);
        if (@list){
            $hval = hex($hval);
            print PHRASEINDEX $IntPackFF while ++$x < $hval;
            print PHRASEINDEX pack($IntType, $offset);
            print PHRASE pack($IntType, scalar(@list));
            $offset += $IntSize;
            for (@list){
                $_ = $FILE{$_} if defined($FILE{$_});
                print PHRASE pack($IntType, $_);
                $offset += $IntSize;
            }
            $x = $hval;
        }
    }
    print PHRASEINDEX $IntPackFF while ++$x < 0x10000;
    close(FI);
    close(PHRASE);
    close(PHRASEINDEX);
    $/ = $tmp;
}

sub nmzhead{
    local(*FI, *FO);
    my ($file, $key) = ("<!-- FILE -->", "<!-- KEY -->");
    my ($qfile, $qkey) = (quotemeta($file), quotemeta($key));
    my (@list) = grep(!/\.BAK$/, glob("$DbPath.head*"));
    for $head (@list){
        if (&wopen(*FO, $head) && open(FI, $head)){
            while (<FI>){
                s/$qfile.*$qfile/$file $FILE $file/ if $FILE;
                s/$qkey.*$qkey/$key $KEY $key/ if $KEY;
                print FO;
            }
            close(FI);
            close(FO);
        }
    }
}

sub delete_field{
    my (@list) = grep(!/\.BAK$/, glob("$DbPath.field.*"));
    my $dbpath = quotemeta("$DbPath.");
    for (@list){
        s/^$dbpath//;
        &delete_line($_, @_);
    }
}

sub dis_list{
    my($ptr, $opt) = @_;
    my($ndx, $ret) = (0, 0);
    my $ref = ref($ptr);
    local(*FO);

    if ($opt){
        &wopen(*FO, "$DbPath.t") || die;
    }
    open(FI, "$DbPath.t") || die;
    binmode(FI);
    while (defined($_ = &readint(*FI))){
        if ($_ == $IntFF){
            $ptr->{$ndx} = 1;
            ++$ret;
        }elsif ($opt){
            print FO pack($IntType, $_);
        }
        ++$ndx;
    }
    close(FO);
    unlink("$DbPath.t.$$") unless ($ret);
    $ret;
}

sub delete_int{
    my($ext, $ptr) = @_;
    local(*FI, *FO, $_);
    my $db = "$DbPath.$ext";
    my $ndx = 0;

    if (&wopen(*FO, $db) && open(FI, $db)){
        binmode(FI);
        while (read(FI, $_, $IntSize)){
            print FO $_ unless $ptr->{$ndx++};
        }
        close(FO);
    }
}

sub delete_line{
    my($ext, $ptr) = @_;
    local(*FI, *FO, $_);
    my $db = "$DbPath.$ext";
    my $ndx = 0;

    if (&wopen(*FO, $db) && open(FI, $db)){
        while (<FI>){
            print FO $_ unless $ptr->{$ndx++};
        }
        close(FO);
    }
}

sub log_aopen{
    my($fh, $tag) = @_;
    if (open($fh, ">>$DbPath.log")){
        print $fh ("\n$tag\nDate: " . localtime($^T) . "\n");
    }
}

sub log_close{
    my($fh) = @_;
    printf $fh ("Time: %d sec.\n", time - $^T);
    close($fh);
}

sub aopenr{
    my($fi, $name) = @_;
    $$fi = $name, return \&areada if ref($name) eq 'ARRAY';
    return \&areadf if open($fi, $name);
    undef;
}

sub areada{
    my($fi) = @_;
    shift(@$$fi);
}

sub areadf{
    my($fi) = @_;
    <$fi>;
}

sub wopen{
    my($fh, $name) = @_;
    push(@wlist, $name);
    my $ret = open($fh, ">$name.$$");
    binmode($fh);
    $ret;
}

sub aopenw{
    my($fo, $name) = @_;
    $$fo = $name, return \&awritea if ref($name) eq 'ARRAY';
    return \&awritef if open($fo, ">$name");
    undef;
}

sub awritef{
    my($fo, $buf) = @_;
    print $fo ($buf);
}

sub awritea{
    my($fo, $buf) = @_;
    push(@$$fo, $buf);
}

sub readint{
    my $buf;
    return undef unless read($_[0], $buf, $IntSize);
    unpack($IntType, $buf);
}

sub set_inttype{
    $IntType = 'I';
    $IntType = 'N' if -e "$DbPath.be" && ! -e "$DbPath.le";
    $IntType = 'V' if -e "$DbPath.le" && ! -e "$DbPath.be";
    $IntPackFF = pack($IntType, -1);
    $IntSize = length($IntPackFF);
    $IntFF = unpack($IntType, $IntPackFF);
}

sub openbfile{
    my($str, $filename) = @_;
    local(*FH) = $str;
    if (open(FH, $filename)){
        binmode(FH);
        $DbSize{$str} = (stat(FH))[7];
    }
    $DbSize{$str}
}

sub closefile{
    my($str) = @_;
    close($str);
    delete $DbSize{$str};
}

1;
