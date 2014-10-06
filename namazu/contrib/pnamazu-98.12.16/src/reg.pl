#-------------------- 'regular expression' Module --------------------
$REG = 1;

sub reg_search{
    local($origkey, *score, $_) = @_;
    local($match, $flag) = ($_, 1);
    my($pat) = &regconv($match, $flag);
    my($fh) = $flag? 'MB': 'SB';
    my($fhi) = $fh . 'INDEX';
    my($db, $totalhit) = ("$DbPath.w", 0);
    local(*FW, $x, $_);
    $match = "/$match/";

    eval("/$pat/i");
    s/[\r\n]//g, s/ at .*//, push(@DbErrors, "$match $_"), return ($match, '', 0) if $_ = $@;

    &w_read($db);
    if ($Wdb > 0){
        $x = $WdbX if $flag;
        for ($flag? @WdbM: @WdbS){
            &ssub(\$totalhit, *score, $match, $pat, $x, $flag) if /$pat/i;
            $x++;
        }
    }
    return ($match, '', $totalhit);
}
1;
#----------------- End of 'regular expression' Module ----------------
