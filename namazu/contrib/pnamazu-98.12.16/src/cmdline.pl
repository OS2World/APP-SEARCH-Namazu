#----------------------- 'command line' Module -----------------------
$CmdLineEna = 1;
sub usage(){
    my($usage);
#    die << "ENDOFUSAGE";
    $usage = << "TOPOFUSAGE";
  Search Program of Namazu Perl Command-line Version 0.3 by tmu\@ikegami.co.jp
  Original Search Program of Namazu Version 1.1.2.3 - 1.3.0.0
  Copyright (C) 1997-1998 Satoru Takabayashi All rights reserved.
  Original pnamazu.cgi-$Pnamazu
  Namazu Search (perl 版) by furukawa\@dkv.yamaha.co.jp

TOPOFUSAGE

    $usage .= '  usage: namazu.pl [-nwsvhcaoCHFRUL] ';

    if ($CmdLineArg eq 'old'){
        $usage .= '[index dir(s)] "key string"';
    }else{
        $usage .= '"key string" [index dir(s)]';
    }

    $usage .= << "ENDOFUSAGE";

     -n (num)  : 一度に表示する件数
     -w (num)  : 表示するリストの先頭番号
     -s        : 短いフォーマットで出力
     -S        : もっと短いフォーマット (リスト表示) で出力
     -v        : usage を表示する (この表示)
     -f (path) : namazu.conf を指定する
     -h        : HTML で出力する
     -l        : 新しい順に疑似的にソートする
     -e        : 古い順に疑似的にソートする
     -a        : 検索結果をすべて表示する
     -o (path) : 指定したファイルに検索結果を出力する
     -C        : コンフィギュレーション内容を表示する
     -H        : 先の検索結果へのリンクを表示する (ほぼ無意味)
     -F        : <FORM> ... </FORM> の部分を強制的に表示する
     -R        : URL の置き換えを行わない
     -U        : plain text で出力する時に URL encode の復元を行わない
     -L (lang) : メッセージの言語を設定する ja または en
ENDOFUSAGE

    &output($usage);
    exit;
}

sub show_configuration(){
    print << "ENDOFPRINTCONF";
namazu configurations

configuration file: $NamazuConf
  * DEFAULT_DIR      : $DEFAULT_DIR
  * BASE_URL         : $BASE_URL
  * URL_REPLACE_FROM : $URL_REPLACE_FROM
  * URL_REPLACE_TO   : $URL_REPLACE_TO
  * Wakati           : $WAKATI
  * LOGGING          : $LOGGING
  * LANGUAGE         : $LANGUAGE
  * SCORING          : $SCORING
ENDOFPRINTCONF
exit;
}

sub command_line_opt{
    local($_);
    while (defined($_ = shift(@ARGV))){
        if (s/^-//){
            while (s/^.//){
                if ($& eq 'n'){
                    $_ = shift(@ARGV) if /^$/;
                    $Max = $_;
                    last;
                }
                if ($& eq 'w'){
                    $_ = shift(@ARGV) if /^$/;
                    $Whence = $_;
                    last;
                }
                if ($& eq 's'){$Format = 'short';}
                if ($& eq 'S'){$Format = 'veryshort';}
                if ($& eq 'h'){$PlainConv = 0;}
                if ($& eq 'H'){$PageIndex = 1;}
                if ($& eq 'F'){$PrintForm = 1;}
                if ($& eq 'a'){$Max = 0; $Whence = 0;}
                if ($& eq 'l'){$Sort = 'later'}
                if ($& eq 'e'){$Sort = 'earlier'}
                if ($& eq 'R'){$Replace = 0;}
                if ($& eq 'U'){$DecodeURL = 0;}
                if ($& eq 'L'){
                    $_ = shift(@ARGV) if /^$/;
                    $LANGUAGE = $_;
                    $LANGUAGE = "ja" if($LANGUAGE =~ /JAPANESE/i);
                    $LANGUAGE = "en" if($LANGUAGE =~ /ENGLISH/i);
                    last;
                }
                if ($& eq 'C'){&load_namazu_conf;
                               &show_configuration;}
                if ($& eq 'f'){
                    $_ = shift(@ARGV) if /^$/;
                    $NamazuConf = $_;
                    &load_namazu_conf;
                    last;
                }
                if ($& eq 'v'){&usage;}
                if ($& eq 'o'){close(STDOUT);
                               $_ = shift(@ARGV) if /^$/;
                               open(STDOUT, ">$_") || die;
                               last;}
                if ($& eq 'd'){$| = $Debug = 1;}
            }
        }else{
            unshift(ARGV, $_);
            last;
        }
    }
    if ($#ARGV > 0){
        if ($CmdLineArg ne 'old' && -d $ARGV[$#ARGV]){
            $DEFAULT_DIR = pop(@ARGV);
        }elsif ($CmdLineArg ne 'new' && -d $ARGV[0]){
            $DEFAULT_DIR = shift(@ARGV);
        }
    }elsif ($#ARGV < 0){
        &usage;
    }
    $ARGV = join(' ', @ARGV);
}
1;
#-------------------- End of 'command line' Module -------------------

