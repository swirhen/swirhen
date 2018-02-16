#!/bin/sh
WAKE=$1    # プロセスもしくはコマンドの名前 ex)TwitterircgatewayCLI
NAME=$2    # 再起動するシェル ex)/home/swirhen/tigkw.sh ※標準出力は捨てること
BORDER=$3            # MEMしきい値
if [ $# -eq 3 ]; then
  MEM=`ps u | grep $NAME | grep -v grep | grep -v $0 | awk '{print $4}' | cut -d"." -f1` ;echo $MEM
  MEM=`echo $MEM | cut -d" " -f1` ;echo $MEM #2個以上見つかった場合は1個目で決めうち対処。泥臭い...
  # MEM使用率がしきい値を越えていた場合、上げ直す
  if [ `expr $MEM` -gt $BORDER ] ; then
    $WAKE;exit
  fi
fi
