#!/bin/bash
# ここ
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE:-$0}")"; pwd)"

ID=$1
FILE=${SCRIPT_DIR}/${ID}
URI="$2"
DATE=`date "+%Y/%m/%d %H:%M:%S"`
HIT_ST="$3"
HIT_ED="$4"

if [ "${HIT_ST}" != "" -a "${HIT_ED}" != "" ]; then
  curl "${URI}" | sed -n "/${HIT_ST}/,/${HIT_ED}/p" > "${FILE}"
else
  curl "${URI}" > "${FILE}"
fi

if [ "`diff ${FILE} ${FILE}.old`" != "" ]; then
  /home/swirhen/tiasock/tiasock_common.sh "#Twitter@t2" "d swirhen 【汎用URLクロールチェック ${DATE}】 差分あり！ チェックID: ${ID} URL: ${URI}"
  /home/swirhen/sh/slack/post.sh "swirhentv" "@j_suzuki 【汎用URLクロールチェック ${DATE}】 差分あり！ チェックID: ${ID} URL: ${URI}"
fi

mv ${FILE} ${FILE}.old
