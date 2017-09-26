#!/bin/bash
# ここ
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE:-$0}")"; pwd)"

ID=$1
FILE=${SCRIPT_DIR}/${ID}
URI="$2"
DATE=`date "+%Y/%m/%d %H:%M:%S"`
PYTHON_PATH="/home/swirhen/.pythonbrew/pythons/Python-3.4.3/bin/python"
HIT_ST="$3"
HIT_ED="$4"
CONVFROM="$5"

if [ "${HIT_ST}" != "" -a "${HIT_ED}" != "" ]; then
  if [ "${CONVFROM}" != "" ];then
    curl "${URI}" | iconv -f ${CONVFROM} -t UTF8 | sed -n "/${HIT_ST}/,/${HIT_ED}/p" > "${FILE}"
  else
    curl "${URI}" | sed -n "/${HIT_ST}/,/${HIT_ED}/p" > "${FILE}"
  fi
else
  if [ "${CONVFROM}" != "" ];then
    curl "${URI}" | iconv -f ${CONVFROM} -t UTF8 > "${FILE}"
  else
    curl "${URI}" > "${FILE}"
  fi
fi

if [ "`diff ${FILE} ${FILE}.old`" != "" ]; then
  /home/swirhen/tiasock/tiasock_common.sh "#Twitter@t2" "d swirhen 【汎用URLクロールチェック ${DATE}】 差分あり！ チェックID: ${ID} URL: ${URI}"
  /home/swirhen/sh/slack/post.sh "swirhentv" "@j_suzuki 【汎用URLクロールチェック ${DATE}】 差分あり！ チェックID: ${ID} URL: ${URI}"
  ${PYTHON_PATH} /home/swirhen/sh/slackbot/swirhentv/post.py "bot-sandbox" "@here 【汎用URLクロールチェック ${DATE}】 差分あり！ チェックID: ${ID} URL: ${URI}"
fi

mv ${FILE} ${FILE}.old
