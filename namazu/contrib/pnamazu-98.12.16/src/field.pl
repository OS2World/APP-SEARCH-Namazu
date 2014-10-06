$FIELD = 1;
sub field_init{
    %FieldAlias = ('author' => 'from',
                   'title' => 'subject',
                   );
}
&field_init;

sub field_search{
    local($origkey, *score, $_) = @_;
    local($key) = $_;
    my($flag);
    my($db) = "$DbPath.field";
    my($match);
    local(@list);

    $key =~ s/^\+([^\:\s]+)\://;
    my($field) = $1;

    if ($key =~ s/^\/(.*)\/$/$1/){
        $flag = 1;
        $pat = &regconv($key, 1);
        $match = "+$field:/$key/";
        $key = "/$key/";
        eval("/$pat/i");
        s/[\r\n]//g, s/ at .*//, push(@DbErrors, "$match $_"), return ($match, '', 0) if $_ = $@;
    }else{
        ($pat = $key) =~ s/[\x00-\x7f]+/quotemeta($&)/ge;
        $match = "+$field:$key";
    }

    my($alias) = $field;
    while (!$FieldList{$alias}){
        last unless $FieldAlias{$alias};
        $alias = $FieldAlias{$alias};
    }

    if ($FieldList{$alias}){
        my($p) = $FieldList{$alias};
        @list = @$p;
    }else{
        $alias = $field;
        while (! open(FH, "$db.$alias")){
            push(@DbErrors, "$match: unknown field"), return ($match, '', 0) if !$FieldAlias{$alias};
            $alias = $FieldAlias{$alias};
        }
        @list = <FH>;

        if ($alias =~ /url/i && $Replace && $ReplaceFrom && $ReplaceTo){
            @list = grep {s/$ReplaceFrom/$ReplaceTo/g} @list;
        }
        $FieldList{$alias} = \@list;
    }
    my($ndx, $totalhit) = (0, 0);
    for (@list){
        s/[\xa1-\xfe]./\xff$&/g if $flag;
        $totalhit++, $score{$ndx} = -1 if /$pat/i && &TimEnable($ndx);
        $ndx++;
    }
    $score{'field_r'} = $score{'field_l'} = 1;
    return ($match, '', $totalhit);
}
1;
