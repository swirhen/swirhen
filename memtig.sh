#!/bin/sh
WAKE=/home/swirhen/sh/tigkw.sh
BORDER=15
PID=`cat /home/swirhen/tig.pid`
MEM=`ps u $PID | grep $PID | awk '{print $4}' | cut -d"." -f1` #;echo $MEM
# MEM$B;HMQN($,$7$-$$CM$r1[$($F$$$?>l9g!">e$2D>$9(B
if [ `expr $MEM` -gt $BORDER ] ; then
  $WAKE;exit
fi
