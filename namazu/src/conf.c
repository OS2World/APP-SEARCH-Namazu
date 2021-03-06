/*
 * 
 * conf.c -
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
#include "namazu.h"
#include "util.h"

void show_configuration()
{
    printf("namazu configurations\n");
    if (ConfLoaded)
	printf("configuration file: %s\n", NAMAZU_CONF);

    printf("\
  * DEFAULT_DIR      : %s\n\
  * BASE_URL         : %s\n\
  * URL_REPLACE_FROM : %s\n\
  * URL_REPLACE_TO   : %s\n\
  * LOGGING          : %s\n\
  * LANGUAGE         : %s\n\
  * SCORING          : %s\n\
", DEFAULT_DIR, BASE_URL, URL_REPLACE_FROM[0],
	 URL_REPLACE_TO[0], Logging ? "ON" : "OFF",
           Lang, TfIdf ? "TFIDF" : "SIMPLE");
    exit(0);
}


/* change filename in full pathname */
void set_pathname(char *to, char *o, char *name)
{
    int i;

    strcpy(to, o);
    for (i = strlen(to) - 1; i > 0; i--) {
	if (to[i] == '/') {
	    i++;
	    break;
	}
    }
    strcpy(to + i, name);
    return;
}

/*
 1. current_executing_binary_dir/.namazurc
 2. ${HOME}/.namazurc
 3. lib/namazu.conf
 */
FILE *open_conf_file(char *av0)
{
    FILE *fp;
    char fname[BUFSIZE], *home;

    /* be invoked with -f option to specify rcfile */
    if (NAMAZURC[0]) {
        if ((fp = fopen(NAMAZURC, "rb"))) {
            strcpy(NAMAZU_CONF, NAMAZURC);
            return fp;
        }
    }

    /* check the where program is */
    set_pathname(fname, av0, ".namazurc");
    if ((fp = fopen(fname, "rb"))) {
        strcpy(NAMAZU_CONF, fname);
        return fp;
    }

    /* checke a home directory */
    if ((home = getenv("HOME"))) {
        strcpy(fname, home);
        strcat(fname, "/.namazurc");
        if ((fp = fopen(fname, "rb"))) {
            strcpy(NAMAZU_CONF, fname);
            return fp;
        }
    }

    /* check the defalut */
    if ((fp = fopen(NAMAZU_CONF, "rb"))) {
        return fp;
    }
    return (FILE *) NULL;
}

/* loading configuration file of Namazu */
void load_namazu_conf(char *av0)
{
    FILE *fp;
    uchar buf[BUFSIZE];
    int n, i;

#ifdef NOCONF
    return;
#endif

    /* I don't know why but GNU-Win32 require this */
    BASE_URL[0] = '\0';
    URL_REPLACE_FROM[url_no][0] = '\0';
    URL_REPLACE_TO[url_no][0] = '\0';

    fp = open_conf_file(av0);
    if (fp == NULL)
	return;
    ConfLoaded = 1;
    while (fgets(buf, BUFSIZE, fp)) {
	chop(buf);
	if (!strncmp(buf, "INDEX\t", 6)) {
	    for (n = 6; buf[n] == '\t'; n++);
	    strcpy(DEFAULT_DIR, buf + n);
	} else if (!strncmp(buf, "BASE\t", 5)) {
	    for (n = 5; buf[n] == '\t'; n++);
	    strcpy(BASE_URL, buf + n);
	} else if (!strncmp(buf, "REPLACE\t", 8)) {
	    for (n = 8; buf[n] == '\t'; n++);
	    for (i = 0; buf[n] != '\t' && buf[n]; n++, i++)
		URL_REPLACE_FROM[url_no][i] = buf[n];
	    URL_REPLACE_FROM[url_no][i] = '\0';
	    for (; buf[n] == '\t'; n++);
	    strcpy(URL_REPLACE_TO[url_no], buf + n);
	    url_no++;
	} else if (!strncmp(buf, "LOGGING\t", 8)) {
	    for (n = 8; buf[n] == '\t'; n++);
	    if (!strncmp(&buf[n], "OFF", 3))
		Logging = 0;
	} else if (!strncmp(buf, "SCORING\t", 8)) {
	    for (n = 8; buf[n] == '\t'; n++);
	    if (!strncmp(&buf[n], "TFIDF", 5))
		TfIdf = 1;
	    if (!strncmp(&buf[n], "SIMPLE", 6))
		TfIdf = 0;
	} else if (!strncmp(buf, "LANG\t", 5)) {
	    for (n = 5; buf[n] == '\t'; n++);
	    strncpy(Lang, &buf[n], 2);
            initialize_message();
	}
    }
    fclose(fp);
}
