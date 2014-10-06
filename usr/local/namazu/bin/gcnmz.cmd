EXTPROC perl.exe -Sx
#!/usr/bin/perl
# gcnmz.pl - by furukawa@dkv.yamaha.co.jp
#    small modification by satoru@isoternet.org
#
# namazu v1.3 でできた、無効なエントリのゴミ掃除スクリプト
#  使い方
#       perl5 gcnmz.pl [dbname]
#  dbname としては、データベースの、拡張子の前までを指定する。
#  無指定時のデフォルトは、'NMZ'

# require 'nmztxt.pl';

while (@ARGV && $ARGV[0] =~ s/^\-//){
    $_ = shift;
    while (s/^.//){
        $Quiet = 1 if $& eq 'q';
    }
}

push(@ARGV, 'NMZ') if !@ARGV;

# テンポラリファイルの設定
$TMP_I = "TMP_I.tmp.$$";
$TMP_O = "TMP_O.tmp.$$";

for (@ARGV){
	die "NMZ.lock2 found. Maybe this index is being updated by the other process now.\nIf not, you can remove this file.\n"
	    unless &nmztxt::init($_);

    # 現在無効になっているファイル番号を調べる
    print STDERR "checking NMZ.t\n" if !$Quiet;
    if (&nmztxt::dis_list(\%List, 1)){
        # データベース -> テキストの変換
        print STDERR "reading NMZ.f, NMZ.fi\n" if !$Quiet;
        &nmztxt::flist2txt($TMP_I);

        # テキストの加工 --  該当するファイルを削除
        &nmztxt::delete_elem($TMP_I, $TMP_O, \%List);

        # データベースに書き戻す
        print STDERR "writing NMZ.f, NMZ.fi, NMZ.r\n" if !$Quiet;
        &nmztxt::txt2flist($TMP_O);

        # 以下同様に

        # 単語データベース
        print STDERR "reading NMZ.i\n" if !$Quiet;
        &nmztxt::word2txt($TMP_I);

        &nmztxt::delete_hit($TMP_I, $TMP_O, \%List);

        print STDERR "writing NMZ.i, NMZ.ii, NMZ.h, NMZ.w\n" if !$Quiet;
        &nmztxt::txt2word($TMP_O);


        # フレーズデータベース
        print STDERR "reading NMZ.p, NMZ.pi\n" if !$Quiet;
        &nmztxt::phrase2txt($TMP_I);

        &nmztxt::delete_hit($TMP_I, $TMP_O, \%List);

        print STDERR "writing NMZ.p, NMZ.pi\n" if !$Quiet;
        &nmztxt::txt2phrase($TMP_O);

        # NMZ.head に結果を反映
        print STDERR "editing NMZ.head*\n" if !$Quiet;
        &nmztxt::nmzhead;

        # NMZ.field.* にも反映
        print STDERR "editing NMZ.field.*\n" if !$Quiet;
        &nmztxt::delete_field(\%List);

        if ($_ = scalar(keys %List)){
            &nmztxt::log_aopen(*FH, '[Garbage Collection]');
            print FH "Collected Entry: $_ files\n";
            &nmztxt::log_close(*FH);
        }

    }
    &nmztxt::end;
}

unlink($TMP_I);
unlink($TMP_O);

# おしまい。
#----------------------------------------------------------------
package nmztxt;

sub delete_elem{
    local($fi, $fo, $ptr) = @_;
    local(*FI, *FO);
    my $ndx = 0;
    my $tmp = $/;
    $/ = '';

    if (open(FI, $fi) && open(FO, ">$fo")){
        while (defined($_ = <FI>)){
            print FO $_ unless $ptr->{$ndx};
            ++$ndx;
        }
    }
    $/ = $tmp;
}

# bug fix by satoru@isoternet.org [10/13/1998]
sub delete_hit{
    local($fi, $fo, $ptr) = @_;
    local(*FI, *FO);
    my($ndx, $x, @x);
    my $tmp = $/;
    $/ = '';

    if (open(FI, $fi) && open(FO, ">$fo")){
        while (defined($elem = <FI>)){
            my($word, @hits) = split(/\n/, $elem);
            my $buf = '';
            if (@hits){
                for (@hits){
                    if (/^\d+/){
                        $buf .= "$_\n" unless $ptr->{$&};
                    }
                }
                print FO "$word\n$buf\n" if $buf ne '';
            }
        }
    }
    $/ = $tmp;
}

# ここから下は、nmztxt.pl から cut & paste したものである。
# 詳細は、nmztxt.pl を参照のこと

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
    local(*FO, $wfunc, $_);
    local($hit, $fileno, $filescore);
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
    local(*FO, $x, $n, $buf, $wfunc);

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
    local(*FI);
    local(*FLIST_____);
    local(*FLISTINDEX);
    local(*R);
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
    local($ext, $ptr) = @_;
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
    local($ext, $ptr) = @_;
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
    local(*FH, $tag) = @_;
    if (open(FH, ">>$DbPath.log")){
        print FH "\n$tag\nDate: " . localtime($^T) . "\n";
    }
}

sub log_close{
    local(*FH) = @_;
    printf FH ("Time: %d sec.\n\n", time - $^T);
    close(FH);
}

sub aopenr{
    local(*FI, $name) = @_;
    $FI = $name, return \&areada if ref($name) eq 'ARRAY';
    return \&areadf if open(FI, $name);
    undef;
}

sub areada{
    local(*FI) = @_;
    return shift(@$FI);
}

sub areadf{
    local(*FI) = @_;
    return <FI>;
}

sub wopen{
    local(*FH, $name) = @_;

    push(@wlist, $name);
    my $ret = open(FH, ">$name.$$");
    binmode(FH);
    $ret;
}

sub aopenw{
    local(*FO, $name) = @_;
    $FO = $name, return \&awritea if ref($name) eq 'ARRAY';
    return \&awritef if open(FO, ">$name");
    undef;
}

sub awritef{
    local(*FO, $buf) = @_;
    print FO $buf;
}

sub awritea{
    local(*FO, $buf) = @_;
    push(@$FO, $buf);
}

sub readint{
    local($_);
    return undef unless read($_[0], $_, $IntSize);
    unpack($IntType, $_);
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
    local($str, $filename) = @_;
    local(*fH) = $str;
    if (open(fH, $filename)){
        binmode(fH);
        $DbSize{$str} = (stat(fH))[7];
    }
    $DbSize{$str}
}

sub closefile{
    local($str) = @_;
    local(*fH) = $str;
    close(fH);
    delete $DbSize{$str};
}

