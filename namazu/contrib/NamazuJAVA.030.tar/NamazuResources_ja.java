/*
 * 日本語リソース
 */
import java.util.*;

public class NamazuResources_ja extends ListResourceBundle {
  public Object[][] getContents () {
	return contents;
  }
  static final Object[][] contents = {
	{"FILE", "ファイル"},
	{"Open", "開く"},
	{"Save", "保存"},
	{"Quit", "終了"},

	{"EDIT", "編集"},
	{"ConfigFile", "設定ファイル"},
	{"Open", "開く"},

	{"VIEW", "参照"},
	{"Usage", "用法"},
	{"Configration", "設定内容"},

	{"OPTIONS", "オプション"},
	{"Browser", "ブラウザ"},

	{"HELP", "ヘルプ"},
	{"VersionInfo", "バージョン情報"},
	{"VERSION", "バージョン"},
	{"LastUpdate", "最終更新日時"},
	{"NowPrinting", "作成中"},

	{"Keyword", "検索式"},

	{"IndexDirectory", "インデックスディレクトリ"},
	{"Number", "表示件数"},
	{"Format", "出力形式"},
	{"TEXT", "テキスト"},
	{"HTML", "ＨＴＭＬ"},
	{"Summary", "要約表示"},
	{"ON", "ＯＮ"},
	{"OFF", "ＯＦＦ"},
	{"Sort", "ソート"},
	{"Increment", "昇順"},
	{"Decrement", "降順"},

	{"Start", "検索開始"},
	{"Clear", "クリア"},

	{"Keyword missing", "検索式空"},
	{"Already Opened", "既オープン"},
	{"Namazu", "なまず"},

	{"Namazu Configuration", "なまず設定"},
	{"Configuration File", "設定ファイル"},
	{"Load Now", "現在の設定のロード"},
	{"Load System Default", "システムデフォルトのロード"},
	{"All Clear", "すっぴん"},

	{"Index Directory", "インデックスのあるディレクトリ"},
	{"Replacement (From)", "検索結果の置き換え (FROM)"},
	{"Replacement (To)", "検索結果の置き換え (TO)"},
	{"BASE HREF", "BASE HREF の指定"},
	{"WAKACHI", "わかち書き用プログラムのパス"},
	{"Temp Directory", "テンポラリ・ディレクトリ"},
	{"Logging", "検索キーのログ"},

	{"History", "検索履歴"},
	{"OK", "反映"}

  };
}
