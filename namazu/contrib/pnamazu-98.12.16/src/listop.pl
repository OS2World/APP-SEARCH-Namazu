#---------------------- 'list operation' Module ----------------------
sub prelist{
    local($n, @list) = @_;

    $n = $#list - $n;
    pop(@list) while $n-- >= 0;
    @list;
}

sub sublist{
    local($l, $r, @list) = @_;
    &postlist($l, &prelist($r, @list));
}
        
sub postlist{
    local($n, @list) = @_;

    shift(@list) while $n-- >= 0;
    @list;
}
1;
#------------------ End of 'list operation' Module -------------------
