#----------------------- 'integer type' Module -----------------------
sub set_inttype{
    local(@db) = @_;
    push(@db, $DbPath);

    if (!$IntType){
        foreach $_ (@db){
            $IntType = 'N', last if -e "$_.be" && ! -e "$_.le";
            $IntType = 'V', last if -e "$_.le" && ! -e "$_.be";
        }
    }
    $IntType = 'I' if !$IntType;
    $IntPackFF = pack($IntType, -1);
    $IntSize = length($IntPackFF);
    $IntFF = unpack($IntType, $IntPackFF);
    foreach $_ (keys(%DbSize)){
        $DbNdx{$_} = $DbSize{$_} / $IntSize;
    }
}
1;
#-------------------- End of 'integer type' Module -------------------
