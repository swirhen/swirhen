#!/bin/sh
WAKE=/home/swirhen/sh/tigkw.sh
BORDER=15
PID=`cat /home/swirhen/tig.pid`
MEM=`ps u $PID | grep $PID | awk '{print $4}' | cut -d"." -f1` #;echo $MEM
# MEM�g�p�����������l���z���Ă����ꍇ�A�グ����
if [ `expr $MEM` -gt $BORDER ] ; then
  $WAKE;exit
fi
