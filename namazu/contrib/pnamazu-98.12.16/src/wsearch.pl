#----------------------- 'word search' Module ------------------------
sub ssub{
    local($totalhit, *score, $key, $pat, $x, $flag) = @_;
    my($buf);
    my($str) = $buf = &readindexindex($x);
    $buf =~ s/[\xa1-\xfe]./\xff$&/g if $flag;
    if ($buf =~ /$pat/){
        my($net, $hit) = &readindexscore($x, *score, $str);
        $$totalhit += $hit;
        $SubHit{$key}{$net} .= "$str ";
        return 1;
    }
    return 0;
}

sub binsearch{
    # Keyword を検索する。
    local($origkey, *score) = @_;
    my($x, $l, $r, $p, $buf, $hit, $totalhit, $pat);
    my($key) = $origkey;
    my($regsearch, $forward, $backward);

    if ($FIELD && ($fieldsearch = ($key =~ /^\+[^\:\s]+\:/))){
        return &field_search($origkey, *score, $key);
    }
    
    if (!($regsearch = ($key =~ s/^\/(.*)\/$/$1/))){
        $forward = ($key =~ s/(.)\*$/$1/);
        $backward = ($key =~ s/^\*(.)/$1/);
    }
    $pat = $key;

    if ($regsearch){
        return &reg_search($origkey, *score, $key) if $REG;
        $forward = $backward = 1;
        $origkey = "*$key*"
    }

    if ($backward){
        if ($BW){
            if ($key =~ /^([\xa1-\xfe][\xa1-\xfe])+$/){
                $Mb = &bwopen('MB', 'm') if $Mb < 0;
                return &bwsearch($origkey, *score, $key, $forward, 'MB') if $Mb;
            }
            if ($key =~ /^[\x21-\x7e]{2,}$/){
                $Sb = &bwopen('SB', 's') if $Sb < 0;
                return &bwsearch($origkey, *score, $key, $forward, 'SB') if $Sb;
            }
            &w_read("$DbPath.w");
            return &w_bw($origkey, *score, $key, $forward) if $Wdb > 0;
        }
        $origkey =~ s/^\*//;
    }
    $pat =~ s/[\x00-\x7f]+/quotemeta($&)/ge if $forward;

    $x = ord($key) << 8;
    if ($key =~ /^.(.)/){
        $x |= ord($1);
        $r = &indexpointer(*HASH, 1 + $x) - 1;
    }elsif ($forward){
        $r = &indexpointer(*HASH, 0x100 + $x) - 1;
    }else{
        $r = &indexpointer(*HASH, 1 + $x) - 1;
    }
    $p = $l = &indexpointer(*HASH, $x);

    if ($l <= $r){
        while ($l <= $r){
            $x = int(($l + $r + 1) / 2);
            $buf = &readindexindex($x);
            if ($forward){
                if (&ssub(\$totalhit, *score, $origkey, $pat, ($p = $x))){
                    while (&ssub(\$totalhit, *score, $origkey, $pat, --$x)){;}
                    $x = $p;
                    while (&ssub(\$totalhit, *score, $origkey, $pat, ++$x)){;}
                    return ($origkey, '', $totalhit);
                }
            }elsif ($key eq $buf){
                $hit = &readindexscore($x, *score, $key);
                return ($key, '', $hit);
            }

            if ($key lt $buf){
                # &unsignedcmp($key, $buf) < 0
                $r = $x - 1;
            }else{
                $l = $x + 1;
            }
        }

        if ($key =~ /^[\xa1-\xfe]*$/){
            # kakasi を呼ばないので、複合語の検索のため
            # 最長一致で keyword と index を比較し、
            while ($x >= $p){
                $buf = &readindexindex($x);
                if ($key =~ /^$buf/){
                    # keyword の残りは次の語として親ルーチンに返す
                    $origkey =~ s/^$buf//;
                    return ($buf, $origkey, &readindexscore($x, *score, $buf));
                }
                --$x;
            }
        }
    }
    return ($&, $origkey, 0) if $origkey =~ s/^\xa5[\xa1-\xf3](\xa5[\a1-\xf3]|\xa1\xbc)*//;
    return ($&, $origkey, 0) if $origkey =~ s/^\xa4[\xa1-\xf3](\xa4[\a1-\xf3]|\xa1\xbc)*//;
    return ($origkey, '', 0);
}

sub wsearch{
    local($word) = @_;
    local(%score);
    my($hashp, $match, $name, $hit, @word);

    while ($word ne ''){
        %score = ();
        ($match, $word, $hit) = &binsearch($word, *score);

        $score{'Disable'} = ($match =~ /^\xa4[\xa1-\xf3](\xa4[\a1-\xf3]|\xa1\xbc)*$/) if !$hit;

        $Hit{$match} = $hit;
        push(@Words, $match);

        $hashp = &makehash;
        %$hashp = %score;
        push(@ScorePtr, $hashp);
        # ちょっと分かりにくいが、この @ScorePtr というリストは
        # sub operate の中で参照している。
        # それまで順番が変わらないことが前堤になっているので、
        # 改造の際は注意すること

        push(@word, $match);
    }
    return '{ ' . join(' ', @word) . ' }' if $#word > 0;
    join(' ', @word);
}

sub searchwords{
    local(@list) = @_;
    local($_);
    my($op) = '(and|or|not|\&\&|[&|!.])';
    local(*pair);
    my(@tmp, @p, $p, $q);

    foreach $_ (@list){
        $SubQueryWords = scalar(@Words) if /^\&\&$/;
        $_ = &wsearch($_) if !/^(and|or|not|\&\&|[(){}&|!.\"])$/;
    }

    $pair{'('} = ')';
    $pair{'{'} = '}';
    $pair{'"'} = '"';

    for (@list){
        if (/^[\(\{]/ || ($_ eq '"' && !$q)){
            unshift(@p, $_);
            $q = 1, $_ = '{' if $_ eq '"';
            push(@tmp, $_);
        }elsif (/^[\}\)]/ || ($_ eq '"' && $q)){
            while (@p){
                $p = $pair{shift(@p)};
                if ($p eq '"'){
                    $q = 0;
                    push(@tmp, '}');
                }else{
                    push(@tmp, $p);
                }
                last if $_ eq $p;
            }
        }else{
            push(@tmp, $_);
        }
    }
    while (@p){
        $p = $pair{shift(@p)};
        $p = '}' if $p eq '"';
        push(@tmp, $p);
    }

    @tmp = &reducep(@tmp);
    $_ = ' ' . join(' ', @tmp) . ' ';
    while (
           # 演算子の連続は、後ろが有効
           s/ $op $op / $2 /
           # 最後が演算子ならば削除
           || s/ $op $/ /
           # 右カッコの直前が演算子ならば削除
           || s/ $op ([\}\)]) / $1 /
           # 先頭の演算子は削除
           || s/^ $op / /
           # 左カッコの直後が演算子ならば削除
           || s/ ([\(\{]) $op / $1 /
           ){;}
    s/^\s+//;
    s/\s+$//;
    s/\s+/ /g;
    $_;
}

sub reducep{
    local(@tmp) = @_;
    if ($tmp[0] eq '(' and $tmp[$#tmp] eq ')'){
        my($ndx, $cnt) = (0, 0);
        for ($ndx = 1; $ndx < $#tmp; $ndx++){
            if ($tmp[$ndx] eq '('){
                ++$cnt;
            }elsif ($tmp[$ndx] eq ')'){
                last if --$cnt < 0;
            }
        }
        pop(@tmp), shift(@tmp) if !$cnt;
    }
    @tmp;
}

1;
#--------------------- End of 'word search' Module -------------------
