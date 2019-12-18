#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE:-$0}")"; pwd)"
TIME=`date "+%H%M"`
if [ "${TIME}" = "0000" ]; then
  DATE=`date -d "1 day ago" "+%m%d-%Y"`
else
  DATE=`date "+%m%d-%Y"`
fi
DATETIME=`date "+%Y/%m/%d %H:%M:%S"`
DATETIME2=`date "+%Y%m%d%H%M%S"`
TEMPFILE=${SCRIPT_DIR}/twitterchk_${DATETIME2}.temp
PYTHON_PATH="/usr/bin/python3"
CHECKLIST_FILE=${SCRIPT_DIR}/checklist.txt
CHANNELS=( `awk '{print $1}' ${CHECKLIST_FILE} | sort | uniq` )


for CHANNEL in ${CHANNELS[@]}
do
    # 引数があったら過去ログをチェックする
    if [ "$1" != "" ]; then
      DATE=`date -d "$5 day ago" "+%m%d-%Y"`
      sed -i '/^search: ここまで読んだ/d' /data/share/log/${CHANNEL}/${DATE}.txt
    fi
    # ここまで読んだ、が無ければ1行目に追加
    if [ "`cat /data/share/log/${CHANNEL}/${DATE}.txt | grep \"^search: ここまで読んだ\"`" = "" ]; then
      sed -i -e "1i search: ここまで読んだ" /data/share/log/${CHANNEL}/${DATE}.txt
    fi

    # ここまで読んだ、以降を簡易DB化
    cat /data/share/log/${CHANNEL}/${DATE}.txt | sed -n -e '/^search: ここまで読んだ/,$p' > ${TEMPFILE}
    sed -i '/^search: ここまで読んだ/d' /data/share/log/${CHANNEL}/${DATE}.txt
    echo "search: ここまで読んだ" >> /data/share/log/${CHANNEL}/${DATE}.txt
    cnt=0
    D_T_C_N=()
    TEXT=()
    while read LOGDATE LOGTIME CHANNEL_AND_NICK TEXT
    do
      if [ "${D_T_C_N[${cnt}]}" != "${LOGDATE} ${LOGTIME} ${CHANNEL_AND_NICK}" ]; then
        (( cnt++ ))
        D_T_C_N[${cnt}]="${LOGDATE} ${LOGTIME} ${CHANNEL_AND_NICK}"
      fi
      if [ "${TEXT[${cnt}]}" != "" ]; then
        TEXT[${cnt}]+="
${TEXT}"
      else
        TEXT[${cnt}]="${TEXT}"
      fi
    done < ${TEMPFILE}
    rm -f ${TEMPFILE}

    # ツイートログごとにループ
    cnt=1
    for TEXT in "${TEXT[@]}"
    do
        while read CH WORD
        do
            if [ "${CHANNEL}" = ${CH} ]; then
                HIT=`echo "${TEXT}" | grep "${WORD}"`
                if [ "${HIT}" != "" ]; then
                    HIT_STR="${D_T_C_N[${cnt}]}
${TEXT}"
                    ${PYTHON_PATH} /home/swirhen/sh/slackbot/swirhentv/post.py "bot-sandbox" "@here 【log検索 ${DATETIME}】 ${CHANNEL} ログ内で ${WORD} にヒットしたよ！
\`\`\`
${HIT_STR}
\`\`\`"
                fi
            fi
        done < ${CHECKLIST_FILE}
        (( cnt++ ))
    done
done
