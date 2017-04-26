#!/bin/bash
TIME=`date "+%H%M"`
if [ "${TIME}" = "0000" ]; then
  DATE=`date -d "1 day ago" "+%m%d-%Y"`
else
  DATE=`date "+%m%d-%Y"`
fi
DATETIME=`date "+%Y/%m/%d %H:%M:%S"`
CHANNEL=$1
SEARCH_WORD=$2
SEARCH_WORD2=$3
SEARCH_WORD3=$4

HIT=`cat /data/share/log/${CHANNEL}/${DATE}.txt | sed -n -e '/^search: ここまで読んだ/,$p' | grep "${SEARCH_WORD}"`
if [ "${SEARCH_WORD2}" != "" ]; then
  HIT2=`cat /data/share/log/${CHANNEL}/${DATE}.txt | sed -n -e '/^search: ここまで読んだ/,$p' | grep "${SEARCH_WORD2}"`
fi
if [ "${SEARCH_WORD3}" != "" ]; then
  HIT3=`cat /data/share/log/${CHANNEL}/${DATE}.txt | sed -n -e '/^search: ここまで読んだ/,$p' | grep "${SEARCH_WORD3}"`
fi

if [ "${HIT}" != "" -a "${HIT2}" != "" -a "${HIT3}" != "" ]; then
  /home/swirhen/tiasock/tiasock_swirhentv.sh "d swirhen 【log検索 ${DATETIME}】 ${CHANNEL} ログ内で ${SEARCH_WORD} ${SEARCH_WORD2} ${SEARCH_WORD3}にヒットしたよ"
fi

sed -i '/^search: ここまで読んだ/d' /data/share/log/${CHANNEL}/${DATE}.txt
echo "search: ここまで読んだ" >> /data/share/log/${CHANNEL}/${DATE}.txt
