#!/bin/sh
WAKE=$1    # $B%W%m%;%9$b$7$/$O%3%^%s%I$NL>A0(B ex)TwitterircgatewayCLI
NAME=$2    # $B:F5/F0$9$k%7%'%k(B ex)/home/swirhen/tigkw.sh $B"(I8=`=PNO$O<N$F$k$3$H(B
BORDER=$3            # CPU$B$7$-$$CM(B
ROOT=/home/swirhen/  # $B%U%!%$%k$r:n$k%G%#%l%/%H%j(B
CPU=$ROOT$NAME.cpu   # CPU$B;HMQN($r5-O?$7$F$*$/%U%!%$%k(B
if [ $# -eq 3 ]; then
  #PID=`ps -eo pid,comm,cmd | grep $NAME | grep -v grep | grep -v $0 | sed "s/^\s*//" | cut -d" " -f1` #;echo $PID
  #PID=`echo $PID | cut -d" " -f1` ;echo $PID #2$B8D0J>e8+$D$+$C$?>l9g$O(B1$B8DL\$G7h$a$&$ABP=h!#E%=-$$(B...
  PID=`pgrep -f -o  $NAME` ;echo $PID
  # $B>e$,$C$F$J$1$l$P>e$2D>$9(B
  if [ ${PID:-null} = null ] ; then
    $WAKE;exit
  fi
  NOW=`top -n 1 -b | egrep "^\s*$PID" | awk '{print $9}'` ;echo $NOW
  if [ -f $CPU ] ; then
    OLD=`cat $CPU` ;echo $OLD
    # CPU$B;HMQN($,O"B3$G$7$-$$CM$r1[$($F$$$?>l9g!">e$2D>$9(B
    if [ `expr $OLD` -gt $BORDER -a `expr $NOW` -gt $BORDER ] ; then
      $WAKE;exit
    else
      echo $NOW > $CPU # $B8=:_$NCM$K=q$-49$($k(B
    fi
  else
    echo $NOW > $CPU # $B>e$,$C$F$k$1$I%U%!%$%k$,B8:_$7$F$J$+$C$?>l9g(B
  fi
fi
