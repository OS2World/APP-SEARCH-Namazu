#!/usr/local/bin/perl5
# wakati.pl - by furukawa@dkv.yamaha.co.jp
{
    my($tmp) = $0;
    while ($tmp =~ /^.*[\/\\]/){
        unshift(@INC, $&);
        last if !-l $tmp;
        $tmp = $& . $tmp if ($tmp = readlink($tmp)) !~ /^\//;
    }
}

require 'pconfig.pl';
require 'db.pl';
require 'lang.pl';
require 'euc.pl';
require 'input.pl';
require 'output.pl';
require 'inttype.pl';

$WKT = 'WKT';
if (@ARGV){
    while ($ARGV[0] =~ s/^\-//){
        $_ = shift;
        while (s/^.//){
            if ($& eq 'w'){
                $_ = shift if $_ eq '';
                $WKT = $_;
                $_ = '';
            }
        }
    }
}

&wakati_init;

while (<>){
    $_ = &toEuc($_);
    s/([\x80-\xff])(.)/&pnkfz1($1, $2)/ge;
    &output(&wakati($_));
}

#---------------------------- subroutines ----------------------------
sub wakati_init{
    local($_, %tmp, $tmp);
    my($dictname) = $WKT;
    my($wkt);

    foreach $_ ('.', @INC){
        $wkt = "$_/$dictname";
        last if &openbfile_opt('DIC', "$wkt.d") && &openbfile_opt('DICINDEX', "$wkt.di");
    }
    ($DbSize{'DIC'} && $DbSize{'DICINDEX'}) || die 'DICINDEX';
    &set_inttype($wkt);

    %tmp = (
            ' ' => '',
            'a' => '\xa4\xa2',
            'b' => '\xa4[\xd0\xd3\xd6\xd9\xdc]',
            'c' => '(\xa4\xc3)?\xa4[\xc1]',
            'd' => '\xa4[\xc0\xc2\xc5\xc7\xc9]',
            'e' => '\xa4\xa8',
            'g' => '\xa4[\xac\xae\xb0\xb2\xb4]',
            'h' => '\xa4[\xcf\xd2\xd5\xd8\xdb]',
            'i' => '\xa4\xa4',
            'j' => '\xa4\xb8',
            'k' => '(\xa4\xc3)?\xa4[\xab\xad\xaf\xb1\xb3]',
            'm' => '\xa4[\xde\xdf\xe0\xe1\xe2]',
            'n' => '\xa4[\xca\xcb\xcc\xcd\xce\xf3]',
            'o' => '\xa4\xaa',
            'p' => '(\xa4\xc3)?\xa4[\xd1\xd4\xd7\xda\xdd]',
            'r' => '\xa4[\xe9\xea\xeb\xec\xed]',
            's' => '\xa4[\xb5\xb7\xb9\xbb\xbd]',
            't' => '(\xa4\xc3)?\xa4[\xbf\xc1\xc4\xc6\xc8]',
            'u' => '\xa4\xa6',
            'w' => '\xa4[\xef\xa4\xa6\xa8\xaa]',
            'y' => '\xa4[\xe4\xe6\xe8]',
            'z' => '\xa4[\xb6\xb8\xba\xbc\xbe]',
            'N' => '\xa4\xf3',
            'T' => '\xa4\xc3',
            );
    while (($_, $tmp) = each(%tmp)){
        tr/ NTa-z/\x80-\x9c/;
        $Okuri{$_} = $tmp;
    }
}

sub wakati{
    local($_) = @_;
    my($ret);
    my($ndx, $offset, $size);
    my(@list, $l, $r, $x);

    while (!/^\s*$/){
        $ret .= $& if s/^\s+//;
        $ret .= $&, next if s/^[^\s\xa1-\xfe]+// || s/^\xa4\xf2//;

        if (/^([\xa1-\xfe])([\xa1-\xfe])/){
            my($match);
            if (!defined($Dic{$&})){
                $ndx = (ord($1) - 0xa1) * (0xfe - 0xa1 + 1) + (ord($2) - 0xa1);
                $offset = &indexpointer(*DICINDEX, $ndx++);
                $size = &lastNdx('DIC', $ndx) - $offset;

                $Dic{$&} = $size? &readdb(DIC, $offset, $size): '';
            }
            if ($Dic{$&}){
                @list = ($Dic{$&} =~ /.*?[\x80-\x9c]/g);
                $l = 0; $r = $#list; $x = int(($r + 1) / 2);
                while ($r >= $l){
                    $x = int(($l + $r + 1) / 2);
                    if ($_ lt $list[$x]){
                        $r = $x - 1;
                    }else{
                        $l = $x + 1;
                    }
                }
                while ($x >= 0){
                    $list[$x] =~ /(.*?)([\x80-\x9c])/;
                    $ret .= $&, last if $match = s/^$1$Okuri{$2}//;
                    $x--;
                }
                next if $match;
            }
        }

        if (s/^(\xa5[\a1-\xf6]|\xa1\xbc)+// ||
            s/^(\xa4[\a1-\xf3])(\xa4[\a1-\xf3]|\xa1\xbc)*// ||
            s/^(\xa1[\xa1-\xfe])+// ||
            s/^(\xa3[\xb1-\xb9\xc1-\xda\xe1-\xfa])+// ||
            s/^(\xa6[\xa1-\xb8\xc1-\xd8])+// ||
            s/^(\xa7[\xa1-\xc1\xd1-\xf1])+// ||
            s/^[\xa1-\xfe][\xa1-\xfe]// ||
            s/^.//
            ){
            $ret .= $&;
        }
    }continue{
        $ret .= ' ' if /^[^\s]/;
    }
    $ret . $_;
}
