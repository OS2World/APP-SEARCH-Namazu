#!/usr/local/bin/perl
# diag.cgi - by furukawa@dkv.yamaha.co.jp

print "Content-Type: text/plain\n\n";

select(STDERR); $| = 1;
select(STDOUT); $| = 1;

open(STDERR, ">&STDOUT");

print "OSNAME: $^O\n";

print "PERL_VERSION: $]\n";
foreach $_ ('N', 'n', 'V', 'v'){
    printf("Integer ($_): %s Endian, %d bit\n", ('Big', 'Little')[/[Vv]/],
           (16, 32)[/[VN]/]) if pack('I', 0x12345678) eq pack($_, 0x12345678);
}
printf("'cmp' is %s.\n\n", ('a' cmp "\xa1") < 0? 'unsigned': 'signed');

print "EXECUTABLE_NAME: $^X\n";
print "\$0: $0\n";
chop, print "$_\n" if open(fH, $0) && ($_ = <fH>) =~ /^#\!/;
print "\n";

print "uid=$<, gid=$(\n";
print "login:" . getlogin . "\n";
print "pwuid:" . eval{(getpwuid($<))[0]} . "\n";
print "grgid:" . eval{(getgrgid($())[0]} . "\n";
print "\n";

if ($^O =~ /ms(win|dos)/i){
    @EXT = ('.com', '.exe');
    @PATH = split(';', $ENV{'PATH'});
}else{
    local($_, @tmp);
    @PATH = split(':', $ENV{'PATH'});
    push(@PATH, '/usr/local/bin') if !grep(/\/usr\/local\/bin/, @PATH);

    &diag('', 'uname', '-mrs', @PATH);
    &diag('', 'arch', '-k', @PATH);
    &diag('', 'mach', '', @PATH);
    &diag('', 'sysctl', 'hw.machine_arch', @PATH);
    &diag('', 'sysctl', 'hw.model', @PATH);
    print "\n";
}

&hr;

for (sort keys(%ENV)){print "$_=$ENV{$_}\n";}

close(STDIN);
&diag("\n", 'perl', '-v', @PATH);
&diag("\n", 'perl5', '-v', @PATH);
&diag("\n", 'gcc', '-v', @PATH);
&diag("\n", 'gzip', '-h', @PATH);
&diag("\n", 'zcat', '-h', @PATH);
&diag("\n", 'nkf', '-v', @PATH);
&diag("\n", 'nkf32', '-v', @PATH);
&diag("\n", 'kakasi', '-v', @PATH);
&diag("\n", 'namazu', '-v', @PATH);

sub modestr{
    local($_) = @_;
    local(%tmp) = (4, 'd', 6, 'b', 2, 'c', 10, 'l', 1, 'p', 12, 's');
    local(@tmp) = ('---', '--x', '-w-', '-wx', 'r--', 'r-x', 'rw-', 'rwx');
    local($ret) = $tmp[$_ & 7];
    $ret =~ s/x/t/ || $ret =~ s/-$/T/ if $_ & 01000;
    $_ >>= 3;

    local($tmp) = $tmp[$_ & 7];
    $tmp =~ s/x/s/ || $tmp =~ s/-$/S/ if $_ & 00200;
    $ret = $tmp . $ret;
    $_ >>= 3;
    
    $tmp = $tmp[$_ & 7];
    $tmp =~ s/x/s/ || $tmp =~ s/-$/S/ if $_ & 00040;
    $ret = $tmp . $ret;
    $_ >>= 6;

    ($tmp{$_} || '-') . $ret;
}

sub diag{
    local($flag, $prog, $opt, @path) = @_;
    for $path (@path){
        $path .= '/' if $path !~ /\/$/;

        for $ext ('', @EXT){
            local($file) = $path . $prog . $ext;
            if (-x $file){
                &hr if $flag;
                print "$prog ($file";
                print " -> " . readlink($file) if -l $file;
                print "): $flag";

                if ($flag){
                    local($dev, $ino, $mode, $nlink, $uid, $gid,
                       $rdev, $size, $atime, $mtime) = stat($file);

                    local($tim_str);
                    $tim_str = localtime($mtime);
                    $tim_str =~ s/^\S\S\S //;
                    $tim_str =~ s/\d\d:\d\d:\d\d //;

                    $uid = eval{(getpwuid($uid))[0]} || $uid;
                    $gid = eval{(getgrgid($gid))[0]} || $gid;

                    print &modestr($mode);
                    printf(" %-8s %-8s %8d %s %s\n",
                           $uid, $gid, $size, $tim_str, $file);
                }
                system("$file $opt");
                return if !$flag;
            }
        }
    }
}

sub hr{print "-" x 70 . "\n";}
