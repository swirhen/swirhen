#!/bin/sh
WAKE=$1    # �v���Z�X�������̓R�}���h�̖��O ex)TwitterircgatewayCLI
NAME=$2    # �ċN������V�F�� ex)/home/swirhen/tigkw.sh ���W���o�͎͂̂Ă邱��
BORDER=$3            # MEM�������l
if [ $# -eq 3 ]; then
  MEM=`ps u | grep $NAME | grep -v grep | grep -v $0 | awk '{print $4}' | cut -d"." -f1` ;echo $MEM
  MEM=`echo $MEM | cut -d" " -f1` ;echo $MEM #2�ȏ㌩�������ꍇ��1�ڂŌ��߂����Ώ��B�D�L��...
  # MEM�g�p�����������l���z���Ă����ꍇ�A�グ����
  if [ `expr $MEM` -gt $BORDER ] ; then
    $WAKE;exit
  fi
fi
