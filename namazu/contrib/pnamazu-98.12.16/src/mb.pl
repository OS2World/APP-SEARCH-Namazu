#-------------------- 'multi byte' search Module ---------------------
sub mb_init{
    $Mb = -1;

    $MbByteL = 0xa1;
    $MbByteR = 0xfe;

    $MbWordL = ($MbByteL * 0x100 + $MbByteL);
    $MbWordR = ($MbByteR * 0x100 + $MbByteR);

    $MbElem = $MbByteR + 1 - $MbByteL;
}
&mb_init;

sub mb_ndx{
    local($_) = @_;
    return ord($_) - 0xa1;
}

sub mbindex{
    return &mb_ndx($_[0]) * $MbElem + &mb_ndx($_[1]);
}

sub mbchars{
    return ($_[0] =~ s/^(.)(.)//)? ($1, $2): ();
}
#----------------- End of 'multi byte' search Module -----------------
