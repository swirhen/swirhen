#!/usr/bin/env bash
# JPCERTのRSSを取得して文字列化
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE:-$0}")"; pwd)"
RSS_RDF=${SCRIPT_DIR}/jpcert.rdf
RSS_OLD=${SCRIPT_DIR}/jpcert.old
RESULT_FILE=${SCRIPT_DIR}/jpcert_feed.txt
RESULT_TEMP=${SCRIPT_DIR}/jpcert_feed.tmp
SETNS_STR="setns x=http://purl.org/rss/1.0/
setns rdf=http://www.w3.org/1999/02/22-rdf-syntax-ns#
setns dc=http://purl.org/dc/elements/1.1/
"
RSS_URL="http://www.jpcert.or.jp/rss/jpcert.rdf"
DATETIME=`date "+%Y/%m/%d-%H:%M:%S"`

end() {
  mv ${RSS_RDF} ${RSS_OLD}
  exit 0
}

curl -s -S "${RSS_URL}" > ${RSS_RDF}

if [ "`diff ${RSS_RDF} ${RSS_OLD}`" = "" ]; then
  if [ "${1:0:1}" != "f" ]; then
    end
  fi
fi

LAST_FEED_DATE=`cat ${RESULT_FILE} | awk 'NR==2'`
if [ "${LAST_FEED_DATE}" = "" ]; then
    LAST_FEED_DATE_S=0
else
    LAST_FEED_DATE_S=`date -d "${LAST_FEED_DATE}" '+%s'`
fi
echo "# LAST UPDATE: ${DATETIME}" > ${RESULT_TEMP}

cnt=1
while :
do
    title=`echo "${SETNS_STR} cat /rdf:RDF/x:item[${cnt}]/x:title" | xmllint --shell "${RSS_RDF}" | grep title | sed "s#<title>\(.*\)</title>#\1#"`
    link=`echo "${SETNS_STR} cat /rdf:RDF/x:item[${cnt}]/x:link" | xmllint --shell "${RSS_RDF}" | grep link | sed "s#<link>\(.*\)</link>#\1#"`
    date=`echo "${SETNS_STR} cat /rdf:RDF/x:item[${cnt}]/dc:date" | xmllint --shell "${RSS_RDF}" | grep date | sed "s#<dc:date>\(.*\)</dc:date>#\1#"`
    date_s=`date -d "${date}" '+%s'`
    if [ "${title}" = "" ]; then
        break
    fi
    if [[ ${title} =~ 注意喚起 ]]; then
        if [ ${date_s} -gt ${LAST_FEED_DATE_S} ]; then
            echo "${date}" >> ${RESULT_TEMP}
            echo "title: ${title}" >> ${RESULT_TEMP}
            echo "link : ${link}" >> ${RESULT_TEMP}
        fi
    fi
    (( cnt++ ))
done

if [ `cat ${RESULT_TEMP} | wc -l` -ne 1 ]; then
    sed '1d' ${RESULT_FILE} >> ${RESULT_TEMP}
    mv ${RESULT_TEMP} ${RESULT_FILE}
    echo "更新あり"
    cat ${RESULT_FILE}
else
    echo "更新無し"
fi

end