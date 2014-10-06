# regconv.pl - 1998.09.09 by furukawa@dkv.yamaha.co.jp

sub regconv{
    # 正規表現を EUC 対応に (それなりに) 変換する
    # 例えば
    #     [あ-うア] -> (\xff\xA4[\xA2-\xA6]|\xffア)
    #     [^亜] -> (\xff[\xA1-\xAF\xB1-\xFE][\xa1-\xfe]|\xff\xB0[\xA2-\xFE]|[\x00-\x7F])
    # といった具合。
    #
    # 元パターンのカッコの位置が変わるので、$1, $2, ... や \1, \2, ...
    # などは使えなくなると思ったほうがよい。
    # また、2 byte 文字の前に \xff を挿入し、境界を誤認識しないように
    # している。よって、検索対象の文字列は、前もって
    #     s/[\xa1-\xfe]./\xff$&/g;
    # といった変換をしておく必要がある。
    #
    # [\x80-\xa0\xff] の範囲の文字があったり、
    # 'あ' と書かずに '\xa4\xa2' と書いてあったり、
    # [\xa1-\xfe] が 2 byte 単位で存在しないパターンでの動作は不明
    #
    # '$', '/' は無条件に quote される。必要ならば変換前に処理しておくこと
    #
    # 独自の拡張として、$ex を真にすると、
    #     次のシーケンスが使える
    #         \H   ひらがな (\xa4[\xa1-\xf3])
    #         \K   カタカナ (\xa5[\xa1-\xf6]|\xa1\xbc)
    #         \J   漢字     ([\xb0-\xf4][\xa1-\xfe])
    #     元のパターンのカッコの対応を修正する
    #     パターン内に \H, \K, \J, 2 バイト文字があったかどうかを $ex に戻す
    # という動作をする

    # usage: $pattern = &regconv($original_pattern [, $ex]);

    local($_, $ex) = @_;
    local(*work, *vct);
    my($pat, $flag, $mark, $x, $y, $p, $fix, $mb);
    my($eol) = s/\$$//;
    my($knj) = "\\xff[\\xa1-\\xfe][\\xa1-\\xfe]";

    while (!/^$/){
        ++$p if ($x = &reggetc(*work, $_)) eq '(';
        if ($x eq ')'){
            next if !$p;
            --$p;
        }

        # '$', '/' は quote
        $x = "\\$x" if $x =~ /^[\/\$]$/;

        $fix .= $x;

        $mb = 1, $pat .= "(\\xff$x)", next if $x =~ /^[\xa1-\xfe][\xa1-\xfe]$/;
        $pat .= "([^\n\\xa1-\\xff]|$knj)", next if $x eq '.';
        $pat .= "([^\w\\xa1-\\xff]|$knj)", next if $x eq "\\W";
        $pat .= "([^\s\\xa1-\\xff]|$knj)", next if $x eq "\\S";
        $pat .= "([^\d\\xa1-\\xff]|$knj)", next if $x eq "\\D";
        if ($ex){
            $pat .= "(\\xff\\xa4[\\xa1-\\xf3])", next if $x eq '\\H';
            $pat .= "(\\xff\\xa5[\\xa1-\\xf6]|\\xff\xa1\xbc)", next if $x eq '\\K';
            $pat .= "(\\xff[\\xb0-\\xf4][\\xa1-\\xfe])", next if $x eq '\\J';
        }
        $pat .= $x, next if $x ne '[';

        # 文字クラス ([..]) 処理

        # 否定
        $vct = s/^\^//;

        @vct = ();
        $vct[0] = $vct[0xa1 - 0xa0] =  $vct{'all'} = $vct{'set'} = '';

        for (0..127){ vec($vct[0], $_, 1) = $vct; }
        for (0xa1..0xfe){
            vec($vct[0xa1 - 0xa0], $_ - 0xa0, 1) = $vct;
            vec($vct{'all'}, $_ - 0xa0, 1) = !$vct;
            vec($vct{'set'}, $_ - 0xa0, 1) = 1;
        }
        for (0xa2..0xfe){ $vct[$_ - 0xa0] = $vct[0xa1 - 0xa0]; }

        $flag = 0;
        while (!/^$/){
            $fix .= ($x = $y = &reggetc(*work, $_));
            last if $x eq ']' && $flag; # 終了
            $flag = 1;

            if ($x =~ /\\[wWsSdDKHJ]/ || $work{'Q'} || !/^\-[^\]]/){
                if ($x =~ /([\xa1-\xfe])([\xa1-\xfe])/){
                    &regcnv::mvect(*vct, ord($1), ord($2));
                }elsif ($ex && $x =~ /\\H/){
                    for (0xa1..0xf3){
                        &regcnv::mvect(*vct, 0xa4, $_);
                    }
                }elsif ($ex && $x =~ /\\K/){
                    for (0xa1..0xf6){
                        &regcnv::mvect(*vct, 0xa5, $_);
                    }
                    &regcnv::mvect(*vct, 0xa1, 0xbc);
                }elsif ($ex && $x =~ /\\J/){
                    for (0xb0..0xf4){
                        $vct[$_ - 0xa0] = $vct{'all'};
                    }
                }else{
                    &regcnv::svect(*vct, $x);
                    if ($x =~ /^(\.|\\[WSD])$/){
                        for (0xa1..0xfe){
                            $vct[$_ - 0xa0] = $vct{'all'};
                        }
                    }
                }
                next;
            }

            &reggetc(*work, $_); $fix .= '-';
            $fix .= ($y = &reggetc(*work, $_));

            if ($x =~ /^([\xa1-\xfe])([\xa1-\xfe])$/){
                my($x0, $x1) = (ord($1), ord($2));
                if ($y =~ /^([\xa1-\xfe])([\xa1-\xfe])$/){
                    my($y0, $y1) = (ord($1), ord($2));
                    if ($x0 < $y0 && $x1 > 0xa1){
                        &regcnv::mvect(*vct, $x0, $x1++) while $x1 < 0xff;
                        ++$x0, $x1 = 0xa1;
                    }
                    $vct[($x0++) - 0xa0] = $vct{'all'} while $x0 < $y0;
                    if ($x0 == $y0){
                        &regcnv::mvect(*vct, $x0, $x1++) while $x1 <= $y1;
                    }
                }
            }else{
                &regcnv::svect(*vct, "$x-$y");
            }
        }

        # ベクタをパターンへ変換

        $mark = '(';

        $flag = 0;
        $x = 0xa1;
        while (($x, $y) = &regcnv::avrange(*vct, $x), $x >= 0){
            $flag = 1, $pat .= $mark . '\xff[' if !$flag;
            $pat .= &regcnv::rangestr($x, $y);
            $x = $y + 1;
        }
        $pat .= '][\xa1-\xfe]', $mark = '|' if $flag;

        for (0xa1..0xfe){
            if ($vct[$_ - 0xa0] !~ /^\x00*$/){
                $flag = '';
#                $pat .= sprintf("$mark\\xff\\x%02X[", $_);
                $x = 0;
                while (($x, $y) = &regcnv::vrange($vct[$_ - 0xa0], $x), $x >= 0){
                    if (!$flag){
                        $pat .= "$mark\\xff";
                        $pat .= chr($_) . chr($x + 0xa0), last if $x == $y && $vct[$_ - 0xa0] =~ /^\x00*$/;
                        $flag = ']';
                        $pat .= sprintf("\\x%02X[", $_);
                    }
                    $pat .= &regcnv::rangestr($x + 0xa0, $y + 0xa0);
                    $x = $y + 1;
                }
                $pat .= $flag;
                $mark = '|';
            }
        }

        $mark = '' if $mark eq '(';
        if ($vct[0] !~ /^\x00*$/){
            $pat .= $mark . '[';
            $x = 0;
            while (($x, $y) = &regcnv::vrange($vct[0], $x), $x >= 0){
                $pat .= &regcnv::rangestr($x, $y);
                $x = $y + 1;
            }
            $pat .= ']';
        }
        $pat .= ')' if $mark;
    }
    $fix .= ")", $pat .= ")" while $p--;
    $fix .= "\$", $pat .= "\$" if $eol;
    eval {$_[0] = $fix, $_[1] = $mb} if $ex;
    $pat;
}

sub reggetc{                # 1 文字読み出し
    local(*work, $_) = @_;
    my($ret);

    while (!/^$/){
        if (s/^\\([ULQE])//){   # \U, \L, \Q, \E, \u, \l の処理
            $1 eq 'E'? chop($work{'mode'}): ($work{'mode'} .= $1);
            $work{'UL'} = (($work{'mode'} =~ /([UL])[^UL]*$/)? $1: '');
            $work{'Q'} = ($work{'mode'} =~ tr/Q/Q/);
            next;
        }
        s/^.//, $ret = $&, last if s/^\\[ul]// && &regcnv::ul($_, $&);
        &regcnv::ul($_, $work{'UL'});

        # 1 文字読み出し
        $work{'mb'} = 1, $ret = $&, last if s/^[\xa1-\xfe][\xa1-\xfe]//;
        $ret = $&, last if s/^\w//;

        s/^.//; $ret = $&;      # 記号の処理
        if ($work{'Q'}){        # \Q が有効ならば quote
            for (1..$work{'Q'}){ $ret = quotemeta($ret); }
            last;
        }
        last if $ret ne "\\";

        # '\' の処理
        &regcnv::ul($_, $work{'UL'});

        # \c. (コントロール文字)の処理
        $ret .= $&, $ret .= s/^.//? $&: '@', last, if s/^c//;

        # \x00 (16 進数) の処理
        $ret .= $&, $ret .= s/^\w{1,2}//? $&: '', last if s/^x//;

        $ret = "\\x00", last if /^[89]/; # \000 (8 進数の処理)
        $ret = sprintf("\\x%02X", oct($&)), last if s/^[0-7]{1,3}//;

        $work{'mb'} = 1 if /^[HKJ]/;
        $ret .= $&, last if s/^[\x20-\x7e]//; # その他
        $ret .= "\\";
        last;
    }
    $_[1] = $_;
    $ret;
}

sub regcnv::ul{                    # 先頭の 1 文字を 大/小文字 変換
    local($_, $ul) = @_;
    return $_[0] =~ s/^[A-Za-z]/\l$&/ if $ul =~ /[lL]/;
    return $_[0] =~ s/^[A-Za-z]/\u$&/ if $ul =~ /[uU]/;
}

sub regcnv::mvect{                   # マルチバイト文字用のベクタ処理
    local(*vct, $x, $y) = @_;
    $x -= 0xa0, $y -= 0xa0 if $x;
    vec($vct[$x], $y, 1) = !$vct;
}

sub regcnv::svect{                   # シングルバイト文字用のベクタ処理
    local(*vct, $pat) = @_;
    for (0x00..0x7f){
        vec($vct[0], $_, 1) = !$vct if eval{chr($_) =~ /[$pat]/};
    }
}

sub regcnv::avrange{
    local(*vct, $_) = @_;
    my($x, $y, $tmp) = (-1, -1);
    while ($_ < 0xff){
        if ($vct[$_ - 0xa0] eq $vct{'set'}){
            $x = $_;
            $vct[$_ - 0xa0] = '', $y = $_++ while $vct[$_ - 0xa0] eq $vct{'set'};
            last;
        }
        ++$_;
    }
    ($x, $y);
}

sub regcnv::rangestr{
    my($x, $y) = @_;
    ($x == $y)? sprintf('\x%02X', $x): sprintf('\x%02X-\x%02X', $x, $y);
}

sub regcnv::vrange{
    local($vct, $_) = @_;
    my($x, $y) = (-1, -1);
    while ($_ < 128){
        if (vec($vct, $_, 1)){
            $x = $_;
            vec($vct, $y = $_++, 1) = 0 while vec($vct, $_, 1);
            last;
        }
        ++$_;
    }
    @_[0] = $vct;
    ($x, $y);
}
1;
