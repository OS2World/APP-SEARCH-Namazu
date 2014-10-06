#-------------------------- 'configuration' --------------------------
# namazu.conf に無いパラメータの設定、および perl 版特有の設定

# インデクス作成と、検索で使うマシンが違う場合、整数の設定を
# 変更する必要がある可能性があるので、確認すること。
# ここでは、mknmz を実行したマシンでの整数のタイプに合わせる

# big endian, 32bit             -> 'N'
# big endian, 16bit             -> 'n'
# little endian, 32bit          -> 'V'
# little endian, 16bit          -> 'v'
# 上記に関係なく mknmz と同じ   -> 'I'

$IntType = '';

# データベースを gzip で圧縮した場合の、zcat の設定
#   データベースファイルのうち、次の 5 つの拡張子のものは、
#   gzip による圧縮ファイルを使用できる。
#       非圧縮時    圧縮時
#       .h          .h.gz  または .hz
#       .ii         .ii.gz または .iiz
#       .i          .i.gz  または .iz
#       .fi         .fi.gz または .fiz
#       .f          .f.gz  または .fz
#   5 つ全部ではなく、一部だけを圧縮して置くことも可能
#   圧縮ファイルが無ければ、自動的に非圧縮ファイルを読む

$Zcat = '/usr/local/bin/gzip -dc';
#$Zcat = '';                     # 圧縮無し
#$Zcat = '/usr/local/bin/zcat';

# zcat を使う場合に、サーバへの負担を軽減するため、priority を下げる
$ZcatPri = 10;

# 設定の初期値 (コマンドラインオプション、環境変数 QUERY_STRING により変更可能)
$Max = 10;
$Whence = 0;
$DbName = 'NMZ';
$Format = 'long';
$Sort = "score";

# $NamazuDir = "/usr/local/namazu";"

# Zcat を使うときには、ScriptName をきちんと設定しておくことが望ましい
$ScriptName = '';

# namazu.conf の指定
$NamazuConf = '';


# renice の指定、重い処理になったときに、サーバに負担がかかるのを防ぐ
# ため、一定時間が経過したら、priority を下げる。CGI のときだけ有効

# renice が実行されるまでの時間と実行後の priority の設定。どちらも
# 正の数でないと、機能は実行されない。
$ReniceTime = 0;
$RenicePri = 10;

# cmdline 時の argv の順番の指定 'new' にすると、'key string' [index dir]
# の順、'old' にすると、[index dir] 'key string' の順
$CmdLineArg = 'new';

# 他のマシンへ検索結果を聞きに行く機能を有効にするかどうか。1 で有効。
$RemoteEnable = 0;

# database の別名リスト。主に、remote の 'http://' で始まる名前を明かし
# たく無い場合に使う。
# %DbAlias = ('foo' => 'http://hogehoge'); のように指定
%DbAlias = ();

# 有効な database 名のリスト。
# このリストが空でない場合、リストにあるもの以外は使えなくなる。
@DbEnable = ();

# 応答の text の検索式の初期値として、
# 1 ... 入力をそのまま返す
# 0 ... わかち書きなどの処理後の文字列を使う
$RespTextOrig = 0;

# 文書の存在するディレクトリにもリンクする
$SplitLink = 0;
1;
#---------------------- End of 'configuration' -----------------------
