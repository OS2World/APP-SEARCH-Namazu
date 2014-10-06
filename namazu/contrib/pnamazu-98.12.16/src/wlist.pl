#--------------------- 'database "W" file' Module --------------------
sub w_init{
    $Wdb = 0;
    @WdbM = ();
    @WdbS = ();
    $WdbX = 0;
}
&w_init;

sub w_set{
    local($_) = @_;

    chomp;
    s/\s.*//;
    if (/[\xa1-\xfe]/){
        s/[\xa1-\xfe]./\xff$&/g;
        push(@WdbM, $_);
    }else{
        ++$WdbX;
        push(@WdbS, $_);
    }
}

sub w_read{
    my($db) = @_;
    local(*FW, $_);

    if (!$Wdb){
        if (-r $db && open(FW, $db)){
            &w_set($_) while <FW>;
            close(FW);
        }else{
            my($i, $w);
            while ($i < $DbNdx{'INDEXINDEX'}){
                $w = &readindexindex($i++);
                &w_set($w);
            }
        }
        $Wdb = 1;
    }
}

1;
#------------------ End of 'database "W" file' Module ----------------
