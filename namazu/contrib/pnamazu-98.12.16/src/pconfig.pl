#-------------------------- 'configuration' --------------------------
# namazu.conf ��̵���ѥ�᡼�������ꡢ����� perl ����ͭ������

# ����ǥ��������ȡ������ǻȤ��ޥ��󤬰㤦��硢�����������
# �ѹ�����ɬ�פ������ǽ��������Τǡ���ǧ���뤳�ȡ�
# �����Ǥϡ�mknmz ��¹Ԥ����ޥ���Ǥ������Υ����פ˹�碌��

# big endian, 32bit             -> 'N'
# big endian, 16bit             -> 'n'
# little endian, 32bit          -> 'V'
# little endian, 16bit          -> 'v'
# �嵭�˴ط��ʤ� mknmz ��Ʊ��   -> 'I'

$IntType = '';

# �ǡ����١����� gzip �ǰ��̤������Ρ�zcat ������
#   �ǡ����١����ե�����Τ��������� 5 �Ĥγ�ĥ�ҤΤ�Τϡ�
#   gzip �ˤ�밵�̥ե��������ѤǤ��롣
#       �󰵽̻�    ���̻�
#       .h          .h.gz  �ޤ��� .hz
#       .ii         .ii.gz �ޤ��� .iiz
#       .i          .i.gz  �ޤ��� .iz
#       .fi         .fi.gz �ޤ��� .fiz
#       .f          .f.gz  �ޤ��� .fz
#   5 �������ǤϤʤ������������򰵽̤����֤����Ȥ��ǽ
#   ���̥ե����뤬̵����С���ưŪ���󰵽̥ե�������ɤ�

$Zcat = '/usr/local/bin/gzip -dc';
#$Zcat = '';                     # ����̵��
#$Zcat = '/usr/local/bin/zcat';

# zcat ��Ȥ����ˡ������Фؤ���ô��ڸ����뤿�ᡢpriority �򲼤���
$ZcatPri = 10;

# ����ν���� (���ޥ�ɥ饤�󥪥ץ���󡢴Ķ��ѿ� QUERY_STRING �ˤ���ѹ���ǽ)
$Max = 10;
$Whence = 0;
$DbName = 'NMZ';
$Format = 'long';
$Sort = "score";

# $NamazuDir = "/usr/local/namazu";"

# Zcat ��Ȥ��Ȥ��ˤϡ�ScriptName �򤭤�������ꤷ�Ƥ������Ȥ�˾�ޤ���
$ScriptName = '';

# namazu.conf �λ���
$NamazuConf = '';


# renice �λ��ꡢ�Ť������ˤʤä��Ȥ��ˡ������Ф���ô��������Τ��ɤ�
# ���ᡢ������֤��вᤷ���顢priority �򲼤��롣CGI �ΤȤ�����ͭ��

# renice ���¹Ԥ����ޤǤλ��֤ȼ¹Ը�� priority �����ꡣ�ɤ����
# ���ο��Ǥʤ��ȡ���ǽ�ϼ¹Ԥ���ʤ���
$ReniceTime = 0;
$RenicePri = 10;

# cmdline ���� argv �ν��֤λ��� 'new' �ˤ���ȡ�'key string' [index dir]
# �ν硢'old' �ˤ���ȡ�[index dir] 'key string' �ν�
$CmdLineArg = 'new';

# ¾�Υޥ���ظ�����̤�ʹ���˹Ԥ���ǽ��ͭ���ˤ��뤫�ɤ�����1 ��ͭ����
$RemoteEnable = 0;

# database ����̾�ꥹ�ȡ���ˡ�remote �� 'http://' �ǻϤޤ�̾����������
# ����̵�����˻Ȥ���
# %DbAlias = ('foo' => 'http://hogehoge'); �Τ褦�˻���
%DbAlias = ();

# ͭ���� database ̾�Υꥹ�ȡ�
# ���Υꥹ�Ȥ����Ǥʤ���硢�ꥹ�Ȥˤ����ΰʳ��ϻȤ��ʤ��ʤ롣
@DbEnable = ();

# ������ text �θ������ν���ͤȤ��ơ�
# 1 ... ���Ϥ򤽤Τޤ��֤�
# 0 ... �狼���񤭤ʤɤν������ʸ�����Ȥ�
$RespTextOrig = 0;

# ʸ���¸�ߤ���ǥ��쥯�ȥ�ˤ��󥯤���
$SplitLink = 0;
1;
#---------------------- End of 'configuration' -----------------------
