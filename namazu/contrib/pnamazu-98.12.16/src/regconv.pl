# regconv.pl - 1998.09.09 by furukawa@dkv.yamaha.co.jp

sub regconv{
    # ����ɽ���� EUC �б��� (����ʤ��) �Ѵ�����
    # �㤨��
    #     [��-����] -> (\xff\xA4[\xA2-\xA6]|\xff��)
    #     [^��] -> (\xff[\xA1-\xAF\xB1-\xFE][\xa1-\xfe]|\xff\xB0[\xA2-\xFE]|[\x00-\x7F])
    # �Ȥ��ä���硣
    #
    # ���ѥ�����Υ��å��ΰ��֤��Ѥ��Τǡ�$1, $2, ... �� \1, \2, ...
    # �ʤɤϻȤ��ʤ��ʤ�Ȼפä��ۤ����褤��
    # �ޤ���2 byte ʸ�������� \xff �����������������ǧ�����ʤ��褦��
    # ���Ƥ��롣��äơ������оݤ�ʸ����ϡ�����ä�
    #     s/[\xa1-\xfe]./\xff$&/g;
    # �Ȥ��ä��Ѵ��򤷤Ƥ���ɬ�פ����롣
    #
    # [\x80-\xa0\xff] ���ϰϤ�ʸ�������ä��ꡢ
    # '��' �Ƚ񤫤��� '\xa4\xa2' �Ƚ񤤤Ƥ��ä��ꡢ
    # [\xa1-\xfe] �� 2 byte ñ�̤�¸�ߤ��ʤ��ѥ�����Ǥ�ư�������
    #
    # '$', '/' ��̵���� quote ����롣ɬ�פʤ���Ѵ����˽������Ƥ�������
    #
    # �ȼ��γ�ĥ�Ȥ��ơ�$ex �򿿤ˤ���ȡ�
    #     ���Υ������󥹤��Ȥ���
    #         \H   �Ҥ餬�� (\xa4[\xa1-\xf3])
    #         \K   �������� (\xa5[\xa1-\xf6]|\xa1\xbc)
    #         \J   ����     ([\xb0-\xf4][\xa1-\xfe])
    #     ���Υѥ�����Υ��å����б���������
    #     �ѥ�������� \H, \K, \J, 2 �Х���ʸ�������ä����ɤ����� $ex ���᤹
    # �Ȥ���ư��򤹤�

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

        # '$', '/' �� quote
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

        # ʸ�����饹 ([..]) ����

        # ����
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
            last if $x eq ']' && $flag; # ��λ
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

        # �٥�����ѥ�������Ѵ�

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

sub reggetc{                # 1 ʸ���ɤ߽Ф�
    local(*work, $_) = @_;
    my($ret);

    while (!/^$/){
        if (s/^\\([ULQE])//){   # \U, \L, \Q, \E, \u, \l �ν���
            $1 eq 'E'? chop($work{'mode'}): ($work{'mode'} .= $1);
            $work{'UL'} = (($work{'mode'} =~ /([UL])[^UL]*$/)? $1: '');
            $work{'Q'} = ($work{'mode'} =~ tr/Q/Q/);
            next;
        }
        s/^.//, $ret = $&, last if s/^\\[ul]// && &regcnv::ul($_, $&);
        &regcnv::ul($_, $work{'UL'});

        # 1 ʸ���ɤ߽Ф�
        $work{'mb'} = 1, $ret = $&, last if s/^[\xa1-\xfe][\xa1-\xfe]//;
        $ret = $&, last if s/^\w//;

        s/^.//; $ret = $&;      # ����ν���
        if ($work{'Q'}){        # \Q ��ͭ���ʤ�� quote
            for (1..$work{'Q'}){ $ret = quotemeta($ret); }
            last;
        }
        last if $ret ne "\\";

        # '\' �ν���
        &regcnv::ul($_, $work{'UL'});

        # \c. (����ȥ���ʸ��)�ν���
        $ret .= $&, $ret .= s/^.//? $&: '@', last, if s/^c//;

        # \x00 (16 �ʿ�) �ν���
        $ret .= $&, $ret .= s/^\w{1,2}//? $&: '', last if s/^x//;

        $ret = "\\x00", last if /^[89]/; # \000 (8 �ʿ��ν���)
        $ret = sprintf("\\x%02X", oct($&)), last if s/^[0-7]{1,3}//;

        $work{'mb'} = 1 if /^[HKJ]/;
        $ret .= $&, last if s/^[\x20-\x7e]//; # ����¾
        $ret .= "\\";
        last;
    }
    $_[1] = $_;
    $ret;
}

sub regcnv::ul{                    # ��Ƭ�� 1 ʸ���� ��/��ʸ�� �Ѵ�
    local($_, $ul) = @_;
    return $_[0] =~ s/^[A-Za-z]/\l$&/ if $ul =~ /[lL]/;
    return $_[0] =~ s/^[A-Za-z]/\u$&/ if $ul =~ /[uU]/;
}

sub regcnv::mvect{                   # �ޥ���Х���ʸ���ѤΥ٥�������
    local(*vct, $x, $y) = @_;
    $x -= 0xa0, $y -= 0xa0 if $x;
    vec($vct[$x], $y, 1) = !$vct;
}

sub regcnv::svect{                   # ���󥰥�Х���ʸ���ѤΥ٥�������
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
