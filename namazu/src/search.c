/*
 * 
 * search.c -
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
#include <stdlib.h>
#include <string.h>
#include <ctype.h>
#include <time.h>
#include <unistd.h>
#ifdef __EMX__
#include <sys/types.h>
#endif
#include <sys/stat.h>
#include "namazu.h"
#include "util.h"

/* reverse byte order */
void reverse_byte_order (int *p, int n)
{
    int i, j;
    uchar *c, tmp;

    for (i = 0; i < n; i++) {
        c = (char *)(p + i);
        for (j = 0; j < (sizeof(int) / 2); j++) {
            tmp = *(c + j);
            *(c + j)= *(c + sizeof(int) - 1 - j);
            *(c + sizeof(int) - 1 - j) = tmp;
        }
    }
}

/* read 	index and return with value */
long get_index_pointer(FILE * fp, long p)
{
    int val;

    fseek(fp, p * sizeof(int), 0);
    freadx(&val, sizeof(int), 1, fp);
    return (long) val;
}

/* show the status for debug use */
void show_status(int l, int r)
{
    uchar buf[BUFSIZE];

    fseek(Index, get_index_pointer(IndexIndex, l), 0);
    fgets(buf, BUFSIZE, Index);
    fprintf(stderr, "l:%d: %s", l, buf);
    fseek(Index, get_index_pointer(IndexIndex, r), 0);
    fgets(buf, BUFSIZE, Index);
    fprintf(stderr, "r:%d: %s", r, buf);
}

/* read 2 bytes as big endian */
#define big_endian_2byte(key) ((int)((*key << 8) | *(key + 1)))

/* get the left and right value of search range */
void lrget(uchar * key, int *l, int *r)
{
    int tmp;

    tmp = big_endian_2byte(key);
    *l = get_index_pointer(Hash, tmp);
    *r = get_index_pointer(Hash, ++tmp) - 1;
    if (*l > *r) {
	*r = *l;
    }

    if (Debug)
	show_status(*l, *r);
}

/* main routine of binary search */
int binsearch(uchar *orig_key, int forward_match_mode)
{
    int l, r, x, e = 0, i;
    uchar buf[BUFSIZE], key[BUFSIZE];

    strcpy(key, orig_key);
    lrget(key, &l, &r);

    if (forward_match_mode) {  /* truncate a '*' character at the end */
        *(lastc(key)) = '\0';
    }

    while (r >= l) {
	x = (l + r) / 2;

	fseek(Index, get_index_pointer(IndexIndex, x), 0);

	/* over BUFSIZE (maybe 1024) size keyword is nuisance */
	fgets(buf, BUFSIZE, Index);
	if (Debug)
	    fprintf(stderr, "searching: %s", buf);
	for (e = 0, i = 0; *(buf + i) != '\n' && *(key + i) != '\0' ; i++) {
	    if (*(buf + i) > *(key + i)) {
		e = -1;
		break;
	    }
	    if (*(buf + i) < *(key + i)) {
		e = 1;
		break;
	    }
	}

	if (*(buf + i) == '\n' && *(key + i)) {
	    e = 1;
	} else if (! forward_match_mode && *(buf + i) != '\n' 
                   && (!*(key + i))) {
	    e = -1;
	}

	/* if hit, return */
	if (!e)
	    return x;

	if (e < 0)
	    r = x - 1;
	else
	    l = x + 1;
    }
    return -1;
}

/* Forward match search */
HLIST forward_match(uchar * orig_key, int v)
{
    int i, j, n;
    HLIST tmp, val;
    uchar buf[BUFSIZE], key[BUFSIZE];
    val.n = 0;

    strcpy(key, orig_key);
    *(lastc(key))= '\0';
    n = strlen(key);

    for (i = v; i >= 0; i--) {
	fseek(Index, get_index_pointer(IndexIndex, i), 0);
	fgets(buf, BUFSIZE, Index);
	if (strncmp(key, buf, n))
	    break;
    }
    if (Debug)
	v = i;

    for (j = 0, i++;; i++, j++) {
	/* return if too much word would be hit
           because treat 'a*' completely is too consuming */
	if (j >= IGNORE_MATCH) {
	    free_hlist(val);
	    val.n = TOO_MUCH_MATCH;
	    break;
	}
	if (-1 == fseek(Index, get_index_pointer(IndexIndex, i), 0))
	    break;
	fgets(buf, BUFSIZE, Index);
        chop(buf);
	if (!strncmp(key, buf, n)) {
	    tmp = get_hlist(i);
	    if (tmp.n > IGNORE_HIT) {
		free_hlist(val);
		val.n = TOO_MUCH_MATCH;
		break;
	    }
	    val = ormerge(val, tmp);
	    if (val.n > IGNORE_HIT) {
		free_hlist(val);
		val.n = TOO_MUCH_MATCH;
		break;
	    }
	    if (Debug)
		fprintf(stderr, "fw: %s, %d, %d\n", buf, tmp.n, val.n);
	} else
	    break;
    }
    if (Debug)
	fprintf(stderr, "range: %d - %d\n", v + 1, i - 1);
    return val;
}

int is_field_safe_character(int c) {
    if ((isalnum(c) || c == (int)'-')) {
        return 1;
    } else {
        return 0;
    }

}
/* check a key if field or not */
int is_field(uchar *key)
{
    if (*key == '+') {
        key++;
    } else {
        return 0;
    }
    while (*key) {
        if (! is_field_safe_character(*key)) {
            break;
        }
        key++;
    }
    if (isalpha(*(key - 1)) && *key == ':' ) {
        return 1;
    }
    return 0;
}


#define NM 0
#define FW 1
#define RE 2
#define PH 3
#define FI 4

/* detect search mode */
int detect_search_mode(uchar *key) {
    if (strlen(key) <= 1)
        return NM;
    if (is_field(key)) { /* field search */
        if (Debug)
            fprintf(stderr, "do FIELD search\n");
        return FI;
    }
    if (*key == '/' && *(lastc(key)) == '/') {
        if (Debug)
            fprintf(stderr, "do REGEX search\n");
	return RE;    /* regex match */
    } else if (*key == '*' 
               && *(lastc(key)) == '*'
               && *(key + strlen(key) - 2) != '\\' ) 
    {
        if (Debug)
            fprintf(stderr, "do REGEX (INTERNAL_MATCH) search\n");
	return RE;    /* internal match search (treated as regex) */
    } else if (*(lastc(key)) == '*'
        && *(key + strlen(key) - 2) != '\\')
    {
        if (Debug)
            fprintf(stderr, "do FORWARD_MATCH search\n");
	return FW;    /* forward match search */
    } else if (*key == '*') {
        if (Debug)
            fprintf(stderr, "do REGEX (BACKWARD_MATCH) search\n");
	return RE;    /* backward match  (treated as regex)*/
    } else if ((*key == '"' && *(lastc(key)) == '"') 
          || (*key == '{' && *(lastc(key)) == '}')) 
    {
        /* remove the delimiter at begging and end of string */
        strcpy(key, key + 1); 
        *(lastc(key))= '\0';
    } 
    
    /* normal or phrase */

    /* if under Japanese mode, do wakatigaki */
    if (is_lang_ja(Lang)) {
        wakati(key);
    }

    if (strchr(key, '\t')) {
        if (Debug)
            fprintf(stderr, "do PHRASE search\n");
	return PH;
    } else {
        if (Debug)
            fprintf(stderr, "do WORD search\n");
        return NM;
    }
}

void print_hit_count (uchar *key, HLIST val)
{
    if (!HitCountOnly && !MoreShortFormat && !NoReference) {
        printf(" [ ");
        fputx(key, stdout);
        if (val.n > 0) {
            printf(": %d", val.n);
        } else { 
            uchar *msg = "";
            if (val.n == 0) {
                msg = ": 0 ";
            } else if (val.n == TOO_MUCH_MATCH) {
                msg = MSG_TOO_MUCH_MATCH;
            } else if (val.n == TOO_MUCH_HIT) {
                msg = MSG_TOO_MUCH_HIT;
            } else if (val.n == REGEX_SEARCH_FAILED) {
                msg = MSG_CANNOT_OPEN_REGEX_INDEX;
            } else if (val.n == FIELD_SEARCH_FAILED) {
                msg = MSG_CANNOT_OPEN_FIELD_INDEX;
            } else {
		msg = "unknown error";
	    }
            fputx(msg, stdout);
        }
        printf(" ] ");
    }
}

HLIST do_word_search(uchar *key, HLIST val)
{
    int v;

    if ((v = binsearch(key, 0)) != -1) {
        /* if found, get list */
        val = get_hlist(v);
    } else {
        val.n = 0;  /* no hit */
    }
    return val;
}

HLIST do_forward_match_search(uchar *key, HLIST val)
{
    int v;

    if ((v = binsearch(key, 1)) != -1) { /* 2nd argument must be 1  */
        /* if found, do foward match */
        val = forward_match(key, v);
    } else {
        val.n = 0;  /* no hit */
    }
    return val;
}


int issymbol(uchar c)  
{
    if (c < 0x80 && !isalnum(c)) {
        return 1;
    } else {
	return 0;
    }
}

/* calculate a value of phase hash */
int hash(uchar *str)
{
    extern int Seed[4][256];
    int hash = 0, i, j;

    for (i = j = 0; *str; i++) {
        if (!issymbol(*str)) { /* except symbol */
            hash ^= Seed[j % 4][(int)*str];
            j++;
        }
        str++;
    }
    return (hash & 65535);
}

/* get the phrase hash and compare it with HLIST */
HLIST compare_phrase_hash(int hash_key, HLIST val, 
                          FILE *phrase, FILE *phrase_index)
{
    int i, j, v, n, *list;
    long ptr;

    if (val.n == 0) {
        return val;
    }
    ptr = get_index_pointer(phrase_index, hash_key);
    if (ptr <= 0) {
        val.n = 0;
        return val;
    }
    fseek(phrase, ptr, 0);
    freadx(&n, sizeof(int), 1, phrase);
    list = (int *)malloc(n * sizeof(int));
    if (list == NULL) {
	 error("compare_phrase_hash_malloc");
    }

    freadx(list, sizeof(int), n, phrase);
    for (i = j = v = 0; i < n; i++) {
        for (; j < val.n && *(list + i) >= val.fid[j]; j++) {
            if (*(list + i) == val.fid[j]) {
                copy_hlist(val, v++, val, j);
            }
        }
    }
    val.n = v;
    free(list);
    return val;
}

int open_phrase_index_files(FILE **phrase, FILE **phrase_index)
{
    *phrase = fopen(PHRASE, "rb");
    if (*phrase == NULL) {
        return 1;
    }

    *phrase_index = fopen(PHRASEINDEX, "rb");
    if (*phrase_index == NULL) {
        return 1;
    }
    return 0;
}


/* phrase search */
HLIST do_phrase_search(uchar *key, HLIST val)
{
    int i, h = 0, ignore = 0, no_phrase_index = 0;
    uchar *p, *q, *word_b = 0, word_mix[BUFSIZE];
    FILE *phrase, *phrase_index;

    p = key;
    if (strchr(p, '\t') == NULL) {  /* if only one word */
        val = do_word_search(p, val);
        return val;
    }

    if (open_phrase_index_files(&phrase, &phrase_index)) {
/*        fputx(MSG_CANNOT_OPEN_PHRASE_INDEX, stdout); */
	no_phrase_index = 1;
    }
        
    if (!HitCountOnly && !MoreShortFormat && !NoReference) {
        printf(" { ");
    }
    while (*p == '\t') {  /* beggining tabs are skipped */
        p++;
    }
    for (i = 0; ;i++) {
        q = strchr(p, '\t');
        if (q) 
            *q = '\0';
        if (strlen(p) > 0) {
            HLIST tmp;

            tmp = do_word_search(p, val);
            print_hit_count(p, tmp);

            if (i == 0) {
                val = tmp;
            } else {
                val = andmerge(val, tmp, &ignore);
            }
	    if (!no_phrase_index) {
		if (i != 0) {
		    strcpy(word_mix, word_b);
		    strcat(word_mix, p);
		    h = hash(word_mix);
		    val = compare_phrase_hash(h, val, phrase, phrase_index);
		    if (Debug) {
			fprintf(stderr, "\nhash:: <%s, %s>: h:%d, val.n:%d\n",
				word_b, p, h, val.n);
		    }
		}
		word_b = p;
	    }
        }
        if (q == NULL)
            break;
        p = q + 1;
    }
    if (!HitCountOnly && !MoreShortFormat && !NoReference) {
        printf(" :: %d } ", val.n);
    }

    if (!no_phrase_index) {
	fclose(phrase);
	fclose(phrase_index);
    }
    return val;
}

#define iseuc(c)  ((c) >= 0xa1 && (c) <= 0xfe)
void do_regex_preprocessing(uchar *expr)
{
    if (*expr == '*' && *(lastc(expr)) != '*') {
        /* if backward match such as '*bar', enforce it into regex */
        strcpy(expr, expr + 1);
        strcat(expr, "$");
    } else if (*expr != '*' && *(lastc(expr)) == '*') {
        /* if forward match such as 'bar*', enforce it into regex */
        *(lastc(expr)) = '.';
        strcat(expr, "*");
    } else if (*expr == '*' && *(lastc(expr)) == '*') {
        /* if internal match such as '*foo*', enforce it into regex */
        strcpy(expr, expr + 1);
        *(lastc(expr)) = '\0';
    } else if (*expr == '/' && *(lastc(expr)) == '/') {
        /* genuine regex */
        /* remove the both of '/' chars at begging and end of string */
        strcpy(expr, expr + 1); 
        *(lastc(expr))= '\0';
        return;
    } else {
        uchar buf[BUFSIZE * 2], *bufp, *exprp;

        if ((*expr == '"' && *(lastc(expr)) == '"')
            || (*expr == '{' && *(lastc(expr)) == '}')) {
            /* delimiters of field search */
            strcpy(expr, expr + 1); 
            *(lastc(expr))= '\0';
        }
        bufp = buf;
        exprp = expr;
        /* escape meta characters */
        while (*exprp) {
            if (!isalnum(*exprp) && !iseuc(*exprp)) {
                *bufp = '\\';
                bufp++;
            }
            *bufp = *exprp;
            bufp++;
            exprp++;
        }
        *bufp = '\0';
        strcpy(expr, buf);
    }
}

HLIST do_regex_search(uchar *orig_expr, HLIST val)
{
    FILE *fp;
    uchar expr[BUFSIZE * 2]; /* because of escaping meta characters */

    strcpy(expr, orig_expr);
    do_regex_preprocessing(expr);

    fp = fopen(WORDLIST, "rb");
    if (fp == NULL) {
        fprintf(stderr, "%s: cannot open file.\n", WORDLIST);
        val.n = REGEX_SEARCH_FAILED;  /* cannot open regex index */
        return val;
    }
    val = regex_grep(expr, fp, "", 0);
    fclose(fp);
    return val;

}

void get_field_name(uchar *field, uchar *str)
{
    uchar *tmp = field;

    str++;  /* ignore beggining '+' mark */
    while (*str) {
        if (! is_field_safe_character(*str)) {
            break;
        }
        *tmp = *str;
        tmp++;
        str++;
    }
    *tmp = '\0';

    if (strcmp(field, "title") == 0) {
        strcpy(field, "subject");
    } else if (strcmp(field, "author") == 0) {
        strcpy(field, "from");
    } else if (strcmp(field, "path") == 0) {
        strcpy(field, "url");
    } 
}

void get_expr(uchar *expr, uchar *str)
{
    str = strchr(str, (int)':') + 1;
    strcpy(expr, str);
}

HLIST do_field_search(uchar *str, HLIST val)
{
    uchar expr[BUFSIZE * 2], /* because of escaping meta characters */
        field_name[BUFSIZE], file_name[BUFSIZE];
    FILE *fp;

    get_field_name(field_name, str);
    get_expr(expr, str);
    do_regex_preprocessing(expr);

    strcpy(file_name, FIELDINFO); /* make pathname */
    strcat(file_name, field_name);

    fp = fopen(file_name, "rb");
    if (fp == NULL) {
        fprintf(stderr, "%s: cannot open file.\n", file_name);
        val.n = FIELD_SEARCH_FAILED;  /* cannot open field index */
        return val;
    }
    val = regex_grep(expr, fp, field_name, 1); /* last argument must be 1 */
    fclose(fp);
    return val;
}

void delete_beginning_backslash(uchar *str)
{
    if (*str == '\\') {
        strcpy(str, str + 1);
    }
}

HLIST do_search(uchar *orig_key, HLIST val)
{
    int mode;
    uchar key[BUFSIZE];

    strcpy(key, orig_key);
    tolower_string(key);
    mode = detect_search_mode(key);
    delete_beginning_backslash(key);

    if (mode == FW) {
        val = do_forward_match_search(key, val);
    } else  if (mode == RE) {
        val = do_regex_search(key, val);
    } else if (mode == PH) {
        val = do_phrase_search(key, val);
    } else if (mode == FI) {
        val = do_field_search(key, val);
    } else {
        val = do_word_search(key, val);
    }

    if (mode != PH) { /* phrase mode print status by itself */
        print_hit_count(orig_key, val);
    }
    return val;
}


/* check the existence of lockfile */
int check_lockfile(void)
{
    FILE *lock;

    if ((lock = fopen(LOCKFILE, "rb"))) {
	fclose(lock);
        printf("(now be in system maintenance)");
        return 1;
    }
    return 0;
}


/* checking byte order */
void check_byte_order(void)
{
    int  n = 1;
    char *c;
    FILE *fp;
    
    OppositeEndian = 0;
    c = (char *)&n;
    if (*c) { /* little-endian */
        if ((fp = fopen(BIGENDIAN, "rb"))) {
            OppositeEndian = 1;
            fclose(fp);
        }
    } else { /* big-endian */
        if ((fp = fopen(LITTLEENDIAN, "rb"))) {
            OppositeEndian = 1;
            fclose(fp);
        }
    }
    if (Debug && OppositeEndian)
        fprintf(stderr, "OppositeEndian mode\n");
}

/* opening files at once */
int open_index_files()
{
    if (check_lockfile())
        return 1;
    check_byte_order();
    Index = fopen(INDEX, "rb");
    if (Index == NULL) {
	return 1;
    }
    IndexIndex = fopen(INDEXINDEX, "rb");
    if (IndexIndex == NULL) {
	return 1;
    }
    Hash = fopen(HASH, "rb");
    if (Hash == NULL) {
	return 1;
    }
    return 0;
}

/* closing files at once */
void close_index_files(void)
{
    fclose(Index);
    fclose(IndexIndex);
    fclose(Hash);
}


/* flow of displaying search results */
void print_result1(void)
{
    fputx(MSG_RESULT_HEADER, stdout);

    if (HtmlOutput)
	fputs("<P>\n", stdout);
    else
	fputc('\n', stdout);
    fputx(MSG_REFERENCE_HEADER, stdout);
    if (DbNumber > 1 && HtmlOutput)
	fputs("</P>\n", stdout);
}

void print_result2(void)
{
    if (DbNumber == 1 && HtmlOutput)
	printf("\n</P>\n");
    else
	fputc('\n', stdout);
}

void print_result3(int n)
{
    fputx(MSG_HIT_1, stdout);
    if (HtmlOutput)
        printf("<!-- HIT -->%d<!-- HIT -->", n);
    else
        printf("%d", n);
    fputx(MSG_HIT_2, stdout);
}

void print_result4(HLIST hlist)
{
    if (HtmlOutput)
        printf("<DL>\n");
    
    put_hlist(hlist);
    
    if (HtmlOutput)
        printf("</DL>\n");

}

void print_result5(HLIST hlist)
{
    if (HtmlOutput)
        printf("<P>\n");
    put_current_extent(hlist.n);
    if (!HidePageIndex)
        put_page_index(hlist.n);
    if (HtmlOutput)
        printf("</P>\n");
    else
        printf("\n");
}

/* get tfidf's N */
int get_N (void) {
    struct stat st;

    stat(FLISTINDEX, &st);
    if (Debug)
        fprintf(stderr, "size of %s: %d\n", FLISTINDEX, (int)st.st_size);
    return ((int)(st.st_size) / 4);
}

char *get_env_safely(char *s)
{
    char *cp;
    return (cp = getenv(s)) ? cp : "";
}


/* do logging, separated with TAB characters 
   it does not consider a LOCK mechanism!
*/
void do_logging(uchar * query, int n)
{
    FILE *slog;
    char *rhost;
    char *time_string;
    time_t t;

    t = time(&t);
    time_string = ctime(&t);

    slog = fopen(SLOG, "a");
    if (slog == NULL) {
        if (Debug)
            fprintf(stderr, "NMZ.slog: Permission denied\n");
	return;
    }
    rhost = get_env_safely("REMOTE_HOST");
    if (!*rhost)
	rhost = get_env_safely("REMOTE_ADDR");
    if (!*rhost)
	rhost = "LOCALHOST";
    fprintf(slog, "%s\t%d\t%s\t%s", query, n, rhost, time_string);

    fclose(slog);
}


char *get_dir_name(char *path)
{
    char *p;

    p = strrchr(path, '/');
    if (p) {
        return (p + 1);
    } else {
        return path;
    }
}

HLIST search_and_print_reference(HLIST hlist, uchar *query,
                                 uchar *query_orig, int n)
{
    if (!HitCountOnly && !MoreShortFormat && !NoReference) {
        if (DbNumber > 1) {
            if (HtmlOutput)
                printf("<LI><STRONG>%s</STRONG>: ", get_dir_name(DbNames[n]));
            else
                printf("(%s)", DbNames[n]);
        }
    }

    if (open_index_files()) {
        /* if open failed */
        hlist.n = 0;
        fputx(MSG_CANNOT_OPEN_INDEX, stdout);
        return hlist;
    }

    /* if query contains only one keyword, TfIdf mode will be off */
    if (KeyItem[1] == NULL && strchr(KeyItem[0], '\t') == NULL)
        TfIdf = 0;
    if (TfIdf) {
        AllDocumentN = get_N();
    }

    /* search */
    initialize_parser();
    hlist = expr();

    if (hlist.n) /* if hit */
        set_did_hlist(hlist, n);
    if (!HitCountOnly && !MoreShortFormat && !NoReference) {
        if (DbNumber > 1 && KeyItem[1]) {
            printf(" [ TOTAL: %d ]", hlist.n);
        }
        printf("\n");
    }
    close_index_files();

    if (Logging) {
        do_logging(query_orig, hlist.n);
    }
    return hlist;
}

void make_fullpathname_index(int n)
{
    uchar *base;

    base = DbNames[n];

    pathcat(base, INDEX);
    pathcat(base, INDEXINDEX);
    pathcat(base, FLISTINDEX);
    pathcat(base, HASH);
    pathcat(base, BIGENDIAN);
    pathcat(base, LITTLEENDIAN);
    pathcat(base, WORDLIST);
    pathcat(base, PHRASE);
    pathcat(base, PHRASEINDEX);
    pathcat(base, LOCKFILE);
    pathcat(base, SLOG);
    pathcat(base, FIELDINFO);
    pathcat(base, DATEINDEX);
}


/* flow of search */
void search_main(uchar *query)
{
    HLIST hlist, tmp[DB_MAX];
    uchar query_orig[BUFSIZE];
    int i;

    strcpy(query_orig, query); /* save */
    split_query(query);

    if (!HitCountOnly && !MoreShortFormat && !NoReference) {
        print_result1();

        if (DbNumber > 1) {
            printf("\n");
            if (HtmlOutput)
                printf("<UL>\n");
        }
    }
    for (i = 0; i < DbNumber; i++) {
        make_fullpathname_index(i);
        tmp[i] = search_and_print_reference(tmp[i], query, 
                                            query_orig, i);
    }
    if (!HitCountOnly && !MoreShortFormat && !NoReference) {
        if (DbNumber > 1 && HtmlOutput) {
            printf("</UL>\n");
        }
        print_result2();
    }

    hlist = merge_hlist(tmp);
    if (hlist.n > 0) {
        reverse_hlist(hlist);
        sort_hlist(hlist, "date");  /* sort by date */
        if (! LaterOrder) {  /* early order */
            reverse_hlist(hlist);
        }
        if (ScoreSort) {
            sort_hlist(hlist, "score"); /* sort by score */
        }
        if (!HitCountOnly && !MoreShortFormat) {
            print_result3(hlist.n);
        }
        print_result4(hlist); /* summary listing */
        if (!HitCountOnly && !MoreShortFormat) {
            print_result5(hlist);
        }
    } else {
        if (HitCountOnly) {
            printf("0\n");
        } else if (!MoreShortFormat) {
            fputx(MSG_NO_HIT, stdout);
        }
    }
    free_hlist(hlist);
}




