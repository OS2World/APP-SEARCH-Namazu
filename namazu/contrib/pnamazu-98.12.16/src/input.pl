#-------------------------- 'input' Module ---------------------------
sub pnkfz1{
    # 'nkf -Z1' のような処理
    local($f, $_) = @_;
    if ($f eq "\xa1"){
        return $_ if tr/\xa1\xa4\xa5\xa7\xa8\xa9\xaa\xae\xb0\xb2\xbf\xc3\xc7\xc9\xca\xcb\xd0\xd1\xdc\xdd\xe1\xe3\xe4\xf0\xf3\xf4\xf5\xf6\xf7/ ,.:;?!`^_\/|'"(){}+\-=<>$%#&*@/; #`
    }elsif ($f eq "\xa3"){
        return $_ if tr/\xc1-\xda\xe1-\xfa\xb0-\xb9/A-Za-z0-9/;
    }
    $f . $_;
}

sub input::pWakachi{
    local($_) = @_;
    my($ret);

    # 1byte - 2byte を分ける
    s/([\x21-\x7f])([\x80-\xff])/$1 $2/g;
    # 2byte - 1byte を分ける
    s/([\x80-\xff])([\x21-\x7f])/$1 $2/g;

    return $_;

    while (!/^$/){
        $ret .= $&, next if s/^[^\xa1-\xfe]+//;
        if (/^\xa4[\xa1-\xf3]/){
            # ひらがなで始まる部分
            s/^(\xa4[\a1-\xf3]|\xa1\xbc)+//;
            $ret .= $&;
            $ret .= $& if s/^\*//;
            $ret .= ' ' if /^\S/;
            next;
        }
        if (/^\xa5[\xa1-\xf6]/){
            # カタカナで始まる部分
            s/^(\xa5[\a1-\xf6]|\xa1\xbc)+//;
            $ret .= $&;
            $ret .= $& if s/^\*//;
            $ret .= ' ' if /^\S/;
            next;
        }
        if (s/^([\xa1-\xfe][\xa1-\xfe])+?(\xa5[\xa1-\xf6])//){
            # 漢字 - カタカナと続く部分
            my($tmp) = $&;
            $_ = $2 . $_;
            $tmp =~ s/..$/ /;
            $ret .= $tmp;
            next;
        }
        s/^[\xa1-\xfe]+//;
        $ret .= $&;
    }
    $ret .= $_;
}

sub string_normalize{
    local($_) = @_;
    my($f, $b, $pat);

    $_ = &toEuc($_);
    s/([\x80-\xff])(.)/&pnkfz1($1, $2)/ge;

    s/^\s+//;
    while (!/^$/){
        if (s/^(\+[^\s\:]+\:)?\///){
            my($tmp) = $&;
            $tmp =~ tr/A-Z/a-z/;
            $pat .= $tmp;

            $tmp = '';
            while (!(/^\s*$/ || s/^\/\s+// || s/^\/$//)){
                $tmp .= $&, next if s/^[^\\\/]+//;
                $tmp .= $&, next if s/^\///;
                $tmp .= $&, next if s/^\\.//;
                $tmp .= $&, next if s/^\\$//;
            }
            $tmp =~ s/\s/\\s/g;
            $pat .= "$tmp/ ";
            next;
        }

        $pat .= "$1 ", next if s/^([\"\{])\s*//;
        $pat .= "$1 ", next if s/^(\+[^\s\:]+\:\S+)\s*//;

        if (s/^(\S+)\s*//){
            my($tmp) = $1;
            my($p) = ($tmp =~ s/[\"\}]$//)? " $&": '';
            my($f) = ($tmp =~ s/\*$//)? $&: '';
            my($b) = ($tmp =~ s/^\*//)? $&: '';
            ($tmp = &input::pWakachi($tmp)) =~ tr/A-Z/a-z/;
            $pat .= $b . &input::pWakachi($tmp) . $f . $p . " ";
        }
    }
    $_ = $pat;
    s/\s+/ /g;
    s/^\s+//;
    s/\s+$//;
    $_;
}
1;
#----------------------- End of 'input' Module -----------------------
