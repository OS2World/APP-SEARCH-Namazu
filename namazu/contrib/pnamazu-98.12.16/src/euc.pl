#--------------------------- 'euc' Module ----------------------------
$Shift_JIS = (&lang eq 'Shift_JIS');

sub euc::stoe{
    my($c1, $c2) = @_;
    $c1 = ord($c1);
    $c2 = ord($c2);
    $c1 += ($c1 - 0x60) & 0x7f;
    if ($c2 < 0x9f){
        $c1--;
        $c2 += ($c2 < 0x7f) + 0x60;
    }else{
        $c2 += 2;
    }
    chr($c1) . chr($c2);
}

sub euc::ktoe{
    my($c1, $c2) = @_;
    @euc::ktoe = (0xA3, 0xD6, 0xD7, 0xA2, 0xA6, 0xF2, 0xA1, 0xA3,
                  0xA5, 0xA7, 0xA9, 0xE3, 0xE5, 0xE7, 0xC3, 0xBC,
                  0xA2, 0xA4, 0xA6, 0xA8, 0xAA, 0xAB, 0xAD, 0xAF,
                  0xB1, 0xB3, 0xB5, 0xB7, 0xB9, 0xBB, 0xBD, 0xBF,
                  0xC1, 0xC4, 0xC6, 0xC8, 0xCA, 0xCB, 0xCC, 0xCD,
                  0xCE, 0xCF, 0xD2, 0xD5, 0xD8, 0xDB, 0xDE, 0xDF,
                  0xE0, 0xE1, 0xE2, 0xE4, 0xE6, 0xE8, 0xE9, 0xEA,
                  0xEB, 0xEC, 0xED, 0xEF, 0xF3, 0xAB, 0xAC, ) if !@euc::ktoe;
    $c1 = ord($c1) & 0x7f;
    my($hi) = ($c1 <= 0x25 || $c1 == 0x30 || 0x5e <= $c1)? "\xa1": "\xa5";
    $c1 -= 0x21;
    my($lo) = $euc::ktoe[$c1];
    if ($c2){
        if ($c1 == 5){
            $lo = 0xdd;
        }else{
            $lo++;
            $lo++ if ord($c2) & 0x7f == 0x5f;
        }
    }
    $hi . chr($lo);
}

sub euc::_k2e_{
    local($_) = @_;
    s/(.)([\x5e\x5f]?)/&euc::ktoe($1, $2)/ge;
    $_;
}

sub euc::SJtoEUC{
    $_[0] =~ s/([\x81-\x9f\xe0-\xfa])(.)|([\xa1-\xdf])([\xde\xdf]?)/($3? &euc::ktoe($3, $4): &euc::stoe($1, $2))/ge;
}

sub euc::EUCtoEUC{
    $_[0] =~ s/\x8e(.)(\x8e(.))?/&euc::ktoe($1, $3)/ge;
}

sub euc::base64w{
    local $_ = $_[0];
    my($Len, @Ord); 

    tr/A-Za-z0-9\+\/\=/\x00-\x3f/d;
    $Len = scalar(@Ord = unpack('c*', $_)) - 1;
    substr pack('N',
                (($Ord[0] << 6 | $Ord[1]) << 6 | $Ord[2]) << 6 | $Ord[3]
                ), 1, $Len;
}

sub euc::base64{
    local($_) = @_;
    my($ret);

    $ret .= &euc::base64w($&) while s/^....//;
    $ret;
}

sub euc::quoted{
    local($_) = @_;
    my($ret);
    while (!/^$/){
        $ret .= ' ', next if s/^_//;
        $ret .= chr(hex($1)), next if s/^=([a-zA-Z0-9]{2})//;
        $ret .= $& if s/^.//;
    }
    $ret;
}


sub toEuc{
    local($_) = @_;
    my($tmp, $ret);

    if (s/=\?ISO-2022-JP\?B\?(([a-zA-Z0-9\+\/\=]{4})+?)\?=/&euc::base64($1)/eg |
        s/=\?ISO-2022-JP\?Q\?((=[0-9a-fA-F][0-9a-fA-F]|[_\x21-\x3c\x3e\x40-\x7e])+)\?=/&euc::quoted($1)/eg |
        s/\e([\$\(])(.)([\x21-\x7e]*)/(($1 eq "\$")?
                                       (($tmp = $3)
                                        =~ tr\/\x21-\x7e\/\xa1-\xfe\/,
                                        $tmp):
                                       (($2 eq "I")? &euc::_k2e_($3): $3)
                                       )/ge
        ){
        # ESC とか mime で文字コードを指定しているなんて、ISO-2022 に違いない
        return $_;
    }elsif (/([\x81-\x8d\x8f-\x9f]|\x8e[^\xa1-\xdf])|([\xfd\xfe]|[^\x81-\x9f\xb6-\xc4\xca-\xce\xe0-\xfa][\xde\xdf]|[\xb6-\xc4]\xde)/){
        if ($Shift_JIS = $1){
            # [\x81-\x9f] があるなんて、Shift_JIS に違いない
            &euc::SJtoEUC($_);
        }else{
            # [\xfd\xfe] があるなんて、EUC-JP に違いない
            &euc::EUCtoEUC($_);
        }
        return $_;
    }else{
        # 仕方がない、ちょっとづつ見ていこう
        while(!/^$/){
            if (s/^[\x00-\x80\xa0\xff]+//){
                # 7 bit 文字は、そのまま
                # \x80 とか \xa0 とか \xff とか、知らんものはスキップ
                ($tmp = $&) =~ tr/\x80\xa0\xff//d;
                $ret .= $tmp;
            }elsif (/^([\xaf\xf6\xf7])|^(\xea[\xa3-\xfe]|[\xeb\xef-\xfe][\xa1-\xfe])/){
                if ($Shift_JIS = $1){
                    # EUC-JP では、1 byte 目が [\xaf\xf6\xf7] のものは、
                    #(PC98, MAC の機種依存文字も含めて)
                    # 文字は定義されていないようだ
                    # こりゃ、この後は全部 Shift_JIS と見なそう
                    &euc::SJtoEUC($_);
                }else{
                    # Shift_JIS では、1 byte 目が [\xea\xeb\xef-\xfe] のものは
                    # 文字は定義されていないようだ
                    # こりゃ、この後は全部 EUC-JP と見なそう
                    &euc::EUCtoEUC($_);
                }
                last;


                # コードが特定できないから、今までのコードを引き継いで、
                # とりあえず 1 文字処理しよう
            }elsif ($Shift_JIS){
                s/^([\x81-\x9f\xe0-\xfa])(.)|([\xa1-\xdf])([\xde\xdf]?)//;
                if ($3){
                    $ret .= &euc::ktoe($3, $4);
                }else{
                    $ret .= &euc::stoe($1, $2);
                }
            }elsif (s/^\x8e(.)(\x8e([\xde\xdf]))?//){
                $ret .= &euc::ktoe($1, $3);
            }else{
                s/^..?//;
                $ret .= $&;
            }
        }
        return $ret . $_;
    }
}
1;
#------------------------ End of 'euc' Module ------------------------
