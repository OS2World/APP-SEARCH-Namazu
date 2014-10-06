# 'remote' Module

$REMOTE = 1;

$RemoteOpen = 0;
$RemoteRead = 0;

sub remote_check{
    my(@tmp);
    local($_);
    for $tmp (@_){
        $_ = &db_alias($tmp);
        if (/^http\:\/\// && &remote_open($_)){
            push(@RemoteList, $tmp);
        }else{
            push(@tmp, $tmp);
        }
    }
    @tmp;
}

sub remote_open{
    local($_) = @_;
    my($name, $url);

    if (/^http\:\/\/(.+?)\/(.+)/){
        $url = &db_alias($name = $_);
        my($handle);
        my($host, $path, $port, $c) = ($1, $2, 80, '?');
        $port = $1 if $host =~ s/:(\d+)//;
        $c = '&' if $path =~ /\?/;

        if (!$RemoteOpen){
            $RemoteOpen = 'remoteopen000';
#            use Socket;
        }

        local(*S) = ++$RemoteOpen;
        if ($_ = &tcp_client(*S, $host, $port)){
            &output("<HR><BR>\n<STRONG>$name</STRONG>: $_<BR>\n");
        }else{
            my($str) = "GET /$path$c";
            $str .= join('&', grep(/^(key|sort|max|whence|format|detail)\=/i,
                                   @OriginalQuery));
            $str .= " HTTP/1.0\n\n";
            print S $str;
            vec($remote::Rin, fileno(S), 1) = 1;
            $RemoteS{$name} = *S;
        }
    }
    $url;
}

sub href_conv{
    local($_, $url) = @_;

    return $_ if /^[a-zA-Z]+\:\/\//;
    $url =~ /^(http\:\/\/.+?)\//, return $1 . $_ if /\//;
    $url =~ s/\/.*?$//;
    "$url/$_";
}

sub remote_nmz{
    local(*S, $_);
    my($name);
    my($rin, $rout, $win, $wout, $ein, $eout);
    my($hstr) = '\<\!\-\-\s*HIT\s*\-\-\>';

    $ein = $rin = $remote::Rin;

    my($tmp);
    while (($tmp = select($rout = $rin, $wout = '', $eout = $rin, undef)) > 0){
        for $name (keys(%RemoteS)){
            *S = $RemoteS{$name};
            if (vec($rout, fileno(S), 1)){
                if (defined($_ = <S>)
                    && ($Remote{$name} || /^HTTP\/\d+\.\d+\s+200/)){

                    $Remote{$name} = '' if s/\<\/FORM\>//i;
                    s/(href\=\")(.*?)(\")/$1.&href_conv($2, &db_alias($name)).$3/gei;
                    $Keys = $1 if /$hit\s*(\d+)\s*$hit/ && $1 > $Keys;
                    $Remote{$name} .= $_;
                    next if !/\<\/DL\>/i;
                }
                vec($rin, fileno(S), 1) = 0;
                close(S);
                if ($_ = $Remote{$name}){
                    &output("<HR><BR>\n<STRONG>$name</STRONG><BR>\n");
                    s/(\<\/DL\>).*/$1\n/si || s/\<HR\>.*//si;
                    &output($_);
                }
            }
        }
        if ($rin =~ /^\x00*$/){
            last;
        }
    }
    $tmp;
}

sub tcp_proto_port{
    my($name, $aliases, $proto) = getprotobyname('tcp');
    ($name, $aliases, $_[0]) = getservbyname($_[0], 'tcp') if $_[0] !~ /^\d+$/;
    $proto;
}

sub tcp_addr{
    local($_) = @_;
    local($d, @tmp) = '\d{1,3}';
    chomp;
    return pack('cccc', @tmp) if @tmp = /^($d)\.($d)\.($d)\.($d)$/;
    @tmp = gethostbyname($_);
    $tmp[4];
}

sub tcp_client{
    local(*S, $rmt, $port) = @_;
    my($sockaddr) = 'S n a4 x8';
    my($proto) = &tcp_proto_port($port);
#    my($pf_inet, $sock_stream, $af_inet) = (&PF_INET, &SOCK_STREAM, &AF_INET);
    my($pf_inet, $sock_stream, $af_inet) = (2, 1, 2);
    socket(S, $pf_inet, $sock_stream, $proto) || return "socket: $!";
    bind(S, pack($sockaddr, $af_inet, 0, "\0\0\0\0")) || return "bind: $!";
    connect(S, pack($sockaddr, $af_inet, $port, &tcp_addr($rmt))) || return "connect: $!";
    my($tmp) = select(S); $| = 1; select($tmp);
    undef;
}
1;

# end of 'remote' Module
