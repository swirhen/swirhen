#!/bin/sh
WAKE=$1    # $B%W%m%;%9$b$7$/$O%3%^%s%I$NL>A0(B ex)TwitterircgatewayCLI
NAME=$2    # $B:F5/F0$9$k%7%'%k(B ex)/home/swirhen/tigkw.sh $B"(I8=`=PNO$O<N$F$k$3$H(B
BORDER=$3            # MEM$B$7$-$$CM(B
if [ $# -eq 3 ]; then
  MEM=`ps u | grep $NAME | grep -v grep | grep -v $0 | awk '{print $4}' | cut -d"." -f1` ;echo $MEM
  MEM=`echo $MEM | cut -d" " -f1` ;echo $MEM #2$B8D0J>e8+$D$+$C$?>l9g$O(B1$B8DL\$G7h$a$&$ABP=h!#E%=-$$(B...
  # MEM$B;HMQN($,$7$-$$CM$r1[$($F$$$?>l9g!">e$2D>$9(B
  if [ `expr $MEM` -gt $BORDER ] ; then
    $WAKE;exit
  fi
fi
