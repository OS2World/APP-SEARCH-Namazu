#-------------------------- 'output' Module --------------------------
$output::Lang = &lang;

sub output::tosjis{
    my($c1, $c2) = unpack('CC', shift);
    $c2 -= ($c1 & 1)? (0x60 + ($c2 < 0xe0)): 2;
    $c1 = ($c1 + 0x61) >> 1;
    $c1 += 0x40 if $c1 >= 0xa0;
    pack('CC', $c1, $c2);
}

sub output{
    # データの出力に使う。入力は ISO-2022-JP または EUC-JP だと仮定。
    my(@list) = @_;
    my($tmp);
    foreach $_ (@list){
        $_ = &html2plain($_) if $PlainConv;
        if ($output::Lang eq 'ISO-2022-JP'){
            s/[\x80-\xff]+/\e\$B$&\e\(B/g;
            tr/\x80-\xff/\x00-\x7f/;
        }else{
            s/\e\$[\@B](.*?)\e\([BJ]/($tmp = $1,
                                      $tmp =~ tr\/\x21-\x7e\/\xa1-\xfe\/,
                                      $tmp)/ge;
            s/[\x80-\xff]./&output::tosjis($&)/ge if $output::Lang eq 'Shift_JIS';
        }
        print;
    }
}

sub message{
    # スクリプト中の文字列の出力に使う。
    local($_) = @_;
    $_ = &html2plain($_) if $PlainConv;
    if ($output::Lang eq 'ISO-2022-JP'){
        s/[\x80-\xff]+/\e\$B$&\e\(B/g;
        tr/\x80-\xff/\x00-\x7f/;
    }
    print;
}
1;
#---------------------- End of 'output' Module -----------------------
