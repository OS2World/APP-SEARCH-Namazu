#-------------------- 'single byte' search Module --------------------
sub sb_init{
    $Sb = -1;

    $SbByteL = 0x21;
    $SbByteR = 0x7e;

    $SbWordL = ($SbByteL * 0x100 + $SbByteL);
    $SbWordR = ($SbByteR * 0x100 + $SbByteR);

    $SbOffsetA = 1;
    $SbOffsetN = $SbOffsetA + (ord('z') - ord('a') + 1);
    $SbElem = $SbOffsetN + (ord('9') - ord('0') + 1);

    $SbOffsetA -= ord('a');
    $SbOffsetN -= ord('0');
}
&sb_init;

sub sb_ndx{
    local($_) = @_;
    my($ord) = ord($_);
    return $ord + $SbOffsetA if /^[a-z]/;
    return $ord + $SbOffsetN if /^[0-9]/;
    return 0;
}

sub sbindex{
    return &sb_ndx($_[0]) * $SbElem + &sb_ndx($_[1]);
}

sub sbchars{
    return ($_[0] =~ s/^(.)(.)/$2/)? ($1, $2) : ();
}
#---------------- End of 'single byte' search Module -----------------
