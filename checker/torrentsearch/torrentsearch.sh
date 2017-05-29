#!/bin/bash
# ここ
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE:-$0}")"; pwd)"

URI=$1
LISTNAME=$2
DATE=`date "+%Y/%m/%d %H:%M:%S"`
DATE2=`date "+%Y%m%d"`
DOWNLOAD_DIR="/data/share/temp/torrentsearch/${DATE2}"
PYTHON_PATH="/home/swirhen/.pythonbrew/pythons/Python-3.4.3/bin/python"
LIST=${SCRIPT_DIR}/${LISTNAME}.txt
LIST_TEMP=${SCRIPT_DIR}/${LISTNAME}.temp
CRAWL_TEMP=${SCRIPT_DIR}/${LISTNAME}.crawl.temp
CRAWL_XML=${SCRIPT_DIR}/${LISTNAME}.crawl.xml
RESULT_FILE=${SCRIPT_DIR}/${LISTNAME}.result
hit_flg=0
rm -f ${LIST_TEMP}
touch ${LIST_TEMP}
rm -f ${RESULT_FILE}

curl -s -S "${URI}" > ${CRAWL_TEMP}
xmllint --format ${CRAWL_TEMP} > ${CRAWL_XML}

while read keyword
do
    cnt=1
    hit_flg=0
    while :
    do
      item_xml=`echo "cat /rss/channel/item[${cnt}]" | xmllint --shell "${CRAWL_XML}"`
      title=`echo "${item_xml}" | grep title | sed "s#<title>\(.*\)</title>#\1#" | sed "s/^      //"`
      # feed end
      if [ "${title}" = "" ]; then
        break
      fi

      if [ "`echo \"${title}\" | grep \"${keyword}\"`" != "" ];then
        hit_flg=1
        mkdir -p ${DOWNLOAD_DIR}
        echo "# keyword hit : ${keyword} title: ${title}" >> ${RESULT_FILE}
        link=`echo "${item_xml}" | grep link | sed "s#<link>\(.*\)</link>#\1#" | sed "s/^      //" | sed "s/amp;//"`
#        link=`echo "${item_xml}" | grep link | sed "s#<link><\!\[CDATA\[\(.*\)\]\]></link>#\1#" | sed "s/^      //" | sed "s/amp;//"`
        curl "${link}" -o "${DOWNLOAD_DIR}/${title}.torrent"
#        wget --no-check-certificate --restrict-file-names=nocontrol --trust-server-names --content-disposition "${link}" -P "${DOWNLOAD_DIR}" > /dev/null
      fi
      (( cnt++ ))
    done

    if [ "${hit_flg}" = "1" ]; then
      /home/swirhen/tiasock/tiasock_common.sh "#Twitter@t2" "d swirhen 【汎用種調査 ${DATE}】検索キーワード ${keyword} リスト名: ${LISTNAME} ヒットしました！"
    else
      echo "${keyword}" >> ${LIST_TEMP}
    fi
done < ${LIST}

if [ -f "${RESULT_FILE}" ]; then
  /home/swirhen/tiasock/tiasock_common.sh "#Twitter@t2" "【謎調査 ${DATE}】検索キーワードにヒットしました！"
  ${PYTHON_PATH} /home/swirhen/sh/slackbot/swirhentv/post.py "bot-sandbox" "@here 【汎用種調査 ${DATE}】キーワードヒット: ダウンロードしました
\`\`\`
# 結果:
`cat ${RESULT_FILE}`
# ダウンロードした種ファイル:
`ls -l ${DOWNLOAD_DIR}`
\`\`\`"
  mv ${LIST_TEMP} ${LIST}
else
  /home/swirhen/tiasock/tiasock_common.sh "#Twitter@t2" "【謎調査 ${DATE}】検索キーワードにヒットありません"
fi
