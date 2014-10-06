#---------------------------- 'db' Module ----------------------------
sub opentfile{
    local(*fH, $filename) = @_;
    local($_);
    my($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,$atime,$mtime);

    if (!$LANGUAGE || $LANGUAGE =~ /ja|jp|jis/i){
        $_ = "$filename.ja";
    }elsif (! -r ($_ = "$filename.$LANGUAGE")){
        $_ = $filename . '-e';
    }
    -r $_ || -r ($_ = $filename) || chop($_);

    ($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,$atime,$mtime)
        = stat($_) if open(fH, $_);
    $mtime;
}

sub db::openzfile{
    local(*fH, $filename) = @_;
    if (-r $filename){
        if ($ZcatPri){
            $ZCatPri = 0;
            eval{setpriority(0, 0, $IniPri + $ZcatPri)};
        }
        return open(fH, "$Zcat $filename |");
    }
    return 0;
}

sub openbfile_opt{
    local($str, $filename, $die) = @_;
    local(*fH) = $str;
    my($tmp) = $/;
    my($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,$atime,$mtime);

    if ($Zcat){
        my($fname);
        if (&db::openzfile(*fH, ($fname = "$filename.gz"))
            || &db::openzfile(*fH, ($fname = "$filename"."z"))){

            binmode(fH);
            undef $/;
            $fH = <fH>;
            $/ = $tmp;
            close(fH);
            if (!$?){
                ($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,$atime,$mtime)
                    = stat($fname);
                $DbSize{$str} = $size = length($fH);
                $DbNdx{$str} = $size / $IntSize if $IntSize;
                return $mtime;
            }
            $fH = '';
        }
    }
    if (open(fH, $filename)){
        binmode(fH);
        ($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,$atime,$mtime) = stat(fH);
        $DbSize{$str} = $size;
        $DbNdx{$str} = $size / $IntSize if $IntSize;
        return $mtime;
    }elsif ($die){
        die $filename;
    }
    return 0;
}

sub openbfile{
    &openbfile_opt($_[0], $_[1], 1);
}

sub openfiles{
    my($dbname) = @_;
    @HEAD = <HEAD> if &opentfile(*HEAD, "$dbname.head");
    @FOOT = <FOOT> if &opentfile(*FOOT, "$dbname.foot");
}

sub opendb{
    # DB ファイルを開く
    my($dbname) = @_;
    my(@tmp);
    my($sec,$min,$hour,$mday,$mon,$year,$wday);

    $dbname = $DbPath if !$dbname;

    if (-e "$dbname.lock"){
        &puthtmlheader;
        if (&opentfile(*MSG, "$dbname.msg")){
            print while <MSG>;
        }else{
            print "(now be in system maintenance)\n";
        }
        exit;
    }
    $HashTime = &openbfile('HASH', "$dbname.h");
    ($sec,$min,$hour,$mday,$mon,$year,$wday) = gmtime($HashTime);
    $LastModified
        = sprintf("%s, %02d %s %04d %02d:%02d:%02d GMT",
                  ('Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat')[$wday],
                  $mday,
                  ('Jan', 'Feb', 'Mar', 'Apl', 'May', 'Jun',
                   'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec')[$mon],
                  $year + 1900, $hour, $min, $sec);
    &openbfile('INDEX', "$dbname.i");
    &openbfile('INDEXINDEX', "$dbname.ii");
    &openbfile("FLIST_____$DbList", "$dbname.f");
    &openbfile("FLISTINDEX$DbList", "$dbname.fi");

    &openbfile_opt('PHRASE', "$dbname.p");
    &openbfile_opt('PHRASEINDEX', "$dbname.pi");

    &openbfile_opt('TIM', "$dbname.t");
}

sub closefile{
    local($str) = @_;
    local(*fH) = $str;
    close(fH);
    undef $fH;
    delete $DbNdx{$str};
    delete $DbSize{$str};
}

sub closedb{
    my($dbname) = @_;
    undef $HashTime;
    &closefile('HASH');
    &closefile('INDEX');
    &closefile('INDEXINDEX');

    &closefile('TIM');

    &closefile('PHRASE');
    &closefile('PHRASEINDEX');

    &bwclose;
    &w_init;
    &phrase_init;

    undef %db::cache_rii_buf;

    undef @Words;
    undef %Hit;
    undef %SubHit;
    undef @ScorePtr;
    undef @DbErrors;
}

sub dbsize{
    local(*fH) = @_;
    my($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size);

    return length($fH) if $fH;
    ($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size) = stat(fH);
    $size;
}

sub Burst_on{
    local(*fH, $offset) = @_;
    $db::Burst = 1;
    seek(fH, $offset, 0) if !$fH;
}

sub Burst_off{
    $db::Burst = 0;
}

sub readdb{
    local(*fH, $offset, $size) = @_;
    my($buf, $len);

    if ($fH){
        return ($offset, -1) if $offset >= length($fH);
        $buf = substr($fH, $offset, $size);
    }else{
        seek(fH, $offset, 0) if !$db::Burst;
        return ($offset, -1) if eof(fH);
        read(fH, $buf, $size);
    }
    $offset += $size;
    ($offset, $buf);
}

sub getsdb{
    local(*fH, $offset, $size) = @_;
    my($buf, $len);

    if ($fH){
        while ($offset < length($fH)){
            $c = substr($fH, $offset++, 1);
            last if $c =~ /^$/;
            $buf .= $c;
        }
    }else{
        seek(fH, $offset, 0) if !$db::Burst;

        $buf = <fH>;
        $offset += length($buf);
        chomp($buf);
    }
    ($offset, $buf);
}

#sub eodb{
#    local(*fH, $offset) = @_;
#    $offset >= &dbsize(*fH);
#}

sub indexpointer{
    # file 中の N 番目の整数値を返す
    local(*fH, $n) = @_;
    my($val);

    $n *= $IntSize;
#    return -1 if &eodb(*fH, $n);
    $val = &readdb(*fH, $n, $IntSize);
    unpack($IntType, $val);
}

sub readindexindex{
    # NMZ.ii の N 番目の語を NMZ.i から読んで返す
    my($x) = @_;
    my($offset, $buf);
    return ($offset, $db::cache_rii_buf{$x}) if ($offset = $db::cache_rii_off{$x});
    ($offset, $buf) = &getsdb(*INDEX, &indexpointer(*INDEXINDEX, $x));
    ($db::cache_rii_off{$x} = $offset, $db::cache_rii_buf{$x} = $buf);
}

sub readindexscore{
    # NMZ.i から score を読み取る。ヒット数を返す
    local($n, *score, $str) = @_;
    my($filescore, $fileno, $p, $hit, $net, $ret);
    local(*tmpscore);

#    ($p, $hit) = &readindexindex($n);
    ($p, $str) = &readindexindex($n);

    &Burst_on(*INDEX, $p);
    ($p, $hit) = &readdb(*INDEX, $p, $IntSize);
    $hit = unpack($IntType, $hit) / 2;
    while ($hit-- > 0){
        ($p, $fileno) = &readdb(*INDEX, $p, $IntSize);
        $fileno = unpack($IntType, $fileno);
        ($p, $filescore) = &readdb(*INDEX, $p, $IntSize);
        $filescore = unpack($IntType, $filescore);
        $tmpscore{$fileno} = $filescore;
    }
    &Burst_off;

    for $fileno (sort {$a <=> $b} keys(%tmpscore)){
        if (&TimEnable($fileno)){
            $filescore = $tmpscore{$fileno};
            $score{'phrase'}{$fileno} .= "$str $str\n";
            $net++;
            $ret++ if !$score{$fileno};
            $score{$fileno} = $filescore if $filescore > $score{$fileno};
        }
    }
    # 純粋なヒット数、重複を除いたヒット数を返す
    ($net, $ret);
}

sub lastNdx{
    my($fh, $x) = @_;
    my($fhi) = $fh . 'INDEX';
    ($x < $DbNdx{$fhi})? &indexpointer($fhi, $x): $DbNdx{$fh};
}

sub lastSize{
    my($fh, $x, $db) = @_;
    my($fhi) = $fh . 'INDEX';
    $fhi = $db if $db;
    ($x < $DbNdx{$fhi})? &indexpointer($fhi, $x): $DbSize{$fh};
}

sub TimEnable{
    local($fileno) = @_;
    my $p = $fileno;
    $p .= "#$DbList" if $DbList;
    unless (defined($Tim{$p})){
        if ($fileno < $DbNdx{'TIM'}){
            $Tim{$p} = &indexpointer('TIM', $fileno);
        }else{
            $Tim{$p} = $fileno;
        }
    }
    $Tim{$p} != $IntFF;
}

1;
#------------------------- End of 'db' Module ------------------------
