#!/bin/sh
WAKE=$1    # �ċN������V�F���̈ʒu ex)/home/swirhen/sh/tiarraup.sh
NAME=$2    # �`�F�b�N����v���Z�X�̖��O ex)tiarra
if [ $# -eq 2 ]; then  # ������2�Ȃ�������I��
  CHK=`ps -eo comm,cmd | grep $NAME | grep -v grep | grep -v $0` #;echo $CHK
  # �オ���ĂȂ���Ώグ����
  if [ "${CHK:-null}" = null ] ; then
    $WAKE
  fi
fi
