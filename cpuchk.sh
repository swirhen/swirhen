#!/bin/sh
WAKE=$1    # �v���Z�X�������̓R�}���h�̖��O ex)TwitterircgatewayCLI
NAME=$2    # �ċN������V�F�� ex)/home/swirhen/tigkw.sh ���W���o�͎͂̂Ă邱��
BORDER=$3            # CPU�������l
ROOT=/home/swirhen/  # �t�@�C�������f�B���N�g��
CPU=$ROOT$NAME.cpu   # CPU�g�p�����L�^���Ă����t�@�C��
if [ $# -eq 3 ]; then
  #PID=`ps -eo pid,comm,cmd | grep $NAME | grep -v grep | grep -v $0 | sed "s/^\s*//" | cut -d" " -f1` #;echo $PID
  #PID=`echo $PID | cut -d" " -f1` ;echo $PID #2�ȏ㌩�������ꍇ��1�ڂŌ��߂����Ώ��B�D�L��...
  PID=`pgrep -f -o  $NAME` ;echo $PID
  # �オ���ĂȂ���Ώグ����
  if [ ${PID:-null} = null ] ; then
    $WAKE;exit
  fi
  NOW=`top -n 1 -b | egrep "^\s*$PID" | awk '{print $9}'` ;echo $NOW
  if [ -f $CPU ] ; then
    OLD=`cat $CPU` ;echo $OLD
    # CPU�g�p�����A���ł������l���z���Ă����ꍇ�A�グ����
    if [ `expr $OLD` -gt $BORDER -a `expr $NOW` -gt $BORDER ] ; then
      $WAKE;exit
    else
      echo $NOW > $CPU # ���݂̒l�ɏ���������
    fi
  else
    echo $NOW > $CPU # �オ���Ă邯�ǃt�@�C�������݂��ĂȂ������ꍇ
  fi
fi
