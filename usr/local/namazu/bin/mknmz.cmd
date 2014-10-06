EXTPROC perl.exe -Sx
#!/usr/bin/perl
#
# mknmz.pl - indexer of Namazu
# Version   1.3.0.11 [01/26/2000]
#
# Copyright (C) 1997-1999 Satoru Takabayashi  All rights reserved.
#     This is free software with ABSOLUTELY NO WARRANTY.
#
#  This program is free software; you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation; either versions 2, or (at your option)
#  any later version.
# 
#  This program is distributed in the hope that it will be useful
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with this program; if not, write to the Free Software
#  Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA
#  02111-1307, USA
#
#  This file must be encoded in EUC-JP encoding
#

package main;
require 5.003;
use Cwd;
use Time::Local;
use strict;  # be strict since v1.2.0

##
## software information
##
my $VERSION = "1.3.0.11";
my $COPYRIGHT = "Copyright (C) 1997-1999 Satoru Takabayashi  All rights reserved.";
my $NMZ_URL = "http://openlab.ring.gr.jp/namazu/";

# Japanese usage
my $USAGE_JA = <<EOFusage;
  mknmz.pl v$VERSION -  全文検索システム Namazu のインデックス作成プログラム
  $COPYRIGHT

  使い方: $0 [options] [URL_PREFIX] <対象dir>
      -a: すべてのファイルを対象とする
      -c: 日本語の単語のわかち書きに ChaSen を用いる
      -e: ロボットよけされているファイルを除外する
      -h: Mail/News のヘッダ部分をそれなりに処理する
      -k: 日本語の単語のわかち書きに KAKASI を用いる
      -m: ChaSen の形態素解析の品詞情報を利用する (名詞のみ登録)
      -q: インデックス処理の最中にメッセージを表示しない
      -r: man のファイルを処理する
      -u: uuencode と BinHex の部分を無視する
      -x: HTML のヘディングによる要約作成を行わない (文書の先頭から作成)
      -D: Date:, From: といったヘッダを要約につけない (ディフォルトではつける)
      -E: 単語の両端の記号は削除する (ディフォルトでは含める)
      -G: 送り仮名を削除する (ディフォルトでは含める)
      -H: 平仮名のみの単語は登録しない (ディフォルトでは登録を行う)
      -K: 記号はすべて削除する (ディフォルトでは登録を行う)
      -L: 行頭・行末の調整処理を行わない (ディフォルトでは調整を行う)
      -M: MHonArc で作成された HTML の処理を行わない (ディフォルトでは行う)
      -P: フレーズ検索用のインデックスを作成しない (ディフォルトでは作成する)
      -R: 正規表現検索用のインデックスを作成しない (ディフォルトでは作成する)
      -U: URLのencodeを行わない (ディフォルトでは行う)
      -W: 日付によるソート用のインデックス作らない (ディフォルトでは作成する)
      -X: フィールド検索用のインデックスを作らない (ディフォルトでは作成する)
      -Y: 削除された文書の検出を行わない (ディフォルトでは行う)
      -Z: 文書の更新/削除を反映しない (ディフォルトでは行う)
      -A: .htaccess で制限されたファイルを除外する
      -l (lang): 言語を設定する ('en' or 'ja')
      -F (file): インデックス対象のファイルのリストを読み込む
      -I (file): ユーザ定義のファイルをインクルードする
      -O (dir) : インデックスファイルの出力先を指定する
      -T (dir) : NMZ.{head,foot,body}.* のディレクトリを指定する
      -t (regex): 対象ファイルの正規表現を指定する

EOFusage

my $USAGE_EN = <<EOFusage;
  mknmz.pl v$VERSION -  indexer of Namazu
  $COPYRIGHT

   Usage: $0 [options] [URL_PREFIX] <target dir>
      -a: target all files
      -c: use ChaSenI as Japanese processor
      -e: exclude files which has robot exclusion
      -h: treat header part of Mail/News well
      -k: use KAKASI as Japanese processor
      -m: use ChaSenI as Japanese processor with morphological processing
      -q: suppress status messages during execution
      -r: treat man files
      -u: decode uuencoded part and discard BinHex part
      -x: do not make summary with structure of HTML's headings
      -D: do not insert headers such as 'Date:' to summary (default: off)
      -E: delete symbols on edge of word (default: off)
      -G: delete Okurigana in word (default: off)
      -H: ignore words consist of Hiragana only (default: off)
      -K: delete all symbols (default: off)
      -L: do not adjust beginning and end of line (default: off)
      -M: do not do special processing for MHonArc (default: off)
      -P: do not make the index for phrase search (default: off)
      -R: do not make the index for regexp search (default: off)
      -U: do not encode URL (default: off)
      -W: do not make the index for sort by date (default: off)
      -X: do not make the index for field search (default: off)
      -Y: do not detect deleted documents (default: off)
      -Z: do not detect update and deleted documents (default: off)
      -A: exclude files restricted by .htaccess
      -l (lang): specify the language ('en' or 'ja', default:en)
      -I (file): include user defined file in advance of index processing
      -F (file): load a file which contains list of target files
      -O (dir) : specify a directory to output the index
      -T (dir) : specify a directory where NMZ.{head,foot,body}.* are
      -t (regex): specify a regex for target files

EOFusage

##
## required softwares
##

## Network Kanji Filter nkf v1.62
my $NKF = "nkf2"; 

## KAKASI or ChaSen (to handle Japanese characters)
## KAKASI must have -w option added by Hajime BABA-san
my $KAKASI = "kakasi -ieuc -oeuc -w";

## ChaSen 1.51 (simple wakatigaki)
my $CHASEN = "chasen -j -F '\%m '";

## ChaSen 1.51 (with morphological processing)
my $CHASEN_MORPH = "chasen -j -F '\%m %H\\n'";

## Default Japanese processer
my $NONE = '';
my $WAKATI  = $KAKASI;
my $MorphOpt = 1 if "KAKASI" eq "CHASEN_MORPH";

## Table of helper programs and extentions
my %HELPER_PROGRAMS = (
    'gz'  => 'zcat',
    'Z'   => 'zcat',
    'man' => 'groff -man -Tnippon',
);

## Make regex of extensions
my $HELPER_EXTENSIONS = 
    join('|', sort {length($b) <=> length($a)} keys %HELPER_PROGRAMS);

##
## Names of Index files
##
my $DBNAME     = "NMZ";
my $FLIST      = "$DBNAME.f";
my $FLISTINDEX = "$DBNAME.fi";
my $INDEX      = "$DBNAME.i";
my $INDEXINDEX = "$DBNAME.ii";
my $HASH       = "$DBNAME.h";
my $REGLIST    = "$DBNAME.r";
my $HEADERFILE = "$DBNAME.head";
my $FOOTERFILE = "$DBNAME.foot";
my $LOGFILE    = "$DBNAME.log";
my $SLOGFILE   = "$DBNAME.slog";
my $LOCKFILE   = "$DBNAME.lock";
my $LOCKFILE2  = "$DBNAME.lock2";
my $LOCKMSGFILE = "$DBNAME.msg";
my $BODYMSGFILE = "$DBNAME.body";
my $ERRORSFILE = "$DBNAME.err";
my $BIGENDIAN  = "$DBNAME.be";
my $LITTLEENDIAN  = "$DBNAME.le";
my $WAKATITMP = "$DBNAME.wkc.$$";
my $TMP_I      = "$DBNAME.tmp_i.$$";
my $TMP_W      = "$DBNAME.tmp_w.$$";
my $TMP_P      = "$DBNAME.tmp_p.$$";
my $TMP_PI     = "$DBNAME.tmp_pi.$$";

my $WORDLIST    = "$DBNAME.w";
my $PHRASE      = "$DBNAME.p";
my $PHRASEINDEX = "$DBNAME.pi";
my $FIELDINFO = "$DBNAME.field";

my $DATEINDEX = "$DBNAME.t";
my $TOTALFILESCOUNT = "$DBNAME.total";

##
## Default values
##
my $LIBDIR = "d:/usr/local//namazu/lib";      # directory contains library and etc.
my $LANGUAGE = "ja";  # language of messages
#$SYSTEM = "OS2";     # UNIX/MSWin32/os2
my $ADMIN  = 'webmaster@foo.bar.jp'; # admin's email address
my $CGI_ACTION = '/cgi-bin/namazu.cgi'; # <FORM> 's ACTION の指定

## Prefix of URL (\t will be treated as full path name)
my $URL_PREFIX = "\t";

## Files can be omission in URL. e.g. index.html
my $DEFAULT_FILE = "_default";

## Target files' regex
my $TARGET_FILE = '.*\.html?|.*\.txt|.*_default';

## Non-Target files' regex
my $DENY_FILE = '.*\.gif|.*\.(jpg|jpeg)|.*\.tar\.gz|core|.*\.bak|.*~|\..*|\x23.*|NMZ\..*';

## HTML extentions like .htm, .html, .shtml, .phtml, .html.en, .html.ja, .asp
my $HTML_SUFFIX = 'html?|[ps]html|html\.[a-z]{2}|asp|cgi';

## Place where CGI prgrams is in. e.g. /cgi-bin/, /htbin/
my $CGI_DIR = '/(cgi-bin|htbin)/';

## MHonArc's message file
my $MHONARC_MESSAGE_FILE = 'msg\d{5}\.html(?:\.gz)?';

## MHonArc's header for identification (regex)
my $MHONARC_HEADER = '<\!-- MHonArc v\d\.\d\.\d -->';

## Mail/News's headers should be remained as searchable text
## (case insensitive)
my $REMAIN_HEADER = "From|Date|Message-ID";

## Mail/News's headers should be inserted in search results
my $SUMMARY_HEADER = "From|Date|Author|Newsgroups";

## Mail/News's headers for field specified search (NMZ.field.*)
my $SEARCH_FIELD = "Message-Id|Subject|From|Date|Url|Newsgroups|To";

## Aliases for NMZ.field.*
my %FIELD_ALIASES = ('title' => 'subject', 'author' => 'from');


my $TEXT_TITLE = " (Text File) "; # text file
my $NO_TITLE = "No title in original";    # document has no title


## 
## Size of files indexed at once on memory. (bytes)
## If you have much memory, you can increase this value. (128MB or more)
## If you have not much memory, you can decrease this value. (32MB or less)
##
my $ON_MEMORY_MAX   = 5000000;
#                  M  K  bytes   

## File size limitation. The file larger than this value will not be indexed.
my $FILE_SIZE_LIMIT = 600000;
#                   M  K  bytes   

## Word length limitation. The word longer than this value will be ignored.
my $WORD_LENG_MAX   = 128;


##
## Weights for HTML elements
## Element names should be described in CAPITAL letter
##
my $TITLEW     = 16;  # only TITLE has own variable

my %TAGW = ();
$TAGW{'H1'} = 8;
$TAGW{'H2'} = 7;
$TAGW{'H3'} = 6;
$TAGW{'H4'} = 5;
$TAGW{'H5'} = 4;
$TAGW{'H6'} = 3;
$TAGW{'A'}  = 4;
$TAGW{'STRONG'} =  2;
$TAGW{'EM'}     =  2;
$TAGW{'KBD'}    =  2;
$TAGW{'SAMP'}   =  2;
$TAGW{'VAR'}    =  2;
$TAGW{'CODE'}   =  2;
$TAGW{'CITE'}   =  2;
$TAGW{'ABBR'}   =  2;
$TAGW{'ACRONYM'} =  2;
$TAGW{'DFN'}    =  2;

## Weight for Mail/News's header
my $REMAIN_HEADER_W = 8;

##
## タグを捨てる際に空白を挿入しないタグ
## 例えば、これは<STRONG>重要</STRONG>です。などという文脈ではタグは削除すべき
## だが、 This is foo.<BR>That is bar. という文脈ではタグは空白に変換すべき
##
my $NON_SEPARATION_TAGS = 'A|TT|CODE|SAMP|KBD|VAR|B|STRONG|I|EM|CITE|FONT|U|'.
                       'STRIKE|BIG|SMALL|DFN|ABBR|ACRONYM|Q|SUB|SUP|SPAN|BDO';


## タグによる重みづけする際にこの数字以上の長さの文字列の場合は重
## みづけをしない (<H[1-6]> を文字サイズの指定のために本文全体を囲ったり
## している人がいるための処置)
my $INVALID_LENG = 128; 


##
## Weight for <META NAME="keywords" CONTENT="foo bar">
##
my $METAKEYW = 32;



## Length of summary
my $SUMMARY_LENGTH = 200;

##
## robots.txt に関する設定
##

my $HTDOCUMENT_ROOT = "%OPT_HTDOCUMENT_ROOT%";
my $HTDOCUMENT_ROOT_URL_PREFIX = "%OPT_HTDOCUMENT_ROOT_URL_PREFIX%";
my $ROBOTS_TXT = "$HTDOCUMENT_ROOT/robots.txt";
my $ROBOTS_EXCLUDE_URLS = "%OPT_ROBOTS_EXCLUDE_URLS%";

# hogehoge
my $DeletedFilesCount = 0;
my $UpdatedFilesCount = 0;
my $APPENDMODE = 0;
my $LastKeyN = 0;
my $INTSIZE = 4;
my $UnsignedCmp = 0;

my @FList = ();
my @Seed = ();
my %PreupdatedFields = ();
my %PhraseHash = ();
my %KeyIndex = ();

my $SYSTEM = "";
my $PSC = "/";
my $CCS = "euc";

my $LOCK_MSG_JA = "";
my $LOCK_MSG_EN = "";
my $BODY_MSG_JA = "";
my $BODY_MSG_EN = "";

my $LIBDIR2 = "";
my $DATEINDEX_ = "";
my $TARGET_DIR = "";
my $FLIST_ = "";
my $INDEX_ = "";
my $HEADERFILE_ = "";
my $FOOTERFILE_ = "";
my $PHRASE_     = "";
my $PHRASEINDEX_ = "";
my $REGLIST_ = "";
my $FLISTINDEX_ = "";
my $INDEXINDEX_ = "";
my $HASH_ = "";
my $WORDLIST_ = "";

# options
my $NoPhraseIndexOpt = 0;
my $DebugOpt         = 0;
my $QuietOpt         = 0;
my $RobotExcludeOpt  = 0;
my $NoFieldInfoOpt   = 0;
my $NoDateIndexOpt   = 0;
my $ManOpt           = 0;
my $NoMHonArcOpt     = 0;
my $UuencodeOpt      = 0;
my $MailNewsOpt      = 0;
my $NoLineAdOpt      = 0;
my $NoHeadAbstOpt    = 0;
my $HiraganaOpt      = 0;
my $OkuriganaOpt     = 0;
my $NoEdgeSymbolOpt  = 0;
my $NoSymbolOpt      = 0;
my $NoEncodeURL      = 0;
my $NoRegexpIndexOpt = 0;
my $NoInsertHeaderOpt = 0;
my $NoDeleteProcessing = 0;
my $NoUpdateProcessing = 0;
my $HtaccessExcludeOpt  = 0;

##
## Program begins
##

# STDOUT->autoflush(1); 
$| = 1;                # autoflush STDIN
initialize();

main();
sub main () {
    my ($swap, $all_file_size, $cfile_size, $file_count, $cfile,
       $start_time, $file_segment, $tmp);
    $file_segment = 0;

    $start_time = time;
    $file_segment = preparation_process();
    set_lockfile($LOCKFILE2);
    
    $swap = 1;
    $file_count = 0;
    $all_file_size = 0;
    my $key_count = 0;

    # Process target files one by one
    foreach $cfile (@FList) {
	$cfile_size = namazu_core($cfile, $file_count, $file_segment);
	unless ($cfile_size) {
	    $cfile = "" ;  # remove @FList entry
	    next;
	}
	$all_file_size += $cfile_size;
	$file_count++;
	if ($all_file_size > $ON_MEMORY_MAX * $swap) {
	    if (%KeyIndex) {
		$key_count = put_index();
		put_phrase_hash()
		    unless $NoPhraseIndexOpt;
	    }
	    $swap++;
	}
    }
    if (%KeyIndex) {
	$key_count = put_index();
	put_phrase_hash()
	    unless $NoPhraseIndexOpt;
    }

    remain_process($all_file_size, $file_count, $key_count, $start_time);
}

sub dprint (@) {
    print STDERR @_ if $DebugOpt;
} 

# Initializer
#   $PSC: Path Separate Character '/' or '\'
#   $CCS: Character Coding System 'euc' or 'sjis'
sub initialize () {
    get_int_size();
    @Seed = init_seed();
    $SYSTEM= $^O;             # $^O contains system name

    if (($SYSTEM eq "MSWin32") || ($SYSTEM eq "os2")) {
	$PSC = "\\";
	$CCS = "sjis";
 	$0 =~ m#^([A-Z]:)(/|\\)#i, 
	$LIBDIR = $1 . $LIBDIR if ($LIBDIR !~ /^[A-Z]:/i);
    } else {
	$PSC = "/";
	$CCS = "euc";
    }
    $LIBDIR2 = cwd() . "${PSC}..${PSC}lib";
}

# Core routine
sub namazu_core ($$$) {
    my ($cfile, $file_count, $file_segment) = @_;
    my ($url, $cfile_size, $ctrl, $kanji, %fields);
    my ($title, $weighted_str, $contents, $headings, $err);
    $headings = "";
    $contents = "";
    $weighted_str = "";

    $url = url_decchiagator($cfile);  # Make a URL from a file name

    ($cfile_size, $ctrl, $kanji) = load_document(\$cfile, \$contents);
    # Do checking
    if ($err = check_file($cfile, \$contents, $ctrl, $cfile_size)) {
	print $file_count + $file_segment . " $url $err\n" unless $QuietOpt;
	print ERRORSFILE "$cfile $err\n"; 
	return 0;  # return with 0 if error
    }
    if ($RobotExcludeOpt) {
	if ($url =~ m/$ROBOTS_EXCLUDE_URLS/i) {
	    $err = "is excluded because of /robots.txt.\n";
	    print $file_count + $file_segment . " $url $err\n";
	    print ERRORSFILE "$cfile $err\n"; 
	    return 0;  # return with 0 if error
	} elsif ($cfile =~ /\.($HTML_SUFFIX)$/i &&
		 $contents =~ /META\s+NAME\s*=\s*([\'\"]?)ROBOTS\1\s+[^>]*
		 CONTENT\s*=\s*([\'\"]?).*?(NOINDEX|NONE).*?\2[^>]*>/ix) 
	{
	    $err = "is excluded because of <META> element.";
	    print $file_count + $file_segment . " $url $err\n" unless $QuietOpt;
	    print ERRORSFILE "$cfile $err\n"; 
	    return 0;  # return with 0 if error
	}
    }
    # Output processing file name as URL
    print $file_count + $file_segment . " $url\n" unless $QuietOpt;

    document_filter($cfile, \$title, \$contents, \$weighted_str,
		     \$headings, \%fields);
    make_field_info(\%fields, $cfile, $title, $url);

    put_file_info($url, $title, $cfile_size, \$contents,
		  \$headings, $cfile, \%fields);
    put_field_info(\%fields) unless $NoFieldInfoOpt;

    put_dateindex($cfile) unless $NoDateIndexOpt;
    $contents .= $weighted_str;   # add weight info
    count_words($file_count, $file_segment, \$contents, $kanji);
    make_phrase_hash($file_count, $file_segment, \$contents)
	unless $NoPhraseIndexOpt;
    $cfile_size;
}

sub make_field_info (\%$$$) {
    my ($fields, $cfile, $title, $url) = @_;

    unless (defined($fields->{date})) {
	my $mtime = (stat($cfile))[9];
	my $date = rfc822time($mtime);
	$fields->{date} = $date;
    }
    unless (defined($fields->{title})) {
	my $tmp = $title;
	decode_entity(\$tmp);  # since $title has been already encoded
	$fields->{title} = $tmp;
    }
    unless (defined($fields->{url})) {
	$fields->{url} = $url;
    }
}

# RFC 822 format without timezone
sub rfc822time ($)
{
    my ($time) = @_;

    my @week_names = ("Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat");
    my @month_names = ("Jan", "Feb", "Mar", "Apr", "May", "Jun",
		       "Jul", "Aug", "Sep", "Oct", "Nov", "Dec");
    my ($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst) 
	= localtime($time);

    sprintf("%s, %.2d %s %d %.2d:%.2d:%.2d", 
             $week_names[$wday],
             $mday, $month_names[$mon], $year + 1900,
                $hour, $min, $sec);
}

# output the field infomation into NMZ.fileds.* files
sub put_field_info (\%) {
    my ($orig_fields) = @_;
    my ($key, @keys, $field);
    my (%fields) = %{$orig_fields};

    my $aliases_regex = 
	join('|', sort {length($b) <=> length($a)} keys %FIELD_ALIASES);
    foreach $field (keys %{fields}) {
	if ($field =~ /^($aliases_regex)$/) {
	    unless (defined($fields{$FIELD_ALIASES{$field}})) {
		$fields{$FIELD_ALIASES{$field}} = $fields{$field};
	    }
	    undef $fields{$field};
	}
    }
    @keys = split('\|', $SEARCH_FIELD);
    foreach $key (@keys) {
	$key = lc($key);
	my $fname = "$FIELDINFO.$key.$$";
	open(FIELD, ">>$fname") || die "$fname: $!\n";
	binmode(FIELD);
	if (defined($fields{$key})) {
	    $fields{$key} =~ s/\s+/ /g;
	    $fields{$key} =~ s/\s+$//;
	    $fields{$key} =~ s/^\s+//;
	    print FIELD $fields{$key}, "\n";
	} else {
	    print FIELD "\n";
	}
	close(FIELD);
	$PreupdatedFields{$key} = 1;
    }
}


# put the date infomation into NMZ.t file
sub put_dateindex ($) {
    my ($cfile) = @_;
    my $mtime = (stat($cfile))[9];

    open(DATEINDEX, ">>$DATEINDEX_") || die "$DATEINDEX_: $!\n";
    binmode(DATEINDEX);
    print DATEINDEX pack("i", $mtime);
    close(DATEINDEX);
}


# load a document file
sub load_document ($$) {
    my ($orig_cfile, $contents) = @_;
    my ($line, $omake, $size, $ctrl, $kanji, $zipped, $filter, $ext);
    my $cfile = $$orig_cfile;

    return (0, 0, 0) unless (-f $cfile && -r $cfile);
    $ctrl = 0;
    $size = -s $cfile;
    return ($size, $ctrl, 0) if $size > $FILE_SIZE_LIMIT;

    # for handling a file which contains Shift_JIS code
    my $shelter_cfile = "";
    my $shelter_ext = "";
    if ($SYSTEM eq "MSWin32" 
	&& $cfile =~ /[\x81-\x9f\xe0-\xef][\x40-\x7e\x80-\xfc]|[\x20\xa1-\xdf]/) 
    {
	$shelter_cfile = $cfile;
	$cfile = $TMP_W;
    while ($shelter_cfile =~ /^.*\.($HELPER_EXTENSIONS)$/o) {
	$shelter_ext = $1;
    $cfile .= '.'.$shelter_ext;
	last;
    } 
	use File::Copy;
	copy("$shelter_cfile","$cfile");
    }

    $filter = "";    
    while ($cfile =~ /^.*\.($HELPER_EXTENSIONS)$/) {
	$ext = $1;
	if ($filter eq "") {
	    $filter = "$HELPER_PROGRAMS{$ext} \"$cfile\" |";
	} else {
	    $filter .= "$HELPER_PROGRAMS{$ext} |";
	}
	# if .gz or .Z, suppress the extention and continue
	if ($ext =~ /^(gz|Z)$/) {
	    $zipped = 1;
	    $cfile =~ s/\.$ext$//;
	} else {
	    last;
	}
    } 
    if ($LANGUAGE eq "ja") {
	if ($filter eq "") {
	    $filter = "$NKF -emXZ1 \"$cfile\" |";
	} else {
	    $filter .= "$NKF -emXZ1 |";
	}
    } else {
	if ($filter eq "") {
	    $filter = "$cfile";
	}
    }
    if ($ManOpt) { # man mode
	if ($filter =~ /\|$/) {
	    $filter .= "$HELPER_PROGRAMS{'man'} |";
	} else {
	    $filter = "$HELPER_PROGRAMS{'man'}" . $filter . "|";
	}
    }

    # consider a filename containing Shift_JIS under OS/2.
    $filter =~ s|\\|\\\\|g if $SYSTEM eq "os2";
    open(CFILE, $filter) || die "$cfile: $!\n";
    $$contents = join("", <CFILE>);

    # for handling a file which contains Shift_JIS code
    if ($SYSTEM eq "MSWin32" && $shelter_cfile ne "") {
	unlink "$cfile.$shelter_ext";
	$cfile = $shelter_cfile;
    }

    # if a zipped file, the size has been changed
    if ($zipped) {
	$size = length($$contents);
	return ($size, $ctrl, 0) if $size > $FILE_SIZE_LIMIT;
    }

    if ($ManOpt) { # processing like col -b (2byte character acceptable)
	$$contents =~ s/_\x08//g;
	$$contents =~ s/\x08{1,2}([\x20-\x7e]|[\xa1-\xfe]{2})//g;
    }

    $$contents =~ s/[ \t]+/ /g;   # remain LFs v1.03
    $$contents =~ s/\r\n/\n/g;    # remain LFs is for ChaSen
    $$contents =~ s/\r/\n/g;      # CR+LF or CR are into LF
    # Control characters be into space
    $ctrl = $$contents =~ tr/\x00-\x09\x0b-\x1f\xff/   /;
    $kanji = $$contents =~ tr/\xa1-\xfe/\xa1-\xfe/;  # Kanji contained?
    close(CFILE);
    ($size, $ctrl, $kanji);
}

# not implimented yet.
sub analize_rcs_stamp()
{
}

# Filters
sub document_filter ($$$$$$\%) {
    my ($orig_cfile, $title, $contents, $weighted_str, $headings, $fields)
	= @_;
    my ($mhonarc_opt);
    my $cfile = $orig_cfile;
    $cfile =~ s/\.(gz|Z)$//;  # zipped file

    analize_rcs_stamp();
    $mhonarc_opt = 1 if 
	(!$NoMHonArcOpt && $$contents =~/^$MHONARC_HEADER/);
    if (ishtml($cfile)) {
	mhonarc_filter($contents, $weighted_str) 
	    if $mhonarc_opt;
	html_filter($contents, $weighted_str, $title, $fields, $headings);
    } elsif ($cfile =~ /rfc\d+\.txt/i ) {
	rfc_filter($contents, $weighted_str, $title);
    } elsif ($ManOpt) {
	man_filter($contents, $weighted_str, $title);
    }
    uuencode_filter($contents) if $UuencodeOpt;
    if ($mhonarc_opt  || $MailNewsOpt) {
	mailnews_filter($contents, $weighted_str, $title, $fields);
	mailnews_citation_filter($contents, $weighted_str);
    }
    line_adjust_filter($contents) unless $NoLineAdOpt;
    line_adjust_filter($weighted_str) unless $NoLineAdOpt;
    white_space_adjust_filter($contents);
    filename_to_title($cfile, $title, $weighted_str) unless $$title;
    show_filter_debug_info($contents, $weighted_str,
			   $title, $fields, $headings);
}

# Show debug information for filters
sub show_filter_debug_info ($$$$) {
    my ($contents, $weighted_str, $title, $fields, $headings) = @_;
    dprint "-- title --\n$$title\n";
    dprint "-- contents: --\n$$contents\n";
    dprint "-- weighted_str: --\n$$weighted_str\n";
    dprint "-- headings: --\n$$headings\n";
}

# Adjust white spaces
sub white_space_adjust_filter ($) {
    my ($text) = @_;
    $$text =~ s/^ +//gm;
    $$text =~ s/ +$//gm;
    $$text =~ s/ +/ /g;
    $$text =~ s/\n+/\n/g;
}

# ファイル名からタイトルを取得 (単なるテキストファイルの場合)
sub filename_to_title ($\$\$) {
    my ($cfile, $title, $weighted_str) = @_;
    my ($tmp);

    # for MSWin32's filename using Shift_JIS [09/24/1998]
    if (($SYSTEM eq "MSWin32") || ($SYSTEM eq "os2")) {
	$cfile = codeconv::shiftjis_to_eucjp($cfile);
    }

    $cfile =~ /^.*\Q$PSC\E([^\Q$PSC\E]*)$/ ;
    my $filename = $1;
    # ファイル名を元にキーワードを割り出してみる v1.1.1
    # modified [09/18/1998] 
    $tmp = $filename;
    $tmp =~ s|/\\_\.-| |g;
    $$weighted_str .= "\x7f$TITLEW\x7f$tmp\x7f/$TITLEW\x7f\n";

    $$title = $filename . $TEXT_TITLE;
}

# HTML 用のフィルタ
sub html_filter ($$$$$) {
    my ($contents, $weighted_str, $title, $fields, $headings) = @_;

    escape_lt_gt($contents);
    get_html_title($contents, $weighted_str, $title);
    get_author($contents, $fields);
    get_meta_info($contents, $weighted_str);
    get_img_alt($contents);
    get_table_summary($contents);
    get_title_attr($contents);
    normalize_html_tag($contents);
    erase_above_body($contents);
    weight_tag($contents, $weighted_str, $headings);
    erase_html_tags($contents);
    # それぞれ実体参照の復元
    decode_entity($contents);
    decode_entity($weighted_str);
    decode_entity($headings);
}

# 単独の < > を実体参照に変換し、保護する
# この処理は Perl の正規表現置換の仕様により、二重に行います
sub escape_lt_gt ($) {
    my ($contents) = @_;

    $$contents =~ s/\s<\s/ &lt; /g;
    $$contents =~ s/\s>\s/ &gt; /g;
    $$contents =~ s/\s<\s/ &lt; /g;
    $$contents =~ s/\s>\s/ &gt; /g;
}

sub get_author ($$) {
    my ($contents, $fields) = @_;
    my ($author);

    # <LINK REV=MADE HREF="mailto:ccsatoru@vega.aichi-u.ac.jp">

    if ($$contents =~ m!<LINK\s[^>]*?HREF=([\"\'])mailto:(.*?)\1>!i) {
	    $fields->{author} = $2;
    } elsif ($$contents =~ m!.*<ADDRESS[^>]*>([^<]*?)</ADDRESS>!i) {
	my $tmp = $1;
#	$tmp =~ s/\s//g;
	if ($tmp =~ /\b([\w\.\-]+\@[\w\.\-]+(?:\.[\w\.\-]+)+)\b/) {
	    $fields->{author} = $1;
	}
    }
    
}

# TITLE を取り出す <TITLE LANG="ja_JP"> などにも考慮しています
# </TITLE> が二つ以上あっても大丈夫 v1.03
sub get_html_title ($$$$) {
    my ($contents, $weighted_str, $title) = @_;
    
    if ($$contents =~ s/<TITLE[^>]*>([^<]+)<\/TITLE>//i) {
	$$title = $1;
	# TITLE を TITLEW 倍して末尾に追加 
	$$weighted_str .= "\x7f$TITLEW\x7f$$title\x7f/$TITLEW\x7f\n";
    }
    else {
	$$title = $NO_TITLE;
    }
    $$title =~ s/\s+/ /g;
    $$title =~ s/^\s+//;
    $$title =~ s/\s+$//;
}

# <META NAME="keywords|description" CONTENT="foo bar"> に対応する処理
sub get_meta_info ($$) {
    my ($contents, $weighted_str) = @_;

    $$weighted_str .= "\x7f$METAKEYW\x7f$3\x7f/$METAKEYW\x7f\n" if $$contents =~ /<META\s+NAME\s*=\s*([\'\"]?)KEYWORDS\1\s+[^>]*CONTENT\s*=\s*([\'\"]?)([^>]*?)\2[^>]*>/i;
    $$weighted_str .= "\x7f$METAKEYW\x7f$3\x7f/$METAKEYW\x7f\n" if $$contents =~ /<META\s+NAME\s*=\s*([\'\"]?)DESCRIPTION\1\s+[^>]*CONTENT\s*=\s*([\'\"]?)([^>]*?)\2[^>]*>/i;
}

# <IMG ... ALT="foo"> の foo の取り出し
# HTML の扱いは厳密ではないです
sub get_img_alt ($) {
    my ($contents) = @_;

    $$contents =~ s/<IMG[^>]*\s+ALT\s*=\s*[\"\']?([^\"\']*)[\"\']?[^>]*>/ $1 /gi;
}

# <TABLE ... SUMMARY="foo"> の foo の取り出し
sub get_table_summary ($) {
    my ($contents) = @_;

    $$contents =~ s/<TABLE[^>]*\s+SUMMARY\s*=\s*[\"\']?([^\"\']*)[\"\']?[^>]*>/ $1 /gi;
}

# <XXX ... TITLE="foo"> の foo の取り出し
sub get_title_attr ($) {
    my ($contents) = @_;

    $$contents =~ s/<[A-Z]+[^>]*\s+TITLE\s*=\s*[\"\']?([^\"\']*)[\"\']?[^>]*>/ $1 /gi;
}

# <A HREF...> などを <A> に統一 (エレメントをすべて削除)
sub normalize_html_tag ($) {
    my ($contents) = @_;

    $$contents =~ s/<([!\w]+)\s+[^>]*>/<$1>/g;
}

sub erase_above_body ($) {
    my ($contents) = @_;

    $$contents =~ s/^.*<BODY>//si;
}


# %TAGW に設定されている数値に応じて \x7fXX\x7f, \x7f/XX\x7f という架空のタグ
# を作り、これで挟んでおく (\x7f は予めすべて空白に変換してある)
# 単語のカウントの際にこの架空のタグを利用して計算する
# <A> が最初に処理されるように sort keys しています(安直)。
# というのは <A> は他のタグの内側に来ることが多いからです
# 厳密な入れ子処理は行っていません
# さらに <H[1-6]> については要約作成のために怪しい処理をしている
sub weight_tag ($$$ ) {
    my ($contents, $weighted_str, $headings) = @_;
    my ($tag);

    foreach $tag (sort keys(%TAGW)) {
	my ($tmp, $tagw);
	$tmp = "";
	$$contents =~ s/<($tag)>(.*?)<\/$tag>/weight_tag_sub($1, $2, \$tmp)/gies;
	$$headings .= $tmp if $tag =~ /^H[1-6]$/i && ! $NoHeadAbstOpt 
	    && $tmp;
	$tagw = $tag =~ /^H[1-6]$/i && ! $NoHeadAbstOpt ? 
	    $TAGW{$tag} : $TAGW{$tag} - 1;
	$$weighted_str .= "\x7f$tagw\x7f$tmp\x7f/$tagw\x7f\n" if $tmp;
    }
}

# HTML タグをすべて削除,タグによって空白を入れたり入れなかったりする
sub erase_html_tags ($) {
    my ($contents) = @_;

    1 while ($$contents =~ s/<\/?([^<>]*)>/tag_to_space_or_null($1)/ge);
}

# 指定されたタグの文字列を処理するためのサブルーチン
sub weight_tag_sub ($$$) {
    my ($tag, $text, $tmp) = @_;
    my ($space);

    $space = tag_to_space_or_null($tag);
    $text =~ s/<[^>]*>//g;
    $$tmp .= "$text " if (length($text)) < $INVALID_LENG;
    $tag =~ /^H[1-6]$/i && ! $NoHeadAbstOpt  ? " " : "$space$text$space";
}

# numberd entity の復元を行う /  無効な値ははじく
sub decode_numbered_entity ($) {
    my ($num) = @_;
    return ""
	if $num >= 0 && $num <= 8 ||  $num >= 11 && $num <= 31 || $num >=127;
    sprintf ("%c",$num);
}


# 実体参照の復元 ISO-8859-1 の右半分は無視します
# HTML 2.x で拡張された numbered entity には未対応です
# どちらも日本語 EUC では無理なのです
# &quot &lt &gt; のように空白で続けて最後に ; をつける記述も大丈夫 v1.03
sub decode_entity ($) {
    my ($text) = @_;

    return unless defined($$text);

    $$text =~ s/&#(\d{2,3})[;\s]/decode_numbered_entity($1)/ge;
    $$text =~ s/&quot[;\s]/\"/g;
    $$text =~ s/&amp[;\s]/&/g;
    $$text =~ s/&lt[;\s]/</g;
    $$text =~ s/&gt[;\s]/>/g;
    $$text =~ s/&nbsp/ /g; ## 特別扱い v1.1.2.1
}


# '<' と '>' '&' を実体参照へ変換
sub encode_entity ($) {
    my ($tmp) = @_;

    $$tmp =~ s/&/&amp;/g;    # &amp; は最初に処理しないとまずい
    $$tmp =~ s/</&lt;/g;
    $$tmp =~ s/>/&gt;/g;
    $$tmp;
}

# 指定されたタグが単に削除すべきものか空白に変換すべきか判定する
sub tag_to_space_or_null ($) {
    $_[0] =~ /^($NON_SEPARATION_TAGS)$/i ? "" : " ";
}


# MHonArc 用のフィルタ
# MHonArc v2.1.0 が標準で出力する HTML を想定しています
sub mhonarc_filter ($$) {
    my ($contents, $weighted_str) = @_;

    # MHonArc を使うときはこんな感じに処理すると便利
    $$contents =~ s/<!--X-MsgBody-End-->.*//s;
    $$contents =~ s/<!--X-TopPNI-->.*<!--X-TopPNI-End-->//s;
    $$contents =~ s/<!--X-Subject-Header-Begin-->.*<!--X-Subject-Header-End-->//s;
    $$contents =~ s/<!--X-Head-Body-Sep-Begin-->/\n/;  # ヘッダと本文を区切る
    $$contents =~ s/^<LI>//gim;   # ヘッダの前に空白をあけたくないから
    $$contents =~ s/<\/?EM>//gi;  # ヘッダの名前をインデックスにいれたくない
    $$contents =~ s/^\s+//;
}

# Mail/News 用のフィルタ
# 元となるものは古川@ヤマハさんにいただきました
sub mailnews_filter ($$$\%) {
    my ($contents, $weighted_str, $title, $fields) = @_;
    my ($line, $boundary, $partial, @tmp);

    $$contents =~ s/^\s+//;
    # 1 行目がヘッダっぽくないファイルは、ヘッダ処理しない
    return unless ($$contents =~ /(^\S+:|^from )/i);

    @tmp = split(/\n/, $$contents);
  HEADER_PROCESSING:
    while (@tmp) {
	$line = shift(@tmp);
	last if ($line =~ /^$/);  # if an empty line, header is over
	# connect the two lines if next line has leading spaces
	while (defined($tmp[0]) && $tmp[0] =~ /^\s+/) {
	    # if connection is Japanese character, remove spaces
	    # from Furukawa-san's idea [09/22/1998]
	    my $nextline = shift(@tmp);
	    $line =~ s/([\xa1-\xfe])\s+$/$1/;
	    $nextline =~ s/^\s+([\xa1-\xfe])/$1/;
	    $line .= $nextline;
	}
	# keep field info
	if ($line =~ /^(\S+):\s(.*)/i) {
	    my $name = $1;
	    my $value = $2;
	    $fields->{lc($name)} = $value;
	    if ($name =~ /^($REMAIN_HEADER)$/i) {
		# keep some fields specified REMAIN_HEADER for search keyword
		$$weighted_str .= 
		    "\x7f$REMAIN_HEADER_W\x7f$value\x7f/$REMAIN_HEADER_W\x7f\n";
	    }
 	}
	if ($line =~ s/^subject:\s*//i){
	    $$title = $line;
	    encode_entity($title);
	    # ML 特有の [hogehoge-ML:000] を読み飛ばす。
	    # のが意図だが、面倒なので、
	    # 実装上、最初の [...] を読み飛ばす。
	    $line =~ s/^\[.*?\]\s*//;

	    # 'Re:' を読み飛ばす。
	    $line =~ s/\bre:\s*//gi;

	    $$weighted_str .= "\x7f$TITLEW\x7f$line\x7f/$TITLEW\x7f\n";
	} elsif ($line =~ s/^content-type:\s*//i) {
	    if ($line =~ /multipart.*boundary="(.*)"/i){
		$boundary = $1;
		dprint "((boundary: $boundary))\n";
  	    } elsif ($line =~ m!message/partial;\s*(.*)!i) {
		# The Message/Partial subtype routine [10/12/1998]
		# contributed by Hiroshi Kato <tumibito@mm.rd.nttdata.co.jp>
  		$partial = $1;
  		dprint "((partial: $partial))\n";
	    }
	} 
    }
    if ($partial) {
	# MHonARC makes several empty lines between header and body,
	# so remove them.
	while(@tmp) {
	    last if (! $line =~ /^\s*$/);
	    $line = shift(@tmp);
	}
	undef $partial;
	goto HEADER_PROCESSING;
    }
    $$contents = join("\n", @tmp);
    if ($boundary) {
	# MIME の Multipart  をそれなりに処理する
	$boundary =~ s/(\W)/\\$1/g;
	$$contents =~ s/This is multipart message.\n//i;


	# MIME multipart processing,
	# modified by Furukawa-san's patch on [1998/08/27]
 	$$contents =~ s/--$boundary(--)?\n?/\xff/g;
 	my (@parts) = split(/\xff/, $$contents);
 	$$contents = '';
 	foreach $_ (@parts){
 	    if (s/^(.*?\n\n)//s){
 		my ($head) = $1;
 		$$contents .= $_ if $head =~ /^content-type:.*text\/plain/mi;
 	    }
 	}
    }
}

# Mail/News の引用マークを片付ける
# また冒頭の名乗るだけの行や、引用部分、◯◯さんは書きましたなどの行は
# 要約に含まれないようにする (やまだあきらさんのアイディアを頂きました)
sub mailnews_citation_filter ($$) {
    my ($contents, $weighted_str) = @_;
    my ($line, $omake, $i, @tmp);

    $omake = "";
    $$contents =~ s/^\s+//;
    @tmp = split(/\n/, $$contents);
    $$contents = "";

    # 冒頭の名乗り出る部分を処理 (これは最初の 1,2 行めにしかないでしょう)
    for ($i = 0; $i < 2 && defined($tmp[$i]); $i++) {
	if ($tmp[$i] =~ /(^\s*((([\xa1-\xfe][\xa1-\xfe]){1,8}|([\x21-\x7e]{1,16}))\s*(。|．|\.|，|,|、|\@|＠|の)\s*){0,2}\s*(([\xa1-\xfe][\xa1-\xfe]){1,8}|([\x21-\x7e]{1,16}))\s*(です|と申します|ともうします|といいます)(.{0,2})?\s*$)/) {
	    # デバッグ情報から検索するには perl -n00e 'print if /^<<<</'
	    dprint "\n\n<<<<$tmp[$i]>>>>\n\n";
	    $omake .= $tmp[$i] . "\n";
	    $tmp[$i] = "";
        }
    }

    # 引用部分を隔離
    foreach $line (@tmp) {
	# 行頭に HTML タグが来た場合は引用処理しない
	if ($line !~ /^[^>]*</ &&
	    $line =~ s/^((\S{1,10}>)|(\s*[\>\|\:\#]+\s*))+//) {
	    $omake .= $line . "\n";
	    $$contents .= "\n";  # 改行をいれよう
	    next;
	}
	$$contents .= $line. "\n";
    }

    # ここでは空行を区切りにした「段落」で処理している
    # 「◯◯さんは△△の記事において□□時頃書きました」の類いを隔離
    @tmp = split(/\n\n+/, $$contents);
    $$contents = "";
    $i = 0;
    foreach $line (@tmp) {
	# 完全に除外するのは無理だと思われます。こんなものかなあ
        # この手のメッセージはせいぜい最初の 5 段落くらいに含まれるかな
	# また、 5 行より長い段落は処理しない。
	# それにしてもなんという hairy 正規表現だろう…
	if ($i < 5 && ($line =~ tr/\n/\n/) <= 5 && $line =~ /(^\s*(Date:|Subject:|Message-ID:|From:|件名|差出人|日時))|(^.+(返事です|reply\s*です|曰く|いわく|書きました|言いました|話で|wrote|said|writes|says)(.{0,2})?\s*$)|(^.*In .*(article|message))|(<\S+\@([\w-.]\.)+\w+>)/im) {
	    dprint "\n\n<<<<$line>>>>\n\n";
	    $omake .= $line . "\n";
	    $line = "";
	    next;
	}
	$$contents .= $line. "\n\n";
        $i++;
    }
    $$weighted_str .= "\x7f1\x7f$omake\x7f/1\x7f\n";
}


# RFC 用のフィルタ
# わりと書式はまちまちみたいだからそれなりに
sub rfc_filter ($$$) {
    my ($contents, $weighted_str, $title) = @_;

    $$contents =~ s/^\s+//s;
    $$contents =~ s/((.+\n)+)\s+(.*)//;
    $$title = $3;
    encode_entity($title);
    $$weighted_str .= "\x7f1\x7f$1\x7f/1\x7f\n";
    $$weighted_str .= "\x7f$TITLEW\x7f$$title\x7f/$TITLEW\x7f\n";
    # summary または Introductionがあればそれを先頭に持ってくる
    $$contents =~ s/([\s\S]+^(\d+\.\s*)?(Abstract|Introduction)\n\n)//im;
    $$weighted_str .= "\x7f1\x7f$1\x7f/1\x7f\n";
}

# man 用のフィルタ
# よくわからないからいいかげんに
sub man_filter ($$$) {
    my ($contents, $weighted_str, $title) = @_;
    my ($name);

    $$contents =~ s/^\s+//gs;

    $$contents =~ /^(.*?)\s*\S*$/m;
    $$title = "$1";
    encode_entity($title);
    $$weighted_str .= "\x7f$TITLEW\x7f$$title\x7f/$TITLEW\x7f\n";

    if ($$contents =~ /^(?:NAME|名前|名称)\s*\n(.*?)\n\n/ms) {
	$name = "$1::\n";
	$$weighted_str .= "\x7f$TAGW{'H1'}\x7f$1\x7f/$TAGW{'H1'}\x7f\n";
    }

    if ($$contents =~ 
	s/(.+^(?:DESCRIPTION 解説|DESCRIPTIONS?|SHELL GRAMMAR|INTRODUCTION|【概要】|解説|説明|機能説明|基本機能説明)\s*\n)//ims) 
    {
	$$contents = $name . $$contents;
	$$weighted_str .= "\x7f1\x7f$1\x7f/1\x7f\n";
    }
}

# uuencode の読み飛ばしルーチンは古川@ヤマハさんがくださりました。[09/28/1997]
# 重ね重ね感謝です。後日 BinHex も追加してもらいました [11/13/1997]
# 私がいじったことによるバグを修正してくださいました [02/05/1998] Thanks!
sub uuencode_filter ($) {
    my ($contents) = @_;
    my ($line, @tmp, $uunumb);
    my ($uuord, $uuin);

    @tmp = split(/\n/, $$contents);
    $$contents = "";
    
    while (@tmp) {
	$line = shift(@tmp);
	$line .= "\n";

	# BinHex の読み飛ばし
	# 仕様がよく分からないので、最後まで飛ばす
	last if $line =~ /^\(This file must be converted with BinHex/; #)

	# uuencode の読み飛ばし
	# 参考文献 : SunOS 4.1.4 の man 5 uuencode
	#            FreeBSD 2.2 の uuencode.c
        # 偶然マッチしてしまった場合のデメリットを少なくするため
	# 本体のフォーマットチェックを行なう
	#
	# News などでファイルを分割して投稿されているものの場合 begin がない
	# ことがあるのでそれを考慮します by S.Takabayashi [v1.0.5]
	# 偶然マッチすることはほとんどないとは思いますが…
	#
	# length は 62 と 63 があるみたい… [v1.0.5]
	# もしかしたら他にも違いがあるのかも
	#
	# 仕様を忠実に表現すると、
	# int((ord($line) - ord(' ') + 2) / 3)
	#     != (length($line) - 2) / 4
	# となるが、式を変形して…
	# 4 * int(ord($line) / 3) != length($line) + $uunumb;

        # SunOS の uuencode は、encode に空白も使っている。
        # しかし、空白も認めると、一般の行を uuencode 行と誤認する
        # 可能性が高くなる。
        # 折衷案として、次のケースで認める。
        #     begin と end の間
        #     前の行が uuencode 行と判断されて、ord が前の行と同じ
	
	# 一行が 0x20-0x60 の文字のみで構成される場合のみ uuencode 
	# とみなす v1.1.2.3 (bug fix)

        $uuin = 1, next if $line =~ /^begin [0-7]{3,4} \S+$/;
        if ($line =~ /^end$/){
            $uuin = 0,next if $uuin;
        }else{
            # ここで、ord の値は 32-95 の範囲に
            $uuord = 32 if ($uuord = ord($line)) == 96;

            # uunumb = 38 の行が loop の外に出ていると、
            # 一般の行で 63 文字の行があったら誤動作してしまう
            $uunumb = (length($line)==63)? 37: 38;

            if ((32 <= $uuord && $uuord < 96) &&
                length($line) <= 63 &&
                (4 * int($uuord / 3) == length($line) + $uunumb)){

                if ($uuin == 1 || $uuin == $uuord){
                    next if $line =~ /^[\x20-\x60]+$/;
                } else {
		    # beginから始まっていないものは厳しくしよう [05/22/1998]
                    $uuin = $uuord, next if $line =~ /^M[\x21-\x60]+$/;
                }
            }
        }
        $uuin = 0;
        $$contents .= $line;
    }
}

# 行頭・行末の空白、タブ、行頭の > | # を削除 (':' もつけ加えた by 高林)
# 行末が日本語で終わる場合は改行コードを削除
# この部分のコードは古川@ヤマハさんがくださりました。[09/15/1997]
# 英文ハイフォネーションの解除は私が付け足しました
# 40文字未満の行について行末の日本語連結処理を行わないようにした v1.1.1
sub line_adjust_filter ($) {
    my ($text) = @_;
    my ($line, @tmp);
    return if (!defined($$text));

    @tmp = split(/\n/, $$text);
    foreach $line (@tmp) {
	$line .= "\n";
	$line =~ s/^[ \>\|\#\:]+//;
	$line =~ s/ +$//;
	$line =~ s/\n// if (($line =~ /[\xa1-\xfe]\n*$/) &&
			    (length($line) >=40));
	$line =~ s/(。|、)$/$1\n/;
	$line =~ s/([a-z])-\n/$1/;  # for hyphenation.
    }
    $$text = join('', @tmp);
}


# 準備
sub preparation_process ($$$) {
    my ($output_dir, $target_dir, $file_segment);
    $file_segment = 0;

    ($output_dir, $target_dir) = get_commandline_opt();
    dbnamechange($output_dir);
    check_present_index();

    ParseRobotsTxt() if ($RobotExcludeOpt);

    my $current_dir = cwd();
    chdir $target_dir || die "$target_dir: $!\n";
    $TARGET_DIR = cwd();
    $TARGET_DIR =~ s/\//\\/g 
	if ($SYSTEM eq "MSWin32") || ($SYSTEM eq "os2");
    # $URL_PREFIX が \t なら $target_dir の cwd を元にセット v1.1.1
    $URL_PREFIX = cwd() . "$PSC" if $URL_PREFIX eq "\t";
    find::findfiles($PSC) unless @FList;
    grep s/(\/|\\)+/\\/g, @FList 
	if ($SYSTEM eq "MSWin32") || ($SYSTEM eq "os2");
    chdir $current_dir;

    $file_segment = do_append_preprocessing() if -e $REGLIST;
    unless (@FList) { # if @FList is empty
	print "No files to index.\n";
	remove_backup_files();
	exit;
    }

    if ($SYSTEM eq "MSWin32") {
	# 例によって Win32 のパイプは変なので別処理になる
	open(FLIST, ">$FLIST_") || die "Can't open $FLIST_.\n";
    } else {
	if ($LANGUAGE eq "ja") {
	    open(FLIST, "|$NKF -jZ >$FLIST_") || die "$FLIST_: $!\n";
	} else {
	    open(FLIST, ">$FLIST_") || die "$FLIST_: $!\n";
	}
    } 
    binmode(FLIST);
    open(ERRORSFILE, ">>$ERRORSFILE") || die "$ERRORSFILE: $!\n";
    binmode(ERRORSFILE);
    return $file_segment;
}

sub set_lockfile ($) {
    my ($file) = @_;

    # make a lock file
    if (-f $file) {
	print "$file found. Maybe this index is being updated by another process now.\nIf not, you can remove this file.\n";
	exit 1;
    } else {
	open(LOCKFILE, ">$file");
	print LOCKFILE "$$"; # save pid
	close(LOCKFILE);
    }
}

sub remove_lockfile ($) {
    my ($file) = @_;

    # lock ファイルを削除する
    unlink $file;
}

# 既存のインデックスの byte order を確認する
sub check_present_index () {
    if (((is_big_endian()) && -f $LITTLEENDIAN)
	|| ((!is_big_endian()) && -f $BIGENDIAN)) {
	die "!!CAUTION!!\nPresent index was made with opposite byte order.\nYou should run 'rvnmz' to change it.\n";
    }
}

# 後処理
sub remain_process ($$$$) {
    my ($all_file_size, $file_count, $key_count, $start_time) = @_;
    my ($tmp, @tmp);

    close(FLIST);
    close(ERRORSFILE);

    @tmp = grep(!/^$/, @FList);
    if (@tmp) {
	if ($SYSTEM eq "MSWin32" && $LANGUAGE eq "ja") {
	    # MSWin32 だと書き直してあげないといけない。
	    open(FLIST, "$NKF -jZ $FLIST_|") || die "$FLIST_: $!\n";
	    open(FLISTTMP, ">$FLIST_.tmp") || die "$FLIST_.tmp: $!\n";
	    binmode(FLISTTMP);
	    print FLISTTMP while <FLIST>;
	    close(FLISTTMP);
	    close(FLIST);
	    Rename("$FLIST_.tmp", $FLIST_);
	}

	append_flist() if $APPENDMODE;
	make_flist_index();
	put_lock_msg();
	put_body_msg();
	set_lockfile($LOCKFILE);
	update_field_info();
	put_registration_file();
	update_dateindex();
	put_nmz_files();
	put_endian_stamp();
	remove_lockfile($LOCKFILE);
	make_slog_file();
    } else {
	if ($DeletedFilesCount > 0) {
	    update_dateindex();
	    update_registration_file();
	}
	# No files are indexed
	remove_backup_files();
    }
    make_headfoot_pages($file_count, $key_count);
    put_log($all_file_size, $start_time, $file_count, $key_count);
    remove_lockfile($LOCKFILE2);
}

sub make_headfoot_pages($$) {
    my ($file_count, $key_count) = @_;

    make_headfoot("$HEADERFILE.ja", $file_count, $key_count);
    make_headfoot("$FOOTERFILE.ja", $file_count, $key_count);
    make_headfoot("$HEADERFILE.en", $file_count, $key_count);
    make_headfoot("$FOOTERFILE.en", $file_count, $key_count);
}

sub remove_backup_files() {
    $FLIST_ =~ m!^(.*\Q$PSC\E)!;
    unlink glob "${1}NMZ.*$$*";
}

# コマンドラインの引数の処理
sub get_commandline_opt ()
{
    my ($target_dir, $target_loaded, $output_dir);
    $output_dir = "";

    usage() if (@ARGV == 0);
    while (defined($ARGV[0]) && $ARGV[0] =~ /^-/) {
	$TARGET_FILE = ".*" if $ARGV[0] =~ /a/;
	$WAKATI = $KAKASI, $MorphOpt = 0 if $ARGV[0] =~ /k/;
	$WAKATI = $CHASEN, $MorphOpt = 0 if $ARGV[0] =~ /c/;
	$WAKATI = $CHASEN_MORPH, $MorphOpt = 1 if $ARGV[0] =~ /m/;
	$UuencodeOpt = 1 if $ARGV[0] =~ /u/;
	$MailNewsOpt = 1 if $ARGV[0] =~ /h/;
	if ($ARGV[0] =~ /r/) {
	    $ManOpt      = 1;
	    $TARGET_FILE = '.*\.\d.*';
	}
	$HiraganaOpt = 1 if $ARGV[0] =~ /H/;
	$OkuriganaOpt = 1 if $ARGV[0] =~ /G/;
	$NoEdgeSymbolOpt = 1 if $ARGV[0] =~ /E/;
	$NoSymbolOpt = 1 if $ARGV[0] =~ /K/;
	$NoLineAdOpt = 1 if $ARGV[0] =~ /L/;
	$NoMHonArcOpt  = 1 if $ARGV[0] =~ /M/;
	$NoEncodeURL  = 1 if $ARGV[0] =~ /U/;
	$DebugOpt    = 1 if $ARGV[0] =~ /d/;
	$NoHeadAbstOpt  = 1 if $ARGV[0] =~ /x/;
	$RobotExcludeOpt = 1 if $ARGV[0] =~ /e/;
	$QuietOpt = 1 if $ARGV[0] =~ /q/;
	$NoPhraseIndexOpt  = 1 if $ARGV[0] =~ /P/;
	$NoRegexpIndexOpt  = 1 if $ARGV[0] =~ /R/;
	$NoInsertHeaderOpt  = 1 if $ARGV[0] =~ /D/;
	$NoDateIndexOpt = 1 if $ARGV[0] =~ /W/;
	$NoFieldInfoOpt = 1 if $ARGV[0] =~ /X/;
	$NoDeleteProcessing = 1 if $ARGV[0] =~ /Y/;
	$NoUpdateProcessing = 1 if $ARGV[0] =~ /Z/;
	$HtaccessExcludeOpt = 1 if $ARGV[0] =~ /A/;
 	if ($ARGV[0] =~ /O$/) {
 	    shift @ARGV;
	    $output_dir = $ARGV[0];
	    $output_dir =~ s|\Q$PSC\E*$||;
 	    print "Index output directory: $ARGV[0]\n" unless $QuietOpt;
 	} elsif ($ARGV[0] =~ /T$/) {
 	    shift @ARGV;
	    $LIBDIR = $ARGV[0];
	    $LIBDIR =~ s|\Q$PSC\E*$||;
 	} elsif ($ARGV[0] =~ /I$/) {
	    shift @ARGV;
	    include($ARGV[0]);
	    print "Included: $ARGV[0]\n" unless $QuietOpt;
	} elsif ($ARGV[0] =~ /l$/) { # small letter of 'L'
	    shift @ARGV;
	    $LANGUAGE = $ARGV[0];
	} elsif ($ARGV[0] =~ /F$/) {
	    shift @ARGV;
	    load_target_list($ARGV[0]);
	    print "Loaded: $ARGV[0]\n" unless $QuietOpt;
	    $target_loaded = 1;
	    $target_dir = cwd();
	} elsif ($ARGV[0] =~ /t$/) {
	    shift @ARGV;
	    print "TARGET: $ARGV[0]\n" unless $QuietOpt;
	    $TARGET_FILE = $ARGV[0];
	}
	shift @ARGV;
    }

    usage() if (@ARGV == 0 && !$target_loaded && $output_dir eq "");

    unless( !$target_loaded || @FList) { # if @FList is empty
	print "No files to index.\n";
	exit;
    }

    if ($#ARGV > 0 || $#ARGV == 0 && $target_loaded) {
	$URL_PREFIX = $ARGV[0];
	shift @ARGV;
    }
    
    $target_dir = $ARGV[0] if defined $ARGV[0];
    $output_dir = cwd() if $output_dir eq "";
    die "$output_dir: invalid output directory\n"
	unless (-d $output_dir && -w $output_dir);
    if ($SYSTEM eq "MSWin32" || $SYSTEM eq "os2") {
        $target_dir =~ s/\//\\/g;
        $output_dir =~ s/\//\\/g;
 	$target_dir =~ s|\Q$PSC\E*$||;
 	$output_dir =~ s|\Q$PSC\E*$||;
    }
    ($output_dir, $target_dir);
}

sub include($) {
    my ($filename) = @_;

    open(INCLUDE, $filename) or die "$filename: $!";
    my $code = join('',<INCLUDE>);
    close(INCLUDE);
    eval $code;
}

sub load_target_list ($) {
    my ($file) = @_;
    my $cwd = cwd();

    open(TLIST, "$file") || die "$file: $!\n";
    @FList = <TLIST>;
    close(TLIST);
    # convert a relative path into an absolute path
    grep(s/^\.\Q$PSC\E/$cwd$PSC/, @FList); 
    if (($SYSTEM eq "MSWin32") || ($SYSTEM eq "os2")) {
        grep(s/^([A-Z](?!\Q:$PSC\E))/$cwd$PSC$1/i, @FList); 
    } else {
        grep(s/^([^\Q$PSC\E])/$cwd$PSC$1/, @FList); 
    }
    grep(chop, @FList); 

    # traverse directories
    # this routine is not efficent but I prefer reliable logic.
    my @tmp = @FList;
    my @tmp2 = ();
    @FList = ();
    while (@tmp) {
	$_ = shift (@tmp);
	if (s!\Q$PSC\E$!! && -d $_) { # path ending with $PSC
	    my $cwd = cwd();
	    chdir $_;
	    find::findfiles($PSC);
	    push(@tmp2, @FList);
	    @FList = ();
	    chdir $cwd;
	} else {
	    push(@tmp2, $_);
	}
    }
    my %tmp3 = ();
    map {$tmp3{$_} = 1} @tmp2;
    @tmp2 = keys %tmp3;
    @FList = @tmp2;
}

sub usage () {
    if ($LANGUAGE eq "ja") {
	if ($CCS eq "euc") {
	    print STDERR $USAGE_JA;
	} elsif ($CCS eq "sjis") {
	    open(NKF, "|$NKF -s");
	    print NKF $USAGE_JA;
	    close(NKF);
	}
    } else {
	print STDERR $USAGE_EN;
    }
    exit;
}

# make a URL from a file name
sub url_decchiagator ($) {
    my ($tmp) = @_;
    return undef unless defined $tmp;

    my $url = $tmp;
    # remove a file name if omittable
    $url =~ s!(.*)\Q$PSC\E($DEFAULT_FILE)(\?.*)?$!$1/$3!; 
    $url =~ s/\Q$TARGET_DIR$PSC\E/$URL_PREFIX/;
    if (($SYSTEM eq "MSWin32") || ($SYSTEM eq "os2")) {
	# Shift_JIS の漢字を考慮して \ を / に変換 [09/26/1998]
	$url =~ s!([\x81-\x9f\xe0-\xef][\x40-\x7e\x80-\xfc]|[\x01-\x7f])!
	    $1 eq "\\" ? "/" : $1!gex;
	$url =~ s#^([A-Z]):#/$1|#i; # ドライヴ部分を /C| のように置き換え
    }

    unless ($NoEncodeURL) {
	# Escape unsafe characters (not strict)
	$url =~ s/\%/%25/g;  # Convert original '%' into '%25' v1.1.1.2
	$url =~ s/([^a-zA-Z0-9~\-\_\.\/\:\%])/
	    sprintf("%%%02X",ord($1))/ge;
	if (($SYSTEM eq "MSWin32") || ($SYSTEM eq "os2")) {
	    # restore '|' for drive letter rule of Win32, OS/2
	    $url =~ s!^/([A-Z])%7C!/$1|!i;
	}
    }
    $url;
}

# check the file -- 0: OK / 1: NG
sub check_file ($$$$) {
    my ($cfile, $contents, $ctrl, $size) = @_;

    # コントロール文字が全体の 3 % よりも多ければバイナリファイル
    # とみなし、スキップする (-B は問題があるので使わない)
    if ($size == 0) {
	"is 0 size! skipped.";
    } elsif (int ($ctrl / $size * 100) > 3) {
	"may be a BINARY file! skipped."
    } elsif ($size > $FILE_SIZE_LIMIT) {
	"is too LARGE file! skipped.";
    } elsif (!$NoMHonArcOpt && $cfile !~ /($MHONARC_MESSAGE_FILE)$/ 
	     && $$contents =~ /^$MHONARC_HEADER/) {
	"is MHonArc's index file! skipped.";
    } else {
	"";
    }
}


# update REGLIST = NMZ.r file
sub put_registration_file () {
    update_registration_file() if -e $REGLIST_;  # preupdated file exists
    return if @FList == 0;
    open(REGLIST, ">>$REGLIST") || die "$REGLIST: $!\n";
    binmode(REGLIST);
    @FList = grep($_ ne '', @FList);
    print REGLIST join("\n", @FList), "\n";
    print REGLIST "## indexed: " . rfc822time(time()) . "\n\n";
    close(REGLIST);
}

# Rename *.$$ to each real file name
sub put_nmz_files () {
    Rename($FLIST_,      $FLIST);
    Rename($FLISTINDEX_, $FLISTINDEX);
    Rename($INDEX_,      $INDEX);
    Rename($INDEXINDEX_, $INDEXINDEX);
    Rename($HASH_,       $HASH);
    Rename($WORDLIST_, $WORDLIST);
    Rename($PHRASE_, $PHRASE);
    Rename($PHRASEINDEX_, $PHRASEINDEX);
}

# Set a file to indentify byte order
sub put_endian_stamp () {
    if (is_big_endian()) {
	open(TMP, ">>$BIGENDIAN");
    } else {
	open(TMP, ">>$LITTLEENDIAN");
    }
    close(TMP);
}

# output NMZ.msg
sub put_lock_msg () {
    write_message_to_file("$LOCKMSGFILE.ja", $LOCK_MSG_JA);
    write_message_to_file("$LOCKMSGFILE.en", $LOCK_MSG_EN);
}

# output NMZ.body
sub put_body_msg () {
    write_message_to_file("$BODYMSGFILE.ja", $BODY_MSG_JA);
    write_message_to_file("$BODYMSGFILE.en", $BODY_MSG_EN);
}

# output NMZ.body and etc.
sub write_message_to_file ($$) {
    my ($full_path_name, $msg) = @_;

    if (! -e $full_path_name) {
	my ($template, $fname);
	
	$full_path_name =~ /.*\Q$PSC\E(.*)$/;
	$fname = $1;
	if ( -e "$LIBDIR$PSC$fname") {
	    $template = "$LIBDIR$PSC$fname";
	} else {
	    $template = "$LIBDIR2$PSC$fname";
	}
	if (-e $template) {
	    my ($buf);
	    open(TEMPLATE, $template) || die "$template: $!\n";
	    if ($LANGUAGE eq "ja") {
		open(OUTPUT ,"|$NKF -j >$full_path_name") 
		    || die "$full_path_name: $!\n";
	    } else {
		open(OUTPUT ,">$full_path_name") 
		    || die "$full_path_name: $!\n";
	    }
	    $buf = join('', <TEMPLATE>);
	    $buf =~ s/"/\\"/g;
	    $buf =~ s/\@/\\@/g;
	    $buf = eval("\"$buf\"");  # eval to interpolate variables in $buf

	    print OUTPUT $buf;

	    close(TEMPLATE);
	    close(OUTPUT);
	}
    }
}


# Make a file for logging
sub make_slog_file () {
    open(SLOGFILE, ">>$SLOGFILE");
    close(SLOGFILE);
    chmod 0666, $SLOGFILE;
}


# Check the size of int
sub get_int_size () {
    my ($tmp);
    $tmp = 0;
    $tmp = pack("i", $tmp);
    $INTSIZE = length($tmp);
}


# 作成する各ファイルの頭に $CURRENTDIR をくっつける
sub dbnamechange ($) {
    my ($current_dir) = @_;
    $FLIST      = "$current_dir$PSC$FLIST";
    $FLISTINDEX = "$current_dir$PSC$FLISTINDEX";
    $INDEX      = "$current_dir$PSC$INDEX";
    $INDEXINDEX = "$current_dir$PSC$INDEXINDEX";
    $HASH       = "$current_dir$PSC$HASH";
    $REGLIST    = "$current_dir$PSC$REGLIST";
    $HEADERFILE = "$current_dir$PSC$HEADERFILE";
    $FOOTERFILE = "$current_dir$PSC$FOOTERFILE";
    $LOGFILE    = "$current_dir$PSC$LOGFILE";
    $SLOGFILE   = "$current_dir$PSC$SLOGFILE";
    $LOCKFILE   = "$current_dir$PSC$LOCKFILE";
    $LOCKFILE2  = "$current_dir$PSC$LOCKFILE2";
    $LOCKMSGFILE = "$current_dir$PSC$LOCKMSGFILE";
    $BODYMSGFILE = "$current_dir$PSC$BODYMSGFILE";
    $ERRORSFILE = "$current_dir$PSC$ERRORSFILE";
    $BIGENDIAN = "$current_dir$PSC$BIGENDIAN";
    $LITTLEENDIAN = "$current_dir$PSC$LITTLEENDIAN";

    $PHRASE = "$current_dir$PSC$PHRASE";
    $PHRASEINDEX = "$current_dir$PSC$PHRASEINDEX";
    $FIELDINFO = "$current_dir$PSC$FIELDINFO";
    $DATEINDEX = "$current_dir$PSC$DATEINDEX";
    $TOTALFILESCOUNT = "$current_dir$PSC$TOTALFILESCOUNT";

    $WORDLIST = "$current_dir$PSC$WORDLIST";
    $WAKATITMP = "$current_dir$PSC$WAKATITMP";
    $TMP_I      = "$current_dir$PSC$TMP_I";
    $TMP_W      = "$current_dir$PSC$TMP_W";
    $TMP_P      = "$current_dir$PSC$TMP_P";
    $TMP_PI     = "$current_dir$PSC$TMP_PI";

    $FLIST_      = "$FLIST.$$";
    $FLISTINDEX_ = "$FLISTINDEX.$$";
    $INDEX_      = "$INDEX.$$";
    $INDEXINDEX_ = "$INDEXINDEX.$$";
    $HASH_       = "$HASH.$$";
    $HEADERFILE_ = "$HEADERFILE.$$";
    $FOOTERFILE_ = "$FOOTERFILE.$$";
    $WORDLIST_   = "$WORDLIST.$$";
    $PHRASE_     = "$PHRASE.$$";
    $PHRASEINDEX_= "$PHRASEINDEX.$$";
    $DATEINDEX_  = "$DATEINDEX.$$";
    $REGLIST_    = "$REGLIST.$$";
}


# FLIST の追加を行う
sub append_flist () {
    open(FLIST, "$FLIST_") || die "$FLIST: $!\n";
    binmode(FLIST);
    open(FLISTBASE, ">> $FLIST_.base") || die "$FLIST_.base: $!\n";
    binmode(FLISTBASE);
    print FLISTBASE while <FLIST>;
    close(FLIST);
    close(FLISTBASE);
    Rename("$FLIST_.base", "$FLIST_");
}


# find 用のルーチン
sub wanted ($){
    my ($name) = @_;
    push(@FList, $name) if 
	( (! /^(($DENY_FILE)(\.gz|\.Z)?)$/i) &&
	 /^(($TARGET_FILE)(\.gz|\.Z|\?.*)?)$/i && -f $_ && -r $_);
}

# インデックスの追加の準備を行う
sub do_append_preprocessing () {
    my ($file_segment);

    $file_segment = set_target_files();
    unless (@FList) { 	# if @FList is empty
	if ($DeletedFilesCount > 0) {
	    make_headfoot_pages(0, 0);
	    set_lockfile($LOCKFILE2);
	    update_dateindex();
	    update_registration_file();
	    put_log2();
	    remove_lockfile($LOCKFILE2);
	}
	    
	print "No files to index.\n";
	exit;
    }

    $APPENDMODE = 1;
    # ファイルをコピーして保護する
    cp($FLIST,     "$FLIST_.base");
    cp($INDEX,      $INDEX_);
    cp($DATEINDEX,  $DATEINDEX_) unless -e $DATEINDEX_; # preupdated ?

    unless ($NoPhraseIndexOpt) {
	cp($PHRASE,      $PHRASE_);
	cp($PHRASEINDEX,      $PHRASEINDEX_);
    }

    return $file_segment;
}

# set target files to @Flist and return with the regiested files number
sub set_target_files() {
    my %rfiles;    # 'rfiles' means 'registered files'
    my @found_files = @FList;

    # load the list of registered files
    $rfiles{name} = [ load_registered_files_list() ];

    # pick up overlap files and do marking
    my %mark1;
    my @overlaped_files;
    grep($_ !~ /^\# / && $mark1{$_}++, @{$rfiles{name}});
    $rfiles{overlaped} = {}; # prepare an anonymous hash
    foreach (grep ($mark1{$_}, @found_files)) {
	$rfiles{overlaped}{$_} = 1;
	push(@overlaped_files, $_);
    };
    # pick up not overlaped files which are files to index
    @FList = grep(! $mark1{$_}, @found_files);
	 
    if ($NoUpdateProcessing) {
	return scalar @{$rfiles{name}};   # for segment of $file_count
    };

    # load the date index
    $rfiles{mtime} = [ load_dateindex() ];

    if (@{$rfiles{mtime}} == 0) {
	return scalar @{$rfiles{name}};   # for segment of $file_count
    };

    if ($#{$rfiles{name}} != $#{$rfiles{mtime}}) {
	dprint "\n\n== registered ==\n", join("\n", @{$rfiles{name}});
	dprint "\n\n== mtimes ==\n", join("\n", @{$rfiles{mtime}});
	die "NMZ.r ($#{$rfiles{name}}) and NMZ.t ($#{$rfiles{mtime}})"
	    . "are not consistent!\n";
    }

    # pick up deleted files and do marking
    # (registered in the NMZ.r but not existent in the filesystem)
    my @deleted_files;
    unless ($NoDeleteProcessing) {
	my %mark2;
	grep($mark2{$_}++, @found_files);
	foreach (grep($_ !~ /^\# / && ! $mark2{$_} && ! $rfiles{overlaped}{$_}
		      , @{$rfiles{name}})) 
	{
	    $rfiles{deleted}{$_} = 1;
	    push(@deleted_files, $_);
	};
    }

    # pick up updated files and set the missing number for deleted files
    my @updated_files = pickup_updated_files(\%rfiles);

    # append updated files to list of files to index
    if (@updated_files) {
	push(@FList, @updated_files);
    }

    dprint "\n\n== found ==\n", join("\n", @found_files), "\n";
    dprint "\n\n== registered ==\n", join("\n", @{$rfiles{name}}), "\n";
    dprint "\n\n== overlaped  ==\n", join("\n", @overlaped_files), "\n";
    dprint "\n\n== deleted  ==\n", join("\n", @deleted_files), "\n";
    dprint "\n\n== updated ==\n", join("\n", @updated_files), "\n";
    dprint "\n\n== files to index ==\n", join("\n", @FList), "\n";

    # update NMZ.t with the missing number infomation and
    # append updated files and deleted files to NMZ.r with leading '# '
    if (@updated_files || @deleted_files) {
	$DeletedFilesCount = 0;
	$UpdatedFilesCount = 0;
	$UpdatedFilesCount += @updated_files;
#	$DeletedFilesCount += @updated_files;
	$DeletedFilesCount += @deleted_files;
	preupdate_dateindex(@{$rfiles{mtime}});
	preupdate_registration_file(@updated_files, @deleted_files);
    }

    # return with number of registered files
    return scalar @{$rfiles{name}};   # for segment of $file_count
}

sub preupdate_registration_file(@) {
    my (@list) = @_;

    open(REGLIST, ">$REGLIST_") || die "$REGLIST_: $!\n";
    binmode(REGLIST);
    @list = grep(s/(.*)/\# $1\n/, @list);
    print REGLIST @list;
    print REGLIST "## deleted: " . rfc822time(time()) . "\n\n";
    close(REGLIST);
}

sub preupdate_dateindex(@) {
    my @mtimes = @_;

    # Since rewriting the entire file, it is not efficient, 
    # but simple and reliable. this would be revised in the future.
    open(DATEINDEX, ">$DATEINDEX_") || die "$DATEINDEX_: $!\n";
    binmode(DATEINDEX);
#    print "\nupdate_dateindex\n", join("\n", @mtimes), "\n\n";
    print DATEINDEX pack("i*", @mtimes);
    close(DATEINDEX);
}

sub update_registration_file() {
    open(REGLIST, ">>$REGLIST") || die "$REGLIST: $!\n";;
    binmode(REGLIST);
    open(REGLIST_, $REGLIST_) || die "$REGLIST_: $!\n";;
    binmode(REGLIST);
    while (<REGLIST_>) {
	print REGLIST $_;
    }
    close(REGLIST);
    close(REGLIST_);
    unlink $REGLIST_;
}

sub update_dateindex() {
    Rename($DATEINDEX_, $DATEINDEX);
}

sub update_field_info() {
    my $key;
    for $key (keys %PreupdatedFields) {
	my $fname_tmp = "$FIELDINFO.$key.$$";
	my $fname_out = "$FIELDINFO.$key";

	open(FIELD, ">>$fname_out") || die "$fname_out: $!\n";;
	binmode(FIELD);
	open(TMP, $fname_tmp) || die "$fname_tmp: $!\n";;
	binmode(TMP);
	while (<TMP>) {
	    print FIELD $_;
	}
	close(FIELD);
	close(TMP);
	unlink $fname_tmp;
    }
}



sub pickup_updated_files (\%) {
    my ($ref) = @_;
    my @updated_files;
    my $cfile;

    my $i = 0;
    foreach $cfile (@{$ref->{name}}) {
	if (defined($ref->{deleted}{$cfile})) {
	    print "$cfile was deleted!\n" unless $QuietOpt;
	    $ref->{mtime}[$i] = -1; # assign the a messing number
	} elsif (defined($ref->{overlaped}{$cfile})) {
	    my $cfile_mtime = (stat($cfile))[9];
	    my $rfile_mtime = $ref->{mtime}[$i];

	    if ($rfile_mtime < $cfile_mtime) {
		# this file is updated!
		print "$cfile was updated!\n" unless $QuietOpt;
		$ref->{mtime}[$i] = -1; # assign the messing number
		push(@updated_files, $cfile);
	    }
	}
	$i++;
    }
    @updated_files
}

sub load_dateindex() {
    my @list;

    open(DATEINDEX, "$DATEINDEX") || return ();
    binmode(DATEINDEX);
    my $size = (stat($DATEINDEX))[7];
    my $buf;
    read(DATEINDEX, $buf, $size);
    @list = unpack("i*", $buf);  # load date index
#    print "\nload_dateindex\n", join("\n", @list), "\n\n";
    close(DATEINDEX);
    @list;
}

sub load_registered_files_list() {
    my (@list);

    open(REGLIST, "$REGLIST")
	|| die "$REGLIST: $!\n";
    binmode(REGLIST);
    my $i = 0;
    my %mark;
    while (<REGLIST>) {
	my $line = $_;
	chomp($line);
	next if /^\s*$/; # an empty line
	next if /^##/; # a comment
	if (/^\#\s+(.*)/) {  # deleted document
	    my $tmp = $1;
	    # remove previous registration
	    if (defined($mark{$tmp})) {
		splice(@list, $mark{$tmp}, 1, "# $tmp");
		undef $mark{$tmp};
	    } else {
		die "ERROR: malformed NMZ.r format!\n";
	    }
	} else {
	    unless (defined($mark{$line})) {
		push(@list, $line);
		$mark{$line} = $i;
		$i++;
	    } 
	}
    }
    close(REGLIST);
    return @list;
}

sub get_total() {
    open(TOTALFILESCOUNT, "$TOTALFILESCOUNT") || return 0;
    binmode(TOTALFILESCOUNT);
    my $total = "";
    $total = <TOTALFILESCOUNT>;
    close(TOTALFILESCOUNT);
    chomp($total);
    if ($total eq "") {
	return 0;
    } else {
	return $total;
    }
}

# do logging
sub put_log ($$$$) {
    my ($all_file_size, $start_time, $file_count, $key_count) = @_;
    my ($date, $tmp, $logmsg, $processtime);

    $date = localtime;

    $all_file_size = commas($all_file_size);
    $key_count = commas($key_count - $LastKeyN);
    $processtime = time - $start_time;
    my $added_files_count = commas($file_count - $UpdatedFilesCount);
    my $deleted_files_count = commas($DeletedFilesCount);
    my $updated_files_count = commas($UpdatedFilesCount);
    my $total_files_count = commas(get_total() + $file_count 
				   - $DeletedFilesCount - $UpdatedFilesCount);

    $logmsg = "[Base]";
    $logmsg = "[Append]" if $APPENDMODE;

    $logmsg = 
	"\n$logmsg\n" .
	"Date: $date\n" .
	"Added   Files: $added_files_count files\n" .
	"Deleted Files: $deleted_files_count files\n" .
	"Updated Files: $updated_files_count files\n" .
	"Total   Files: $total_files_count files\n" .
        "Size: $all_file_size bytes\n" .
        "Keywords: $key_count words\n" .
        "Wakati: $WAKATI\n" .
        "Perl Version: $]\n" .   # '$]' has a perl version
	"Namazu Version: $VERSION\n" . 
	"System: $SYSTEM\n" . 
	"Time: $processtime sec.\n";
    $logmsg .= "(using unsignedcmp routine)\n" if $UnsignedCmp;

    print $logmsg unless $QuietOpt;

    open(LOGFILE, ">>$LOGFILE") || die "$LOGFILE: $!\n";
    binmode(LOGFILE);
    print LOGFILE $logmsg;
    close(LOGFILE);

    put_totalfilescount($total_files_count);
}

sub put_totalfilescount($) {
    my ($total_files_count) = @_;
    $total_files_count =~ s/,//g;
    open(TOTALFILESCOUNT, ">$TOTALFILESCOUNT") 
	|| die "$TOTALFILESCOUNT: $!\n";
    binmode(TOTALFILESCOUNT);
    print TOTALFILESCOUNT $total_files_count;
    close(TOTALFILESCOUNT);
}

# do logging (short format only contains deleted files info)
sub put_log2 () {
    my $date = localtime;
    my $deleted_files_count = commas($DeletedFilesCount);
    my $total_files_count = commas(get_total()
	- $DeletedFilesCount - $UpdatedFilesCount);

    my $logmsg = "[Append]";

    $logmsg = 
	"\n$logmsg\n" .
	"Date: $date\n" .
	"Deleted Files: $deleted_files_count files\n" .
	"Total   Files: $total_files_count files\n" .
        "Perl Version: $]\n" .   # '$]' has a perl version
	"Namazu Version: $VERSION\n" . 
        "System: $SYSTEM\n";

    print $logmsg unless $QuietOpt;

    open(LOGFILE, ">>$LOGFILE") || die "$LOGFILE: $!\n";
    binmode(LOGFILE);
    print LOGFILE $logmsg;
    close(LOGFILE);

    put_totalfilescount($total_files_count);
}

sub get_year() {
    my ($year);

    $year = (localtime)[5] + 1900;
    $year;
}

# ヘッダとフッタの処理。ファイルがなければサンプルを作成する。
# また $file_count, $key_count, $month/$day/$year を埋め込む
sub make_headfoot ($$$) {
    my ($file, $file_count, $key_count) = @_;
    my ($day, $month, $year, $tmp, $buf);

    $day   = sprintf("%02d", (localtime)[3]);
    $month = sprintf("%02d", (localtime)[4] + 1);
    $year = get_year();

    if (-e $file) {
	# ファイルは EUC で読み込みます
	if ($LANGUAGE eq "ja") {
	    open(FILE ,"$NKF -e $file|") || die "$file: $!\n";
	} else {
	    open(FILE ,"$file") || die "$file: $!\n";
	}
	binmode(FILE);
	$buf = join("", <FILE>);
	close(FILE);
    } else {
	my ($template, $fname);
	$file =~ /.*\Q$PSC\E(.*)$/;
	$fname = $1;
	if ( -e "$LIBDIR/$fname") {
	    $template = "$LIBDIR$PSC$fname";
	} else {
	    $template = "$LIBDIR2$PSC$fname";
	}
	if (-e $template) {
	    open(FILE ,"$template") || die "$template: $!\n";
	    binmode(FILE);
	    $buf = join("", <FILE>);
	    close(FILE);
	} else {
	    return;
	}
	$buf =~ s/"/\\"/g;
	$buf =~ s/\@/\\@/g;
	$buf = eval("\"$buf\"");
    }

    # the file must be saved in ISO-2022-JP encoding.
    if ($LANGUAGE eq "ja") {
	open(FILE ,"|$NKF -j >$file") || die "$file: $!\n";
    } else {
	open(FILE ,">$file") || die "$file: $!\n";
    }
    binmode(FILE);

    if ($buf =~ /(<!-- FILE -->)\s*(.*)\s*(<!-- FILE -->)/) {
	my $total_files_count = commas(get_total() + $file_count 
				   - $DeletedFilesCount - $UpdatedFilesCount);
	$buf =~ s/(<!-- FILE -->)(.*)(<!-- FILE -->)/$1 $total_files_count $3/;
    }
    if ($buf =~ /(<!-- KEY -->)\s*(.*)\s*(<!-- KEY -->)/) {
	$tmp = $2;
	$tmp =~ tr/,//d;
	$tmp = $key_count if $key_count;
	$tmp = commas($tmp);
	$buf =~ s/(<!-- KEY -->)(.*)(<!-- KEY -->)/$1 $tmp $3/;
    }
    $buf =~ s/(<!-- DATE -->)(.*)(<!-- DATE -->)/$1 $month\/$day\/$year $3/g;
    $buf =~ s/(<!-- VERSION -->)(.*)(<!-- VERSION -->)/$1 v$VERSION $3/g;

    print FILE $buf;
    close(FILE);
}


# ラクダ本から借用したカンマ挿入ルーチン
sub commas ($) {
    my ($num) = @_;

    $num = "0" if ($num eq "");
#    1 while $num =~ s/(.*\d)(\d\d\d)/$1,$2/;
    # from Mastering Regular Expressions
    $num =~ s<\G((?:^-)?\d{1,3})(?=(?:\d\d\d)+(?!\d))><$1,>g;
    $num;
}

# FLIST ファイルへファイル情報を書き出し (NMZ.f)
sub put_file_info ($$$$$$$) {
    my ($url, $title, $cfile_size, $contents, $headings, $cfile, $fields) = @_;

    my $summary = make_summary($contents, $headings, $cfile, $fields);
    $title =~ s/\s+/ /g;
    $title =~ s/^\s+//;
    $title =~ s/\s+$//;
    $cfile_size = commas($cfile_size);

    # FLIST へ書き出し <DT> の後に改行が欲しいのです
    print FLIST "<DT>\n<STRONG><A HREF=\"$url\">$title</A></STRONG>\n";
    print FLIST "<DD>$summary\n";
    print FLIST "<DD><A HREF=\"$url\">$url</A> size ($cfile_size bytes)<BR><BR>\n";
    # 最後に空行を入れる(これは重要な仕様)
    print FLIST "\n";
}

# 要約を作成する
# 罫線を削除する処理は古川@ヤマハさんにいただきました v1.2.0
sub make_summary ($$$$) {
    my ($contents, $headings, $cfile, $fields) = @_;

    # 頭の $SUMMARY_LENGTH bytes (または $SUMMARY_LENGTH + 1) を取り出し
    my $tmp = "";
    if ($$headings ne "") {
	$$headings =~ s/^\s+//;
	$$headings =~ s/\s+/ /g;
	$tmp = $$headings;
    } else {
	$tmp = "";
    }

    my $offset = 0;
    my $tmplen = 0;
    while (($tmplen = $SUMMARY_LENGTH + 1 - length($tmp)) > 0
           && $offset < length($$contents))
    {
        $tmp .= substr($$contents, $offset, $tmplen);
        $offset += $tmplen;
        $tmp =~ s/(([\xa1-\xfe]).)/$2 eq "\xa8"? '': $1/ge;
        $tmp =~ s/([-=*\#])\1{2,}/$1$1/g;
    }

    my $summary = substr($tmp, 0, $SUMMARY_LENGTH);
    my $kanji = $summary =~ tr/\xa1-\xfe/\xa1-\xfe/;
    $summary .= substr($tmp, $SUMMARY_LENGTH, 1) if $kanji %2;

    # 含まれる '<' と '>' '&' を実体参照へ変換
    encode_entity(\$summary);

    my $header = "";
    if ($NoInsertHeaderOpt) { 
	$header = "";
    } else {
	$header = make_summary_header($cfile, $fields);
    }
    $summary = $header . $summary if $header;
    $summary =~ s/^\s+//;
    $summary =~ s/\s+/ /g;   # ホワイトスペースをまとめる
    $summary;
}

sub make_summary_header ($) {
    my ($cfile, $fields) = @_;
    my $header = "";

    foreach $_ (keys (%{$fields})) {
	if (defined($FIELD_ALIASES{$_}) && 
	    defined($fields->{$FIELD_ALIASES{$_}})) {
	    next;
	}
	if ($_ =~ /^($SUMMARY_HEADER)$/i) {
	    my $field = $_;
	    $field = ucfirst($field);  # Capitalize
	    $header .= "$field: $fields->{$_}\n";
	}
    }
    # Mail/News のヘッダを付加する
    encode_entity(\$header);
    $header =~ s/(\S+):(.*)\n/<STRONG>$1<\/STRONG>:<EM>$2<\/EM><BR>/g 
	if $header;
    $header; # return value
}

# フレーズのハッシュを作成する
# 2単語の組でひとつのハッシュ値 (0-65535) を生成します
sub make_phrase_hash ($$$) {
    my ($file_count, $file_segment, $contents) = @_;
    my ($word, @words, $hash, $word_b, %tmp);

    $$contents =~ s/\x7f *\/? *\d+ *\x7f//g;  #重みづけのタグを捨てる
    @words = split(/\s+/, $$contents);
    @words = grep(!/^$/, @words);   # 空の語を捨てる
    $word_b = $words[0];

    foreach $word (@words) {
	$hash = hash($word_b . $word);
	if (!defined($tmp{$hash})) {
	    $tmp{$hash} = 1;
	    $PhraseHash{$hash}  = pack("i", 0) 
		if (!defined($PhraseHash{$hash}));
	    $PhraseHash{$hash} .= pack("i", $file_count + $file_segment);
	    dprint "<$word_b, $word> $hash\n";
	}
	$word_b = $word;
    }
}

# NMZ.p, NMZ.pi ファイルへ書き出し & マージする (複雑)
sub put_phrase_hash () {
    my ($key, $ptr, $i, $n, $nn, $n2, $baserecord, $record, $opened);

    return if %PhraseHash eq "0";
    dprint "// doing put_phrase_hash() processing.\n";

    open(TMP_PI, ">$TMP_PI") || die "$TMP_PI: $!\n";
    binmode(TMP_PI);
    open(TMP_P, ">$TMP_P") || die "$TMP_P: $!\n";
    binmode(TMP_P);

    if (open(PHRASE, "$PHRASE_")) {
	binmode(PHRASE);
	open(PHRASEINDEX , "$PHRASEINDEX_") || die "$PHRASEINDEX_: $!\n";
	binmode(PHRASEINDEX);
	$opened = 1;
    }
	
    $ptr = 0;
    $n = 0;
    for ($i = 0; $i < 65536; $i++) {
	$baserecord = "";
	if ($opened) {
	    read(PHRASEINDEX, $n, $INTSIZE);
	    $nn = unpack("i", $n);
	    if ($nn != -1 ) { # -1 
		read(PHRASE, $n, $INTSIZE);
		$nn = unpack("i", $n);
		read(PHRASE, $baserecord, $INTSIZE * $nn);
	    }
	}
	if (defined($PhraseHash{$i})) {
	    if ($baserecord eq "") {
		print TMP_PI pack("i", $ptr);
		$n2 = get_n($PhraseHash{$i});
		$record = substr($PhraseHash{$i}, $INTSIZE);
		print TMP_P pack("i", $n2), $record;
		$ptr += ($n2 + 1) * $INTSIZE;
	    } else {
		print TMP_PI pack("i", $ptr);
		$n2 = get_n($PhraseHash{$i});
		$n2 += $nn;
		$record = substr($PhraseHash{$i}, $INTSIZE);
		print TMP_P pack("i", $n2), $baserecord, $record;
		$ptr += ($n2 + 1) * $INTSIZE;
	    }
	} else {
	    if ($baserecord eq "") {
		# 要素を持たない場合は -1 にしておく
		print TMP_PI pack("i", -1);
	    } else {
		print TMP_PI pack("i", $ptr);
		print TMP_P $n, $baserecord;
		$ptr += ($nn + 1) * $INTSIZE;
	    }
	}
    }
    %PhraseHash = ();
    if ($opened) {
	close(PHRASE);
	close(PHRASEINDEX);
    }
    close(TMP_P);
    close(TMP_PI);
    Rename($TMP_P, $PHRASE_);
    Rename($TMP_PI, $PHRASEINDEX_);
}

# Dr. Knuth's  ``hash'' from (UNIX MAGAZINE May 1998)
sub hash ($) {
    my ($word) = @_;
    my ($i, $hash);

    $hash = 0;
    $word =~ tr/\xa1-\xfea-z0-9//cd; # 記号を捨てる
    for ($i = 0; $word ne ""; $i++) {
	$hash ^= $Seed[$i % 4][ord($word)];
        $word = substr($word, 1);
	# $word =~ s/^.//;  is slower
    }
    $hash & 65535;
}

# 単語の頻度数を数える
sub count_words ($$$$) {
    my ($file_count, $file_segment, $contents, $kanji) = @_;
    my ($word, @tmp, @words, @words_, %word_count, $part1, $part2, $tmp);

    # 小文字に正規化
    $$contents =~ tr/A-Z/a-z/;

    # わかち書き
    if ($LANGUAGE eq "ja") {
	wakatize_japanese($contents) if $kanji;
    }

    # 記号を全て削除する -K オプション時
    $$contents =~ tr/\xa1-\xfea-z0-9/   /c if $NoSymbolOpt;

#     $part1 = $$contents;  # 普通の部分
#     $part2 = $$contents;  # 重みづけ部分
#     $part1 =~ s/(.*?)(\t.*)/$1/s;
#     $part2 =~ s/(.*?)(\t.*)/$2/s;

    if ($$contents =~ /\x7f/) {
	$part1 = substr($$contents, 0, index($$contents, "\x7f"));
	$part2 = substr($$contents, index($$contents, "\x7f"));
#	$part1 = $PREMATCH;  # $& and friends are not efficient
#	$part2 = $MATCH . $POSTMATCH;
    } else {
	$part1 = $$contents;
	$part2 = "";
    }

    # スコアの重みづけを行う
    $part2 =~ s/\x7f *(\d+) *\x7f([^\x7f]*)\x7f *\/ *\d+ *\x7f/wordcount_sub($2, $1, \%word_count)/ge;
    wordcount_sub($part1, 1, \%word_count);

    # 全体のキーインデックスに追加する
    $tmp = $file_count + $file_segment;
    foreach $word (keys(%word_count)) {
	next if ($word eq "" || length($word) > $WORD_LENG_MAX);
	$KeyIndex{$word} = pack("i", 0) if (!defined($KeyIndex{$word}));
	$KeyIndex{$word} .= pack("i2", $tmp, $word_count{$word});
    }
    %word_count = ();
}



# わかち書きによる日本語の単語の区切り出し
sub wakatize_japanese ($) {
    my ($contents) = @_;
    my (@tmp);

    # IPC::Open2 もあるけど試したらちょっと変でしかも遅かった
    open(WAKATI, "|$WAKATI > $WAKATITMP");
    binmode(WAKATI);
    print WAKATI $$contents;
    close(WAKATI);

    open(WAKATI, "$WAKATITMP");
    binmode(WAKATI);
    @tmp = <WAKATI>;
    close(WAKATI);
    unlink $WAKATITMP;

    # ひらがなだけの語は削除する -H オプション時
    # このコードは古川@ヤマハさんがくださりました。[11/13/1997]
    # 送り仮名についても対応 (古川さんのコードより) [04/24/1998]
    if ($HiraganaOpt || $OkuriganaOpt){
        my ($ndx);
        for ($ndx = 0; $ndx <= $#tmp; ++$ndx){
	    $tmp[$ndx] =~ s/(\s)/ $1/g;
	    $tmp[$ndx] = ' ' . $tmp[$ndx];
	    if ($OkuriganaOpt) {
		$tmp[$ndx] =~ s/([^\xa4][\xa1-\xfe])+(\xa4[\xa1-\xf3])+ /$1 /g;
	    }
	    if ($HiraganaOpt) {
		$tmp[$ndx] =~ s/ (\xa4[\xa1-\xf3])+ //g;
	    }
        }
    }


    # 品詞情報を元に名詞のみを登録する -m オプション時
    if ($MorphOpt) {
	$$contents = "";
	$$contents .= shift(@tmp) =~ /(.+ )名詞/ ? $1 : "" while @tmp; 
    } else {
	$$contents = join("", @tmp);
    }
}


# 単語を数えるサブルーチン スコアの重みづけも行う
sub wordcount_sub ($$\%) {
    my ($text, $weight, $word_count) = @_;
    my (@words, @words_, $word, $tmp);

    # カレントファイルの単語の出現回数を調べる
    # 記号をそれなりに処理する
    # tcp/ip なら tcp/ip, tcp, ip と 3 つに分解される
    # (tcp/ip) なら (tcp/ip), tcp/ip, tcp, ip の 4 つなる
    # ((tcpi/ip)) なら ((tcp/ip)), (tcp/ip), tcp, ip の 4 つになる
    # 入れ子処理は行わない
    # ただし -K オプション指定時は記号はすべて削除している

    @words = split(/\s+/, $text);
    @words = grep(!/^$/, @words);   # 空の語を捨てる
    @words_ = ();
    foreach $word (@words) {
	if ($NoEdgeSymbolOpt) {
	    # 両端の記号を削除
	    $word =~ s/^[^\xa1-\xfea-z_0-9]*(.*?)[^\xa1-\xfea-z_0-9]*$/$1/g;
	}
	$word_count->{$word} = 0 unless defined($word_count->{$word});
	$word_count->{$word} += $weight;
	unless ($NoSymbolOpt) {
	    if ($word =~ /^[^\xa1-\xfea-z_0-9](.+)[^\xa1-\xfea-z_0-9]$/) {
		$word_count->{$1} = 0 unless defined($word_count->{$1});
		$word_count->{$1} += $weight;
		next unless $1 =~ /[^\xa1-\xfea-z_0-9]/;
	    } elsif ($word =~ /^[^\xa1-\xfea-z_0-9](.+)/) {
		$word_count->{$1} = 0 unless defined($word_count->{$1});
		$word_count->{$1} += $weight;
		next unless $1 =~ /[^\xa1-\xfea-z_0-9]/;
	    } elsif ($word =~ /(.+)[^\xa1-\xfea-z_0-9]$/) {
		$word_count->{$1} = 0 unless defined($word_count->{$1});
		$word_count->{$1} += $weight;
		next unless $1 =~ /[^\xa1-\xfea-z_0-9]/;
	    }
	    push(@words_, split(/[^\xa1-\xfea-z_0-9]+/, $word))
		if $word =~ /[^\xa1-\xfea-z_0-9]/;
	    @words_ = grep(!/^$/, @words_);   # 空の語を捨てる
	    foreach $tmp (@words_) {
		next if $tmp eq "";
		$word_count->{$tmp} = 0 unless defined($word_count->{$tmp});
		$word_count->{$tmp} += $weight;
	    }
	    @words_ = ();
	}
    }
    "";
}

# indexing に関する雑多な処理をする共通ルーチン
sub indexingmisc ($$$$$) {
    my ($word, $hash_ptr, $hash_count, $key_count, $leng) = @_;
    my ($h);

    print INDEXINDEX pack("i", $$hash_ptr);

    $h = vec($word, 0, 16);

    for (; $$hash_count <= $h ; $$hash_count++) {
	print HASH pack("i", $$key_count);
    }
    $$key_count++;
    $$hash_ptr += $leng;
}

# hash の残りを処理
sub put_hash_rest ($$) {
    my ($hash_count, $key_count) = @_;
    for (; $hash_count < 65537; $hash_count++) {
	# 65537 なのは最後に番兵を置いているからです(本当はいらないのだけど)
	print HASH pack("i", $key_count);
    }
}


# $KeyIndex{} に保存されている要素の数を取得する
sub get_n ($) {
    my ($tmp) = @_;
    $tmp = length($tmp);
    $tmp -= $INTSIZE;
    $tmp /= $INTSIZE;
}

# 文字列の unsigned な比較ルーチン。
# このルーチンは古川@ヤマハさんがくださりました
# ほんの少し改変 v1.1.1.3 [02/27/1998]
sub unsignedcmp {
    my ($str1, $str2) = @_;
    my ($ord1, $ord2);

    while (($ord1 = ord($str1)) == ($ord2 = ord($str2))) {
        last if ! $ord1;
        $str1 =~ s/^.//;
        $str2 =~ s/^.//;
    }
    $ord1 <=> $ord2;
}

# INDEX ファイルへ書き出し & マージする (複雑)
sub put_index () {
    my ($n, $nn, $record, $baserecord, @words, $cnt, $i, $current_word); 
    my ($hash_ptr, $hash_count, $key_count);

    # 一部の perl の実装では日本語 EUC のソートがうまくいかないため、
    # (おそらくは signed/unsigned の問題) その際は専用の比較ルーチン
    # を用いる。この部分のコードは古川@ヤマハさんが提供してくださりました
    if (('a' cmp 'あ') < 0) {
        @words = sort keys(%KeyIndex);
    }
    else {
	$UnsignedCmp = 1;
 	@words = sort {unsignedcmp($a, $b)} keys(%KeyIndex);
    }
    return 0 if $#words == -1;
    dprint "// doing put_index() processing.\n";

    open(INDEXINDEX , ">$INDEXINDEX_") || die "$INDEXINDEX: $!\n";
    binmode(INDEXINDEX);
    open(HASH , ">$HASH_") || die "$HASH: $!\n";
    binmode(HASH);
    open(TMP_I , ">$TMP_I") || die "$TMP_I: $!\n";
    binmode(TMP_I);

    unless ($NoRegexpIndexOpt) {
	open(TMP_W , ">$TMP_W") || die "$TMP_W: $!\n";
	binmode(TMP_W);
    }

    $cnt = 0;
    $hash_ptr = 0;
    $hash_count = 0;
    $key_count = 0;
    $n = 0;
    $baserecord = "";
    if (open(INDEX , "$INDEX_")) {
	binmode(INDEX);
      FOO:
	while (<INDEX>) {
	    $i++;

	    $current_word = $_;
	    chop $current_word;

	    read(INDEX, $n, $INTSIZE);
	    $nn = unpack("i", $n);
	    read(INDEX, $baserecord, $INTSIZE * $nn);
	    <INDEX>;

 	    for (; $cnt <= $#words; $cnt++) {
		# SunOS4 + Perl5.003 has problem on string comparison
		# so, use unsignedcmp
		unless (($UnsignedCmp 
		     ? (unsignedcmp($words[$cnt], $current_word) <= 0)
		     : ($words[$cnt] le $current_word))) {
		    last;
		}
		$n = get_n($KeyIndex{$words[$cnt]});
		$record = substr($KeyIndex{$words[$cnt]}, $INTSIZE);

		if ($current_word eq $words[$cnt]) {
		    $n += $nn;
		    $n = pack("i", $n);

		    $_ = "$current_word\n$n$baserecord$record\n";
		    print TMP_W "$current_word\n"
			unless $NoRegexpIndexOpt;
		    print TMP_I;
		    indexingmisc($current_word, \$hash_ptr,
				  \$hash_count, \$key_count, length($_));

		    $cnt++;
		    next FOO;
		} else {
		    $n = pack("i", $n);
		    $_ = "$words[$cnt]\n$n$record\n";
		    print TMP_W "$words[$cnt]\n"
			unless ($NoRegexpIndexOpt);
		    print TMP_I;
		    indexingmisc($words[$cnt],  \$hash_ptr,
				  \$hash_count, \$key_count, length($_));
		}
	    }
	    $nn = pack("i", $nn);
	    $_ = "$current_word\n$nn$baserecord\n";
	    print TMP_W "$current_word\n"
		unless $NoRegexpIndexOpt;
	    print TMP_I;
	    indexingmisc($current_word, \$hash_ptr,
			  \$hash_count, \$key_count, length($_));
	}
    }
    while ($cnt <= $#words) {
	$n = get_n($KeyIndex{$words[$cnt]});
	$n = pack("i", $n);
	$record = substr($KeyIndex{$words[$cnt]}, $INTSIZE);

	$_ = "$words[$cnt]\n$n$record\n";
	print TMP_W "$words[$cnt]\n"
	    unless $NoRegexpIndexOpt;
	print TMP_I;
	indexingmisc($words[$cnt],  \$hash_ptr,
		      \$hash_count, \$key_count, length($_));
	$cnt++;
    }
    %KeyIndex = ();
    put_hash_rest($hash_count, $key_count);

    close(INDEX);
    close(INDEXINDEX);
    close(HASH);
    close(TMP_I);
    close(TMP_W);

    Rename($TMP_I, $INDEX_);
    Rename($TMP_W, $WORDLIST_);
    $LastKeyN = $i if $APPENDMODE && (! $LastKeyN);
    $key_count;
}

# make a FLISTINDEX file
sub make_flist_index () {
    my ($f, $ptr);

    open(FLIST , "$FLIST_") || die "$FLIST: $!\n";
    open(FLISTINDEX , ">$FLISTINDEX_") || die "$FLISTINDEX: $!\n";
    binmode(FLISTINDEX);

    $ptr = 0;
    $f = 1;

    while (<FLIST>) {
	print FLISTINDEX pack("i", $ptr) if $f;
	if (/^\n$/) { 
	    $f = 1;
	} else {
	    $f = 0;
	}
	$ptr += length;
    }
    close(FLIST);
    close(FLISTINDEX);
}


# Replacement for cp command.  Efficiency is nearly equal. v1.1.1
sub cp ($$) {
    my ($from, $to) = @_;

    open(FROM, "$from") || die "$from: $!\n";
    binmode(FROM);
    open(TO, ">$to")    || die "$to: $!\n";
    binmode(TO);

    my $buf = "";
    while(read (FROM, $buf, 16384)) {
        print TO $buf;
    }
    close(FROM);
    close(TO);
}

#  rename() with consideration for OS/2
sub Rename($$) {
    my ($from, $to) = @_;

    return unless -e $from;
    unlink $to if (-f $from) && (-f $to);  # some systems require this
    if (0 == rename($from, $to)) {
	die "rename($from, $to): $!\n";
    };
}

# Check the byte order
sub is_big_endian() {
    if (ord(pack('i', 1)) == 1) {
	return 0;
    } else {
	return 1;
    }
}

# Knuth先生の ``hash'' (UNIX MAGAZINE 1998 5月号) 用の乱数表
# 0-65535までの数を使った要素数256の乱数表を 4つ使います。
sub init_seed () {
	(
	 [
	  3852, 26205, 51350, 2876, 47217, 47194, 55549, 43312, 
	  63689, 40984, 62703, 10954, 13108, 60460, 41680, 32277, 
	  51887, 28590, 17502, 57168, 37798, 27466, 13800, 12816, 
	  53745, 8833, 55089, 15481, 18993, 15262, 8490, 22846, 
	  41468, 59841, 25722, 23150, 41499, 15735, 926, 39653, 
	  56720, 63629, 50607, 4292, 58554, 26752, 36570, 44905, 
	  55343, 54073, 36538, 27605, 16003, 50339, 40422, 4213, 
	  59172, 29975, 19694, 12629, 45238, 28185, 35475, 21170, 
	  22491, 61198, 44320, 63991, 11398, 45247, 38108, 2583, 
	  43341, 23180, 6875, 36359, 49933, 43446, 15728, 39740, 
	  31983, 52267, 1809, 47986, 37070, 42232, 52199, 30706, 
	  6672, 6358, 43336, 51910, 34544, 13276, 7545, 57036, 
	  8939, 51866, 55491, 20338, 31577, 28064, 22921, 9383, 
	  51245, 29797, 45742, 35642, 7707, 61471, 9847, 39691, 
	  48202, 11656, 22141, 19736, 53889, 8805, 50443, 60561, 
	  15164, 28244, 46936, 49709, 41521, 54481, 41209, 50460, 
	  40812, 31165, 5262, 6853, 59230, 28184, 16237, 44940, 
	  57981, 61979, 15046, 152, 57914, 24893, 39843, 40581, 
	  36550, 61985, 60318, 24904, 5255, 45226, 19929, 20420, 
	  7934, 1329, 4593, 49456, 55811, 45803, 34381, 31087, 
	  11433, 39644, 37941, 5128, 2292, 54178, 50068, 60273, 
	  50622, 65115, 60426, 43000, 24473, 34734, 18046, 61024, 
	  31184, 12828, 20392, 36439, 58054, 40322, 56860, 453, 
	  41651, 61453, 49909, 31927, 41721, 18754, 63015, 53155, 
	  58398, 35421, 58283, 60691, 24063, 42816, 55428, 9149, 
	  42395, 50319, 52150, 1332, 19517, 4661, 62357, 50701, 
	  17489, 17213, 21605, 10008, 57535, 12929, 10462, 33651, 
	  8847, 60371, 43, 50569, 13590, 63058, 38188, 6453, 
	  32943, 30936, 1608, 57007, 8216, 57037, 621, 50611, 
	  41820, 52771, 51944, 61338, 57433, 48765, 46504, 9387, 
	  443, 2573, 19395, 57978, 15503, 29857, 26094, 24351, 
	  24693, 26137, 9385, 38284, 23659, 47573, 44738, 56602
	  ],
	 [
	  12974, 46347, 48074, 21190, 37848, 48695, 6266, 14133, 
	  35931, 58211, 9935, 27828, 41440, 56440, 37215, 41883, 
	  59014, 56610, 34326, 8982, 20932, 60420, 33333, 45626, 
	  21021, 42718, 18375, 44681, 24756, 63113, 35748, 37730, 
	  43924, 18286, 58920, 1445, 65187, 30371, 37376, 57862, 
	  40307, 65205, 33766, 31211, 36884, 10114, 24689, 27959, 
	  44441, 33671, 48892, 39326, 1469, 28982, 60348, 44188, 
	  47357, 39493, 3408, 44935, 9705, 41138, 23324, 27992, 
	  34523, 39562, 29437, 34174, 4397, 1278, 26500, 44705, 
	  947, 60267, 10380, 37832, 4846, 35070, 255, 49288, 
	  3206, 49147, 23078, 4676, 12594, 17890, 48864, 59951, 
	  57383, 52273, 39351, 1553, 27875, 62675, 29545, 62399, 
	  36701, 58983, 31038, 41099, 60262, 57539, 20268, 61210, 
	  52271, 30649, 33506, 57118, 184, 33762, 40870, 3390, 
	  17374, 63949, 8067, 29968, 16303, 56931, 24384, 8151, 
	  43668, 63736, 6008, 60875, 39251, 2872, 32040, 32699, 
	  33910, 7603, 27426, 25914, 27872, 23100, 12649, 58521, 
	  56607, 4231, 58705, 24834, 45102, 62096, 42208, 43515, 
	  4627, 6641, 59819, 61559, 31026, 2435, 39692, 29226, 
	  12141, 45700, 24565, 51392, 48573, 56606, 18556, 16947, 
	  64210, 45982, 42861, 26546, 3546, 55511, 19531, 60154, 
	  59743, 12700, 19452, 39309, 9261, 61660, 17289, 13888, 
	  2766, 11572, 9912, 33792, 14008, 49604, 63018, 26149, 
	  29769, 22048, 12006, 12806, 13118, 30562, 29754, 11792, 
	  11008, 7080, 38339, 14554, 62591, 57870, 9172, 56798, 
	  5035, 28625, 30572, 14297, 24749, 47861, 27515, 59433, 
	  38098, 61308, 7906, 22166, 58790, 34055, 51935, 15303, 
	  46061, 64742, 28421, 11087, 28960, 40214, 22095, 36041, 
	  13018, 36650, 33096, 5352, 45823, 24359, 10388, 8912, 
	  54931, 24685, 33662, 37257, 52871, 61178, 31155, 25433, 
	  56950, 39061, 47599, 50204, 7580, 33999, 65507, 53642, 
	  33205, 28393, 64730, 62166, 3072, 21290, 32671, 16090
	  ],
	 [
	  57940, 232, 21443, 38228, 24592, 31831, 47141, 13988, 
	  56517, 15268, 43852, 10910, 16864, 3750, 2324, 55926, 
	  52529, 63507, 19813, 52501, 51613, 53019, 15359, 50807, 
	  49650, 18431, 6561, 16785, 34522, 64502, 17018, 55965, 
	  37195, 41610, 22261, 18801, 55598, 13243, 34069, 41307, 
	  57095, 44979, 58172, 60846, 47304, 48562, 46660, 34298, 
	  46533, 938, 21264, 32611, 53957, 36623, 17883, 38072, 
	  55055, 24444, 54857, 24042, 23411, 6340, 14471, 60606, 
	  47950, 36733, 13872, 38012, 49976, 47941, 13784, 41536, 
	  27385, 6421, 36846, 9154, 54984, 17971, 43452, 35982, 
	  18909, 64716, 3057, 7331, 35804, 20941, 45403, 25324, 
	  45385, 34725, 49366, 3261, 41065, 63838, 63868, 23479, 
	  35036, 12204, 61492, 19476, 60146, 9741, 61013, 21995, 
	  16163, 32324, 31149, 5612, 50295, 9066, 41594, 3669, 
	  8247, 44652, 11000, 44052, 57, 56404, 3840, 45443, 
	  25593, 53206, 48704, 1123, 51508, 47037, 24603, 21008, 
	  59241, 20559, 40485, 53851, 30301, 35963, 10311, 46465, 
	  2751, 41461, 52077, 53047, 50527, 28135, 56717, 58775, 
	  7252, 2182, 37291, 7309, 58586, 41131, 52753, 18644, 
	  28802, 35922, 19767, 14775, 17423, 44371, 35784, 11128, 
	  64931, 10734, 64980, 29696, 46697, 9756, 10626, 49449, 
	  51217, 36961, 36209, 25303, 28142, 29448, 32555, 30324, 
	  1204, 39865, 23375, 42336, 27082, 42020, 5602, 63004, 
	  61788, 20378, 14892, 40623, 56162, 26021, 40018, 1360, 
	  25466, 4179, 48058, 35222, 14805, 31971, 20903, 11973, 
	  3396, 57112, 37276, 31539, 21025, 4295, 61864, 22230, 
	  44161, 19704, 64566, 5707, 61724, 4633, 3176, 57977, 
	  25011, 18069, 33064, 15638, 44090, 7547, 16998, 4020, 
	  11727, 65056, 39242, 26532, 31492, 38506, 34888, 51723, 
	  10246, 891, 7213, 14542, 62756, 29443, 58703, 16924, 
	  28473, 64411, 13112, 33107, 2052, 5554, 58118, 20121, 
	  38618, 8220, 64212, 46166, 25219, 2696, 57893, 24740
	  ],
	 [
	  41939, 18890, 56232, 36549, 57396, 25584, 22736, 2106, 
	  26476, 29949, 16648, 23697, 59393, 9816, 40621, 22331, 
	  8691, 53734, 55438, 10743, 59288, 48021, 30865, 32371, 
	  56242, 29541, 13001, 15925, 32237, 5358, 40666, 8641, 
	  24249, 31362, 45191, 16109, 56947, 2391, 18216, 17887, 
	  32341, 34864, 41584, 26199, 44680, 16670, 48530, 53372, 
	  4868, 38432, 64115, 64156, 20918, 29445, 30992, 11624, 
	  58986, 43993, 27550, 25688, 49352, 2680, 34329, 8065, 
	  34042, 13984, 24174, 25454, 16376, 42391, 43342, 48718, 
	  11719, 19390, 9381, 56400, 36061, 57911, 44237, 40929, 
	  30808, 39550, 51726, 6725, 5006, 63351, 176, 49000, 
	  25365, 25864, 32816, 28046, 60193, 40882, 62089, 8642, 
	  65057, 22007, 25018, 41912, 65349, 8201, 53632, 19204, 
	  17582, 44496, 55265, 9957, 23197, 30659, 40765, 478, 
	  4674, 26956, 7204, 9681, 24771, 7380, 58681, 50137, 
	  33245, 25962, 12647, 27903, 1308, 9200, 36545, 829, 
	  31207, 61564, 42741, 31021, 4229, 30837, 50225, 21812, 
	  9798, 39955, 31769, 32996, 5078, 6999, 33475, 9753, 
	  33956, 40679, 19434, 58727, 48060, 12579, 43328, 15770, 
	  38541, 55975, 43673, 39849, 65176, 14683, 30848, 10711, 
	  17884, 61869, 14941, 48722, 46559, 36753, 58520, 20978, 
	  2987, 25981, 26057, 9987, 59456, 35810, 43943, 34600, 
	  55244, 37135, 17124, 2288, 14928, 32895, 40829, 5368, 
	  11032, 15143, 5008, 25715, 55822, 35856, 36427, 8171, 
	  32190, 51369, 56893, 13214, 22587, 49878, 34193, 25575, 
	  10323, 60250, 35562, 4243, 30525, 13970, 38843, 20234, 
	  51106, 55968, 22523, 498, 23327, 63352, 5866, 34360, 
	  12960, 10874, 60076, 3247, 46731, 30967, 11418, 13386, 
	  16801, 2776, 26600, 39388, 52654, 60793, 64963, 62978, 
	  55508, 34990, 1686, 20498, 48960, 40530, 40733, 34530, 
	  30962, 63256, 35029, 54290, 61073, 40895, 23115, 8497, 
	  51770, 17655, 11744, 32966, 48622, 23162, 46352, 65423
	  ]
	 );
}

# 対象ファイルが HTML かどうかを判別
sub ishtml ($) {
    my ($cfile) = @_;

    ($cfile =~ /\.($HTML_SUFFIX)$/i || 
    $cfile =~ /($DEFAULT_FILE)$/ || 
    $cfile =~ /\?/ || 
    $cfile =~ /($CGI_DIR)/i);
}

# Robots.txt の読み込み
# Disallow 行以外はいっさい無視
#
# This code was contributed by 
#  - [Gorochan ^o^ <kunito@hal.t.u-tokyo.ac.jp>]
#
sub ParseRobotsTxt (){
    my($url);
    if (not -f "$ROBOTS_TXT") {
	warn "$ROBOTS_TXT does not exists";
	$ROBOTS_EXCLUDE_URLS="\t";
	return 0;
    }
    open(ROBOTTXT, "$ROBOTS_TXT") || die "Can't open $ROBOTS_TXT : $!\n";
    while(<ROBOTTXT>){
	/^\s*Disallow:\s*(\S+)/i && do {
	    $url = $1;
	    $url =~ s/\%/%25/g;  # 元から含まれる % は %25 に変更 v1.1.1.2
	    $url =~ s/([^a-zA-Z0-9\-\_\.\/\:\%])/
		sprintf("%%%02X",ord($1))/ge;
	    if (($SYSTEM eq "MSWin32") || ($SYSTEM eq "os2")) {
		# restore '|' for drive letter rule of Win32, OS/2
		$url =~ s!^/([A-Z])%7C!/$1|!i;
	    }
	    $ROBOTS_EXCLUDE_URLS .= "^$HTDOCUMENT_ROOT_URL_PREFIX$url|";
	}
    }
    close(ROBOTTXT);
    chop($ROBOTS_EXCLUDE_URLS);
}


#
# Added by G.Kunito <kunito@hal.t.u-tokyo.ac.jp>
# .htaccess アクセス制限ファイルを調べる
# deny, require valid-user, user, group 等があれば return(1)
# 
sub ParseHtaccess(){
    my $inLimit = 0;
    my $err;
    my $r = 0;
    my $CWD;

    open(HTACCESS, ".htaccess" ) or 
	$err = $!,  $CWD = cwd() , die "$CWD/.htaccess : $err\n";
    while(<HTACCESS>) {
	s/^\#.*$//;
	/^\s*$/ && next;
	/^\s*deny\s+|require\s+(valid-user|user|group)([^\w]+|$)/i && do {
	    $r=1;
	    last;
	};
    }
    close(HTACCESS);
    return($r);
}

# find.pl をほんの少し修正して Symbolic link なディレクトリもたどるようにした
package find;
no strict;
use Cwd;

sub find {
    local ($cwd);
    local ($dev, $dir, $dont_use_nlink, $fixtopdir, $ino, $mode,
	$name, $nlink, $prune, $subcount, $tmp, $topdev, $topdir, $topino,
	$topmode, $topnlink);

    $dont_use_nlink = 1; ## S.Takabayashi added.
    $cwd = cwd();

    foreach $topdir (@_) {
	(($topdev,$topino,$topmode,$topnlink) = stat($topdir))
	  || (warn("Can't stat $topdir: $!\n"), next);

	if (-d _) { 
	    if (chdir($topdir)) {
		($dir,$_) = ($topdir,'.');
		$name = $topdir;
		main::wanted($name);
		($fixtopdir = $topdir) =~ s,$PSC$,, ;
		finddir($fixtopdir,$topnlink);
	    }
	    else {
		warn "Can't cd to $topdir: $!\n";
	    }
	}
	else {
	    unless (($dir,$_) = $topdir =~ m#^(.*$PSC)(.*)$#) {
		($dir,$_) = ('.', $topdir);
	    }
	    $name = $topdir;
	    chdir $dir && main::wanted($name);
	}
	chdir $cwd;
    }
}


# ファイル名を数字を考慮してソートする
# このコードはは古川@ヤマハさんに頂きました
sub fncmp {
    my ($x, $y) = ($a, $b);
    # ファイル名のソートを数値も考慮して行なう
    # 普通にやると、1, 10, 2, 3, ... の順になってしまう。
    # ちゃんとやる方法もあるが、面倒なので、
    # ケタ数を適当に制限して安易に実装。
    # ファイル名に 8 ケタより長い数字が無ければ大丈夫。

    $x =~ s/(\d+)/sprintf("%08d", $1)/ge;
    $y =~ s/(\d+)/sprintf("%08d", $1)/ge;
    $x cmp $y;
}

sub finddir {
    local ($dir,$nlink) = @_;
    local ($dev,$ino,$mode,$subcount);
    local ($name);
    local ($tmp);   ## S.Takabayashi added.

    ## Check .htaccess
    ## Added by G.Kunito <kunito@hal.t.u-tokyo.ac.jp>
    if( $HtaccessExcludeOpt && 
       ( -f ".htaccess" ) && main::ParseHtaccess() ){
	printf ("%s is exclude because of .htaccess\n", cwd());
	return(0);
    }
    ##

    # Get the list of files in the current directory.

    opendir(DIR,'.') || (warn "Can't open $dir: $!\n", return);
    my (@filenames) = grep(!/^\.\.?$/, readdir(DIR));
    closedir(DIR);

    # ファイル名を数字を考慮してソートする
    # 新しい順/古い順による疑似ソートを実現するためです
    @filenames = sort fncmp @filenames;

    if ($nlink == 2 && !$dont_use_nlink) {  # This dir has no subdirectories.
	for (@filenames) {
	    $name = "$dir$PSC$_";
	    $nlink = 0;
	    main::wanted($name);
	}
    }
    else {                    # This dir has subdirectories.
	$subcount = $nlink - 2;
	for (@filenames) {
	    $nlink = $prune = 0;
	    $name = "$dir$PSC$_";
	    main::wanted($name);
	    if ($subcount > 0 || $dont_use_nlink) {    # Seen all the subdirs?

		# Get link count and check for directoriness.
		## Modified by S.Takabayashi lstat() -> stat()
		($dev,$ino,$mode,$nlink) = stat($_) unless $nlink;
		
		if (-d _) { 
		    # It really is a directory, so do it recursively.
		    ## and Symbolic Linked dir, also do it.
		    $tmp = '..';
		    if (-l $_) {
			($dev,$ino,$mode,$nlink) = lstat($_);
			if ($SymLinks{"$dev $ino"}) {
			    print "Looped symbolic link detected [$name], skipped.\n";
			    last;
			}
			$SymLinks{"$dev $ino"} = 1;

			$tmp = cwd();
		    }

		    if (!$prune && chdir $_) {
			finddir($name,$nlink);
			chdir $tmp;
		    }
		    --$subcount;
		}
	    }
	}
    }
}

# 対象ディレクトリから処理の対象となるファイルを抽出
sub findfiles ($) {
    local ($psc) = @_;
    $PSC = $psc;

    find(cwd());
}

#
# package for code conversion
#
#   imported from  Rei FURUKAWA <furukawa@dkv.yamaha.co.jp> san's pnamazu.
#   [09/24/1998]

package codeconv;
use strict;

my @ktoe;

sub init_ktoe() {
    @ktoe = (0xA3, 0xD6, 0xD7, 0xA2, 0xA6, 0xF2, 0xA1, 0xA3,
	     0xA5, 0xA7, 0xA9, 0xE3, 0xE5, 0xE7, 0xC3, 0xBC,
	     0xA2, 0xA4, 0xA6, 0xA8, 0xAA, 0xAB, 0xAD, 0xAF,
	     0xB1, 0xB3, 0xB5, 0xB7, 0xB9, 0xBB, 0xBD, 0xBF,
	     0xC1, 0xC4, 0xC6, 0xC8, 0xCA, 0xCB, 0xCC, 0xCD,
	     0xCE, 0xCF, 0xD2, 0xD5, 0xD8, 0xDB, 0xDE, 0xDF,
	     0xE0, 0xE1, 0xE2, 0xE4, 0xE6, 0xE8, 0xE9, 0xEA,
	     0xEB, 0xEC, 0xED, 0xEF, 0xF3, 0xAB, 0xAC, );
}

# convert JIS X0201 KANA characters to JIS X0208 KANA
sub ktoe {
    my ($c1, $c2) = @_;
    $c1 = ord($c1) & 0x7f;
    my($hi) = ($c1 <= 0x25 || $c1 == 0x30 || 0x5e <= $c1)? "\xa1": "\xa5";
    $c1 -= 0x21;
    my($lo) = $ktoe[$c1];
    if ($c2){
        if ($c1 == 5){
            $lo = 0xdd;
        }else{
            $lo++;
            $lo++ if ord($c2) & 0x7f == 0x5f;
        }
    }
    $hi . chr($lo);
}

# convert Shift_JIS to EUC-JP
sub stoe ($$) {
    my($c1, $c2) = @_;

    $c1 = ord($c1);
    $c2 = ord($c2);
    $c1 += ($c1 - 0x60) & 0x7f;
    if ($c2 < 0x9f){
        $c1--;
        $c2 += ($c2 < 0x7f) + 0x60;
    }else{
        $c2 += 2;
    }
    chr($c1) . chr($c2);
}

sub shiftjis_to_eucjp ($){
    my ($str) = @_;
    init_ktoe() unless defined(@ktoe);

    $str =~ s/([\x81-\x9f\xe0-\xfa])(.)|([\xa1-\xdf])([\xde\xdf]?)/($3? ktoe($3, $4): stoe($1, $2))/ge;
    $str;
}


