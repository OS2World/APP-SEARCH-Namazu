#--------------------------- 'lang' Module ---------------------------
sub lang{
    for ('LC_TYPE', 'LANG'){
        return 'Shift_JIS' if $ENV{$_} =~ /sj|shift/i;
        return 'EUC-JP' if $ENV{$_} =~ /euc/i;
    }
    return 'ISO-2022-JP';
}
$LANGUAGE = &lang;
1;
#----------------------- End Of 'lang' Module ------------------------



