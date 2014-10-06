#------------------------ 'plain text' Module ------------------------
sub html2plain{
    local($_) = @_;
    my($tmp);

    while (s/^(.*?)(\<|\e\$[\@B]|[\x80-\xff])/$2/s){
        $tmp .= $1;
        next if s/\<\!\-\- .*? \-\-\>//s;
        if (s/^\<//){
            s/^.*?\>// if !s/^BR\>/\n/i;
            next;
        }
        $tmp .= $&, next if s/^[\x80-\xff].?// || s/^\e\$[\@B](.*?)\e\([BJ]//;
    }
    $_ = $tmp . $_;
    s/\&gt\;/>/g;
    s/\&lt\;/</g;
    s/\&quot\;/'/g; #'
    s/\&amp\;/&/g;
    $_;
}

sub decode_url{
    local($_) = @_;
    s/\+/ /g;
    s/%(..)/chr(hex($1))/ge;
    $_;
}
1;
#-------------------- End of 'plain text' Module ---------------------
