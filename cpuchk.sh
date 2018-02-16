#!/bin/sh
WAKE=$1    # プロセスもしくはコマンドの名前 ex)TwitterircgatewayCLI
NAME=$2    # 再起動するシェル ex)/home/swirhen/tigkw.sh ※標準出力は捨てること
BORDER=$3            # CPUしきい値
ROOT=/home/swirhen/  # ファイルを作るディレクトリ
CPU=$ROOT$NAME.cpu   # CPU使用率を記録しておくファイル
if [ $# -eq 3 ]; then
  #PID=`ps -eo pid,comm,cmd | grep $NAME | grep -v grep | grep -v $0 | sed "s/^\s*//" | cut -d" " -f1` #;echo $PID
  #PID=`echo $PID | cut -d" " -f1` ;echo $PID #2個以上見つかった場合は1個目で決めうち対処。泥臭い...
  PID=`pgrep -f -o  $NAME` ;echo $PID
  # 上がってなければ上げ直す
  if [ ${PID:-null} = null ] ; then
    $WAKE;exit
  fi
  NOW=`top -n 1 -b | egrep "^\s*$PID" | awk '{print $9}'` ;echo $NOW
  if [ -f $CPU ] ; then
    OLD=`cat $CPU` ;echo $OLD
    # CPU使用率が連続でしきい値を越えていた場合、上げ直す
    if [ `expr $OLD` -gt $BORDER -a `expr $NOW` -gt $BORDER ] ; then
      $WAKE;exit
    else
      echo $NOW > $CPU # 現在の値に書き換える
    fi
  else
    echo $NOW > $CPU # 上がってるけどファイルが存在してなかった場合
  fi
fi
