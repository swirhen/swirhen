#!/bin/bash
# ここ
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE:-$0}")"; pwd)"

URI=$1
LISTNAME=$2
DATE=`date "+%Y/%m/%d %H:%M:%S"`
LIST=${SCRIPT_DIR}/${LISTNAME}.txt
LIST2=${SCRIPT_DIR}/${LISTNAME}.temp
flg=0
rm -f ${LIST2}
touch ${LIST2}
rm -f ${SCRIPT_DIR}/${LISTNAME}.crawl

curl -L -X GET "${URI}&page=rss" > ${SCRIPT_DIR}/${LISTNAME}.crawl
curl -L -X GET "${URI}&offset=2&page=rss" >> ${SCRIPT_DIR}/${LISTNAME}.crawl
curl -L -X GET "${URI}&offset=3&page=rss" >> ${SCRIPT_DIR}/${LISTNAME}.crawl

while read keyword
do
  src=`cat ${SCRIPT_DIR}/${LISTNAME}.crawl | grep "${keyword}"`
  if [ "${src}" != "" ]; then
    flg=1
    /home/swirhen/tiasock/tiasock_common.sh "#Twitter@t2" "d swirhen 【汎用種調査 ${DATE}】検索キーワード ${keyword} リスト名: ${LISTNAME} ヒットしました！"
    /home/swirhen/sh/slack/post.sh "swirhentv" "@here 【汎用種調査 ${DATE}】検索キーワード ${keyword} リスト名: ${LISTNAME} ヒットしました！ URL: ${URI}"
    python /home/swirhen/sh/slackbot/swirhentv/post.py "bot-sandbox" "@here 【汎用種調査 ${DATE}】検索キーワード ${keyword} リスト名: ${LISTNAME} ヒットしました！ URL: ${URI}"
  else
    echo "${keyword}" >> ${LIST2}
  fi
done < ${LIST}

if [ ${flg} = 1 ]; then
  /home/swirhen/tiasock/tiasock_swirhentv.sh "【謎調査 ${DATE}】検索キーワードにヒットしました！"
  mv ${LIST2} ${LIST}
else
  /home/swirhen/tiasock/tiasock_swirhentv.sh "【謎調査 ${DATE}】検索キーワードにヒットありません"
fi
