#!/bin/sh
WAKE=/home/swirhen/sh/tigkw.sh
BORDER=15
PID=`cat /home/swirhen/tig.pid`
MEM=`ps u $PID | grep $PID | awk '{print $4}' | cut -d"." -f1` #;echo $MEM
# MEM使用率がしきい値を越えていた場合、上げ直す
if [ `expr $MEM` -gt $BORDER ] ; then
  $WAKE;exit
fi
