#--------------------- 'backward search' Module ----------------------
$BW = 1;

sub bwopen{
    my($fh, $ext) = @_;

    (&openbfile_opt($fh, "$DbPath.$ext") >= $HashTime &&
     &openbfile_opt($fh . 'INDEX', "$DbPath.$ext" . 'i') >= $HashTime);
}

sub bwclose{
    my($fh, $ext) = @_;
    &closefile('MB');
    &closefile('MBINDEX');
    &closefile('SB');
    &closefile('SBINDEX');
    &mb_init;
    &sb_init;
}

sub w_bw{
    local($origkey, *score, $key, $forward) = @_;
    my($str) = $key;
    my($ptr, $tmp, $bstr, $pre, $buf);
    my($match, $bw);
    my($x, $totalhit, $len, $max);
    local(%kdat, %ldat);

    if ($str =~ s/([\xa1-\xfe])([\xa1-\xfe])/$1 . chr(0x7f & ord($2))/ge){
        $bw = (length($key) > 2);
        $ptr = \@WdbM;
        $x = $WdbX;
    }else{
        $ptr = \@WdbS;
    }
    $str =~ s/[\x00-\x7f]+/quotemeta($&)/ge;
    $str .= "\$" if !$forward;

    for (@$ptr){
        ($buf = $_) =~ s/([\xa1-\xfe])([\xa1-\xfe])/$1 . chr(0x7f & ord($2))/ge;
        if ($buf =~ /$str/){
            $match = 1;
            $bw = 0;
            $kdat{$x} = 1;
        }
        if ($bw){
            $tmp = $key;
            while ($tmp =~ s/..$// && $tmp){
                $len = length($tmp);
                if (/$tmp$/){
                    if ($len > $max){
                        $bstr = $tmp;
                        $max = $len;
                        %ldat = ();
                    }
                    $ldat{$x} = 1;
                }
                last if $len eq $max;
            }
        }
        $x++;
    }

    if ($match){
        $pre = $origkey;
        $key = '';
    }elsif (%ldat){
        %kdat = %ldat;
        $str = "$bstr\$";
        ($key = $origkey) =~ s/^\*$bstr//;
        $pre = $&;
    }elsif ($origkey =~ s/^\*\xa4[\xa1-\xf3](\xa4[\a1-\xf3]|\xa1\xbc)*//){
        return ($&, $origkey, 0);
    }else{
        return ($origkey, '', 0);
    }

    foreach $x (sort {$a <=> $b} keys(%kdat)){
        &ssub(\$totalhit, *score, $pre, $str, $x, $match);
    }
    return ($pre, $key, $totalhit);
}

sub bwsearch{
    local($origkey, *score, $key, $forward, $fh) = @_;
    local(%kdat, %ktmp);
    local(%ldat, %ltmp);
    my($str, $ini) = ($key, 1);
    my($x, $l, $r, $buf, $totalhit);
    my($bstr, $pre, $match, $h, $c1, $c2);
    my($indexsub, $fhi, $charsub);

    my($bw) = ($fh eq 'MB');

    $indexsub = \&mbindex, $charsub = \&mbchars if $fh eq 'MB';
    $indexsub = \&sbindex, $charsub = \&sbchars if $fh eq 'SB';
    $fhi = $fh . 'INDEX';

    $str =~ s/[\x00-\x7f]+/quotemeta($&)/ge;
    $str .= "\$" if !$forward;
    $key =~ s/[^a-zA-Z0-9\x80-\xff]/_/g;

    while (($c1, $c2) = &$charsub($key)){
        $pre .= "$c1$c2";
        $x = &$indexsub($c1, $c2);
        $l = &indexpointer($fhi, $x++);
        $r = &lastNdx($fh, $x);

        %ktmp = %kdat, %kdat = ();
        %ltmp = %ldat, %ldat = () if $bw;
        while ($l < $r){
            $x = &indexpointer($fh, $l++);
            if ($ini || $ktmp{$x}){
                $kdat{$x} = 1;
                if ($bw){
                    $buf = &readindexindex($x);
                    $bw = 0, next if $ini && ($buf =~ /$str/);
                    $bstr = $pre, $ldat{$x} = 1 if $buf =~ /$pre$/;
                }
            }
        }
        $match = !$bw, $ini = 0 if $ini;
        %ldat = %ltmp if $bw && !%ldat;
        last if !%kdat;
    }

    if ($match){
        $pre = $origkey;
        $key = '';
    }elsif (%ldat){
        %kdat = %ldat;
        $str = "$bstr\$";
        ($key = $origkey) =~ s/^\*$bstr//;
        $pre = $&;
    }elsif ($origkey =~ s/^\*\xa4[\xa1-\xf3](\xa4[\a1-\xf3]|\xa1\xbc)*//){
        return ($&, $origkey, 0);
    }else{
        return ($origkey, '', 0);
    }

    foreach $x (sort {$a <=> $b} keys(%kdat)){
        &ssub(\$totalhit, *score, $pre, $str, $x);
    }
    return ($pre, $key, $totalhit);
}
1;
#------------------ End of 'backward search' Module ------------------
