/*
 * 
 * messages.c -
 * 
 * Copyright (C) 1997-1999 Satoru Takabayashi  All rights reserved.
 * This is free software with ABSOLUTELY NO WARRANTY.
 * 
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA
 * 02111-1307, USA
 * 
 * This file must be encoded in EUC-JP encoding.
 * 
 */

#include <stdio.h>
#include <string.h>
#include "namazu.h"

uchar *MSG_MIME_HEADER;

#ifdef LANGUAGE
uchar Lang[] = LANGUAGE;
#else
uchar Lang[] = "en";
#endif

/* information about Namazu */
uchar *VERSION = "1.3.0.11";
uchar *COPYRIGHT =
"  Copyright (C) 1997-1999 Satoru Takabayashi All rights reserved.";

uchar *MSG_USAGE, *MSG_TOO_LONG_KEY, *MSG_TOO_MANY_KEYITEM,
*MSG_RESULT_HEADER, *MSG_NO_HIT, *MSG_HIT_1, *MSG_HIT_2,
*MSG_TOO_MUCH_HIT, *MSG_TOO_MUCH_MATCH, *MSG_INDEXDIR_ERROR,
*MSG_REFERENCE_HEADER, *MSG_INVALID_DB_NAME, *MSG_INVALID_QUERY,
*MSG_CANNOT_OPEN_INDEX, *MSG_CANNOT_OPEN_REGEX_INDEX,
*MSG_CANNOT_OPEN_PHRASE_INDEX, *MSG_CANNOT_OPEN_FIELD_INDEX,
*MSG_QUERY_STRING_TOO_LONG;


/*
  beggening '\t' means this string contains HTML tag.
  It's treated with special care as Namazu's HTML message.
 */

void initialize_message(void)
{
    if (is_lang_ja(Lang)) {
#if	defined(WIN32) || defined(OS2)
        MSG_MIME_HEADER = "Content-type: text/html; charset=ISO-2022-JP\n\n";
#else
        MSG_MIME_HEADER = "Content-type: text/html; charset=ISO-2022-JP\r\n\r\n";
#endif

      MSG_USAGE = "%s\n\
  全文検索システム Namazu の検索プログラム v%s\n\n\
  usage: namazu [options] <query> [index dir(s)] \n\
     -n (num)  : 一度に表示する件数\n\
     -w (num)  : 表示するリストの先頭番号\n\
     -s        : 短いフォーマットで出力\n\
     -S        : もっと短いフォーマット (リスト表示) で出力\n\
     -v        : usage を表示する (この表示)\n\
     -f (file) : namazu.conf を指定する\n\
     -h        : HTML で出力する\n\
     -l        : 新しい順にソートする\n\
     -e        : 古い順にソートする\n\
     -a        : 検索結果をすべて表示する\n\
     -c        : ヒット数のみを表示する\n\
     -r        : 参考ヒット数を表示しない\n\
     -o (file) : 指定したファイルに検索結果を出力する\n\
     -C        : コンフィギュレーション内容を表示する\n\
     -H        : 先の検索結果へのリンクを表示する (ほぼ無意味) \n\
     -F        : <FORM> ... </FORM> の部分を強制的に表示する\n\
     -R        : URL の置き換えを行わない\n\
     -U        : plain text で出力する時に URL encode の復元を行わない\n\
     -L (lang) : メッセージの言語を設定する ja または en\n";

        /* output messages (Japanese message should be outputed by
           euctojisput function */
        MSG_TOO_LONG_KEY =
            "\t<H2>エラー!</H2>\n<P>検索式が長すぎます。</P>\n";
        MSG_TOO_MANY_KEYITEM = 
            "\t<H2>エラー!</H2>\n<P>検索式の項目が多すぎます。</P>\n";
        MSG_QUERY_STRING_TOO_LONG = "CGIのクエリーが長すぎます";
        MSG_INVALID_QUERY = 
            "\t<H2>エラー!</H2>\n<P>検索式が不正です。</P>\n";
        MSG_RESULT_HEADER = "\t<H2>検索結果</H2>\n";
        MSG_NO_HIT = "\t<P>検索式にマッチする文書はありませんでした。</P>\n";
        MSG_HIT_1 = "\t<P><STRONG>検索式にマッチする ";
        MSG_HIT_2 = "\t 個の文書が見つかりました。</STRONG></P>\n\n";
        MSG_TOO_MUCH_HIT = " (ヒット数が多すぎるので無視しました)";
        MSG_TOO_MUCH_MATCH = " (マッチする単語が多すぎるので無視しました)";
        MSG_CANNOT_OPEN_INDEX = " (インデックスが開けませんでした)\n";
        MSG_CANNOT_OPEN_REGEX_INDEX = " (正規表現用インデックスが開けませんでした)";
        MSG_CANNOT_OPEN_FIELD_INDEX = " (フィールド検索用インデックスが開けませんでした)";
        MSG_CANNOT_OPEN_PHRASE_INDEX = " (フレーズ検索用インデックスが開けませんでした)";
        MSG_INDEXDIR_ERROR = "INDEXDIR の設定を確認してください\n";
        MSG_REFERENCE_HEADER = "\t<STRONG>参考ヒット数:</STRONG> ";
        MSG_INVALID_DB_NAME = "不正な dbname の指定です";
    } else {
#if	defined(WIN32) || defined(OS2)
        MSG_MIME_HEADER = "Content-type: text/html\n\n";
#else
        MSG_MIME_HEADER = "Content-type: text/html\r\n\r\n";
#endif

        MSG_USAGE = "%s\n\
  Search Program of Namazu v%s\n\n\
  usage: namazu [options] <query> [index dir(s)] \n\
     -n (num)  : set number of documents shown at once.\n\
     -w (num)  : set first number of documents shown.\n\
     -s        : output by short format.\n\
     -S        : output by more short format (simple listing).\n\
     -v        : print this help and exit.\n\
     -f (file) : set pathname of namazu.conf.\n\
     -h        : output by HTML format.\n\
     -l        : sort documents in reverse order.\n\
     -e        : sort documents in normal order.\n\
     -a        : output all documents.\n\
     -c        : output only hit conunts\n\
     -r        : do not display reference hit counts.\n\
     -o (file) : set output file name.\n\
     -C        : print current configuration.\n\
     -H        : output further result link (nearly meaningless) .\n\
     -F        : force <FORM> ... </FORM> region to output.\n\
     -R        : do not replace URL string.\n\
     -U        : do not decode URL encode when plain text output.\n\
     -L (lang) : set output language (ja or en)\n";

        MSG_TOO_LONG_KEY =
            "\t<H2>Error!</H2>\n<P>Too long query.</P>\n";
        MSG_TOO_MANY_KEYITEM = 
            "\t<H2>Error!</H2>\n<P>Too many queries.</P>\n";
        MSG_QUERY_STRING_TOO_LONG = "Too long CGI query length";
        MSG_INVALID_QUERY = 
            "\t<H2>Error!</H2>\n<P>Invalid query.</P>\n";
        MSG_RESULT_HEADER = "\t<H2>Results:</H2>\n";
        MSG_NO_HIT = "\t<P>No match.</P>\n";
        MSG_HIT_1 = "\t<P><STRONG> Total ";
        MSG_HIT_2 = "\t documents match your query.</STRONG></P>\n\n";
        MSG_TOO_MUCH_HIT = " (Too many pages. Ignored.)";
        MSG_TOO_MUCH_MATCH = " (Too many words. Ignored.)";
        MSG_CANNOT_OPEN_INDEX = " (cannot open index)\n";
        MSG_CANNOT_OPEN_FIELD_INDEX = " (cannot open field index)";
        MSG_CANNOT_OPEN_REGEX_INDEX = " (cannot open regex index)";
        MSG_CANNOT_OPEN_PHRASE_INDEX = " (cannot open phrase index)";
        MSG_INDEXDIR_ERROR = 
            "To Administrator:\nCheck the definition of INDEXDIR.\n";
        MSG_REFERENCE_HEADER = "Word count: ";
        MSG_INVALID_DB_NAME = "Invalid dbname.";
    }
    strcpy(HEADERFILE, "NMZ.head.");
    strcpy(FOOTERFILE, "NMZ.foot.");
    strcpy(BODYMSGFILE, "NMZ.body.");
    strcat(HEADERFILE, Lang);
    strcat(FOOTERFILE, Lang);
    strcat(BODYMSGFILE, Lang);
}



