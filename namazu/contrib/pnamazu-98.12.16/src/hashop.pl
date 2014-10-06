#---------------------- 'hash operation' Module ----------------------
$hashop::HashName = 'hash0';

sub makehash{
    local($_) = @_;
    ++$hashop::HashName;
    %$hashop::HashName = ();
    return \%$hashop::HashName;
}

sub op_score{
    my($x, $y, $or) = @_;
    return $y unless $x;
    return $x unless $y;
    return $y if $x == -1;
    return $x if $y == -1;
    return $x if ($x <=> $y) == $or;
    $y;
}

sub opAnd{
    local(*X, *Y) = @_;
    local(*Z, $key, $vx, $vy);

    return if $Y{'Disable'};
    %X = %Y, return if $X{'Disable'};

    $Z{'field_l'} = 1 if $X{'field_l'} || $Y{'field_l'};
    $Z{'field_r'} = 1 if $X{'field_r'} || $Y{'field_r'};
    my($f) = ($Z{'field_l'} && $Z{'field_r'});

    while (($key, $vx) = each(%X)){
        next if $key =~ /phrase/;
        next if $key =~ /field_/;
        if ($vy = $Y{$key}){
            $Z{$key} = &op_score($vx, $vy);
            $Z{'phrase'}{$key} = $X{'phrase'}{$key} . $Y{'phrase'}{$key} unless $f;
        }
    }
    %X = %Z;
}

sub opPhrase{
    local(*X, *Y) = @_;
    local(*Z, $key, $vx, $vy);
    my($px, $px1, $px2);
    my($py, $py1, $py2);
    my($s, $f);

    return if $Y{'Disable'};
    %X = %Y, return if $X{'Disable'};

    $Z{'field_l'} = 1 if $X{'field_l'};
    $Z{'field_r'} = 1 if $Y{'field_r'};
    $f = ($Z{'field_l'} && $Z{'field_r'});

    while (($key, $vx) = each(%X)){
        next if $key =~ /phrase/;
        next if $key =~ /field_/;
        if ($vy = $Y{$key}){
            if ($X{'field_r'} || $Y{'field_l'}){
                $Z{'phrase'}{$key} .= $X{'phrase'} if !$X{'field_l'};
                $Z{'phrase'}{$key} .= $Y{'phrase'} if !$Y{'field_r'};
                $Z{$key} = &op_score($vx, $vy);
                next;
            }

            for $px (split("\n", $X{'phrase'}{$key})){
                ($px1, $px2) = split(' ', $px);
                for $py (split("\n", $Y{'phrase'}{$key})){
                    ($py1, $py2) = split(' ', $py);

                    $s = $px2 . $py1;
                    &PhraseList($s) if !$Phrase{$s};

                    if ($Phrase{$s}{$key}){
                        $Z{'phrase'}{$key} .= "$px1 $py2\n" unless $f;
                        $Z{$key} = &op_score($vx, $vy);
                    }
                }
            }
        }
    }
    %X = %Z;
}

sub opNot{
    local(*X, *Y) = @_;
    local(*Z, $key, $vx);

    return if $X{'Disable'};

    $Z{'field_l'} = 1 if $X{'field_l'};
    $Z{'field_r'} = 1 if $X{'field_r'};
    while (($key, $vx) = each(%X)){
        next if $key =~ /phrase/;
        next if $key =~ /field_/;
        if (!$Y{$key}){
            $Z{$key} = $vx;
            $Z{'phrase'}{$key} = $X{'phrase'}{$key};
        }
    }
    %X = %Z;
}

sub opOr{
    local(*X, *Y) = @_;
    local($key, $vx, $vy, $f);

    return if $Y{'Disable'};
    %X = %Y, return if $X{'Disable'};

    $X{'field_l'} = 1 if $X{'field_l'} || $Y{'field_l'};
    $X{'field_r'} = 1 if $X{'field_r'} || $Y{'field_r'};
    delete $X{'phrase'} if $f = ($X{'field_l'} && $X{'field_r'});
    while (($key, $vy) = each(%Y)){
        next if $key =~ /phrase/;
        next if $key =~ /field_/;
        $X{$key} = &op_score($vx, $vy, 1);
        $X{'phrase'}{$key} = $X{'phrase'}{$key} . $Y{'phrase'}{$key} unless $f;
    }
}
1;
#------------------ End of 'hash operation' Module -------------------
