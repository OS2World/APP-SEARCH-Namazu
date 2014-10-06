#------------------------ 'operation' Module -------------------------
sub searchp{
    # 括弧を探す
    local($p, *list) = @_;
    my($l, $r);
    my($lp, $rp);

    if ($p){
        $lp = '[\{\(]';
        $rp = '[\}\)]';
    }else{
        $lp = '[\(]';
        $rp = '[\)]';
    }

    for ($r = 0; $r <= $#list; $r++){
        if ($list[$r] =~ /^$rp$/){
            for ($l = $r - 1; $l >= 0; $l--){
                if ($list[$l] =~ /^$lp$/){
                    return ($l, $r, $list[$l]);
                }
            }
        }
    }
    return ();
}

sub calc_sub{
    local($p, @list) = @_;
    local(@olist) = ();
    local($a, $b, $c);
    local(*X, *Y);

    while ($a = shift(@list)){
        while (ref($a)){
            if (!defined($b = shift(@list))){
                push(@olist, $a);
                last;
            }elsif (ref($b)){
                %X = %$a;
                %Y = %$b;
                $p? &opPhrase(*X, *Y): &opAnd(*X, *Y);
                %$a = %X;
                next;
            }elsif ($b eq 'or'){
                push(@olist, $a);
                last;
            }elsif ($b =~ /^(and|not)$/){
                if ($p){
                    push(@olist, $a);
                }else{
                    $c = shift(@list);
                    %X = %$a;
                    %Y = %$c;
                    ($b eq 'not')? &opNot(*X, *Y): &opAnd(*X, *Y);
                    %$a = %X;
                    next;
                }
            }
        }
    }
    @olist;
}


sub calcp{
    # 括弧の中身を計算する。
    # ここには、括弧のないリストが渡される
    local($p, @list) = @_;
    local($a, $b);
    local(*X, *Y);

    @list = &calc_sub(($p eq '{' && $DbSize{'PHRASE'}), @list);

    $a = shift(@list);
    %X = %$a;
    while ($b = shift(@list)){
        %Y = %$b;
        &opOr(*X, *Y);
    }
    %$a = %X;
    return $a;
}

sub operate_proc{
    local($mode, $calc, @list) = @_;

    while (($l, $r, $p) = &searchp($mode, *list)){
        @list = (&prelist($l, @list), &$calc($p, &sublist($l, $r, @list)), &postlist($r, @list));
    }
    &$calc('(', @list);
}

sub operate{
    local(@arg) = @_;
    my($l, $r, @list);

    foreach $_ (@arg){
        if (/^(not|\!)$/){
            push(@list, 'not');
        }elsif (/^(or|\|)$/){
            push(@list, 'or');
        }elsif (/^(and|\&|\&\&)$/){
            push(@list, 'and');
        }elsif (/^[\(\)\{\}]$/){
            push(@list, $_);
        }else{
            push(@list, shift(@ScorePtr));
        }
    }
#    push(@list, ')') if $l > $r;
#    unshift(@list, '(') if $l < $r;

    &operate_proc(1, \&calcp, @list);
}
1;
#--------------------- End of 'operation' Module ---------------------
