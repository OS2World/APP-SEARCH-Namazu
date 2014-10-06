#--------------------- 'load namazu.conf' Module ---------------------
sub load_namazu_conf{
    my($env, $conf);

    if (($env = $ENV{'NAMAZUCONFPATH'}) && open(FH, $conf = $env)
        or ($env = $ENV{'NAMAZUCONF'}) && open(FH, $conf = $env)
        or (open(FH, $conf = '.namazurc') || open(FH, $conf = 'namazu.conf'))
        or $ScriptDir && (open(FH, $conf = "$ScriptDir/.namazurc") ||
                          open(FH, $conf = "$ScriptDir/namazu.conf"))
        or ($env = $ENV{'HOME'}) && (open(FH, $conf = "$env/.namazurc") ||
                                     open(FH, $conf = "$env/namazu.conf"))
        or ($NamazuConf && open(FH, $conf = $NamazuConf))
        or $NamazuDir and (open(FH, $conf = "$NamazuDir/namazu.conf") ||
                           open(FH, $conf = "$NamazuDir/lib/namazu.conf"))
        ){
        $NamazuConf = $conf;

        while(<FH>){
            next if /^# /;
            $DEFAULT_DIR      = $2 if /^(INDEX|DEFAULT_DIR)\s+(\S+)/i;
            $BASE_URL         = $1 if /^BASE_URL\s+(\S+)/i;
            $URL_REPLACE_FROM = $1, $URL_REPLACE_TO = $2 if /^REPLACE\s+(\S+)\s+(\S+)/i;
            $URL_REPLACE_FROM = $1 if /^URL_REPLACE_FROM\s+(\S+)/i;
            $URL_REPLACE_TO   = $1 if /^URL_REPLACE_TO\s+(\S+)/i;
            $WAKATI           = $2 if /^(wakachi|wakati)\s+(\S+)/i;
            $LOGGING          = $1 if /^LOGGING\s+(\S+)/i;
            $LANGUAGE         = $1 if /^LANGUAGE\s+(\S+)/i;
            $SCORING          = $1 if /^SCORING\s+(\S+)/i;
        }
        $LOGGING = 0 if $LOGGING =~ /^off$/i;
        $LANGUAGE = "ja" if($LANGUAGE =~ /JAPANESE/i);
        $LANGUAGE = "en" if($LANGUAGE =~ /ENGLISH/i);
        $ReplaceFrom = quotemeta($URL_REPLACE_FROM);
        $ReplaceTo = $URL_REPLACE_TO;
        close(FH);
    }
}
1;
#----------------- End of 'load namazu.conf' Module ------------------
