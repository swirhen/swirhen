#!/bin/sh
WAKE=$1    # 再起動するシェルの位置 ex)/home/swirhen/sh/tiarraup.sh
NAME=$2    # チェックするプロセスの名前 ex)tiarra
if [ $# -eq 2 ]; then  # 引数が2個なかったら終了
  CHK=`ps -eo comm,cmd | grep $NAME | grep -v grep | grep -v $0` #;echo $CHK
  # 上がってなければ上げ直す
  if [ "${CHK:-null}" = null ] ; then
    $WAKE
  fi
fi
