# nmztxt.pl -- by furukawa@dkv.yamaha.co.jp
#
# Namazu �Υǡ����١��� <-> �ƥ����� �Ѵ����֥롼����
#      �ǡ����١�����ƥ����Ȥ��Ѵ���
#      ���Υƥ����Ȥ˲ù���ܤ���
#      �ǡ����١����˽��᤹
#  �Ȥ�������ˡ�����ꤷ�Ƥ��롣
#
# �񤭴������ե�����ˤĤ��Ƥϡ����Υե������ .BAK �Ȥ��ƻĤ��褦�ˤ�
# ���Ƥ��뤬�����ʺ�ȤǤ��뤳�Ȥϴְ㤤�ʤ��Τǡ��Хå����åפ�Ȥ�
# �Ƥ�������
#
# pnamazu �����ή����ʬ��¿����pnamazu ���߷פ��褯�ʤ����Ȥ��顢�إ�
# �ʥ����Х��ѿ������뤬�������Τ��ȡ�
#
#
# ����� & ��λ����
#   sub nmztxt::init($dbpath)
#    �ǡ����١����γ�ĥ�Ҥ����ޤǤ�̾��������Ȥ��롣�㤨��
#       &nmztxt::init('NMZ');
#       &nmztxt::init('dbname/NMZ');
#
#   sub nmztxt::end
#    �ºݤ˥ե������񤭽Ф����ƥ롼����Ǥϡ��ǡ����١����ν񤭽Ф��ϡ�
#    �ƥ�ݥ��ե�������Ф��Ƥ����ʤ��Ƥ��� (NMZ.*.$$)
#    ���Υ��֥롼����Ǥϡ����Υե����� (NMZ.*) �� NMZ.*.BAK �� rename ��
#    �����ˡ��ƥ�ݥ��ե������ǡ����١����ե������ rename ���롣
#
# �ǡ����١�����ƥ����Ȥ��Ѵ�����
#   sub nmztxt::flist2txt($x)
#   sub nmztxt::phrase2txt($x)
#   sub nmztxt::word2txt($x)
#
#    ������⡢ref($x) eq 'ARRAY' �ΤȤ��ˤϡ�@$x �˥ǡ����򥻥åȤ���
#    �����Ǥʤ��Ȥ��ˤϡ�$x ��ե�����̾�Ȥߤʤ��ơ����Υե�����˽񤭽Ф�
#
#    �ե�����˽񤭽Ф����Ȥ��ˤϡ����Ǥ϶��ԤǶ��ڤ��Ƥ���Τǡ�
#       $/ = '';
#    �Ȥ��뤳�Ȥˤ�ꡢ<FH> �� 1 ���ǤŤ��ɤ߽Ф��롣�����Ǥη����ϡ�
#
#    flist2txt �Ǥϡ�
#      [�ե������ֹ�]           (0-origin)
#      [�ե�����̾]             (NMZ.r ���)
#      [����]                   (NMZ.fi, NMZ.f ���)
#
#    word2txt �Ǥϡ�
#      [��]                     (NMZ.ii, NMZ.i ���)
#      [�ե������ֹ� ������]
#       (�ҥåȿ�����³��)
#
#    phrase2txt �Ǥϡ�
#      [�ϥå�����]             (NMZ.pi, NMZ.p ���)
#      [�ե������ֹ�]
#       (�ҥåȿ�����³��)
#
#
# �ƥ����Ȥ���ǡ����١�����񤭽Ф�
#   sub nmztxt::txt2flist($x)
#   sub nmztxt::txt2word($x)
#   sub nmztxt::txt2phrase($x)
#
#    ������⡢ref($x) eq 'ARRAY' �ΤȤ��ˤϡ�@$x �˥ǡ��������åȤ����
#    �����ΤȤ��ơ�shift(@$x) ���ʤ���񤭤�����
#    �����Ǥʤ��Ȥ��ˤϡ�$x ��ե�����̾�Ȥߤʤ��ơ����Υե����뤫������
#    ���ɤ߽Ф����ǡ����١����˽񤭽Ф���
#
#    txt2flist ����ǡ��ե������ֹ�ȼºݤ��б�ɽ���äƤ���Τǡ�
#    �ꥹ�Ȥ���ե���������������ˤϡ�txt2flist ��txt2(word|phrase)
#    ������ˤ��ʤ��ȡ��б������������ʤ롣�ޤ������ν��֤���С�
#    �ե�������������Ȥ��ˡ�word �� phrase �Υǡ����Υե������ֹ��
#    �б��Ť�����������ѼԤ�����ɬ�פϤʤ� (���ƤϤ����ʤ�)
#
#    (���) �ꥹ����Υե������ñ�����/�ɲä��뤳�ȤϤǤ��뤬�������
#           ���촹�����Ƥ����Τ��������񤭽Ф����ȤϤǤ��ʤ���
#           ���餫���ᡢ����˥����Ȥ��Ƥ�������
#
#
#   sub nmztxt::nmzhead
#    NMZ.head* ����Ρ�<!-- FILE --> �� <!-- KEY --> ���ͤ������롣
#    �������ͤϡ�txt2flist, txt2word �ǿ����Ƥ���Τǡ�����������
#    �¹Ԥ��뤳��
#
#   sub nmztxt::dis_list($ptr, $opt)
#    $ptr �Ȥ��ơ�hash �ؤΥݥ��󥿤��Ϥ��ȡ�
#    NMZ.t ���顢�ͤ� -1 �Ǥ���ե������ֹ�򥭡��Ȥ�������롣
#    $opt �򿿤ˤ��Ƥ����ȡ��������Ǥ�������
#    �����ο� (����оݤΥե������) ������ͤȤ����֤���
#
#   sub nmztxt::delete_int($ext, $ptr)
#    NMZ.t �Τ褦�ˡ�int ���ե�����ο������¤���ǡ������顢
#    $ptr �λؤ� hash �˽��äƥǡ����������롣
#
#   sub nmztxt::delete_line($ext, $ptr)
#    NMZ.field.* �Τ褦�ˡ��Ԥ��ե�����ο������¤���ǡ������顢
#    $ptr �λؤ� hash �˽��äƥǡ����������롣
#
#   sub nmztxt::delete_field($ptr)
#    delete_line ��Ȥäơ�NMZ.field.* ���鳺���Ԥ�������
#
#
#   sub nmztxt::log_aopen(*FH, $str)
#    NMZ.log �� append open ����$str �ڤӥ�����ץȳ��ϻ����Ͽ���롣
#
#   sub nmztxt::log_close(*FH)
#    ������ץȼ¹Ի��֤�Ͽ����NMZ.log �� close ����


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
