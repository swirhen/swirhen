#!/usr/bin/env bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE:-$0}")"; pwd)"

KEYWORD="$1"
MAX_SRC_CNT=10
if [ "$2" != "" ]; then
  MAX_SRC_CNT=$2
fi
DATE=`date "+%Y/%m/%d %H:%M:%S"`
DATE2=`date "+%Y%m%d%H%M%S"`
HIT_FLG=0
NYAA_LIST=${SCRIPT_DIR}/list/nyaa.txt
CRAWL_TEMP=${SCRIPT_DIR}/temp/tss2_${DATE2}.crawl.temp
CRAWL_XML=${SCRIPT_DIR}/temp/tss2_${DATE2}.crawl.xml
RESULT_FILE=${SCRIPT_DIR}/temp/tss2.result

end()
{
  rm -f ${CRAWL_TEMP}
  rm -f ${CRAWL_XML}
  exit 0
}

hit_cnt=0
rm -f ${RESULT_FILE}
while read URI
do
  curl -s -S "${URI}&term=${KEYWORD}&page=rss" > ${CRAWL_TEMP}
  xmllint --format ${CRAWL_TEMP} > ${CRAWL_XML}
  cnt=1
  while :
  do
    item_xml=`echo "cat /rss/channel/item[${cnt}]" | xmllint --shell "${CRAWL_XML}"`
    title=`echo "${item_xml}" | grep title | sed "s#<title>\(.*\)</title>#\1#" | sed "s/^      //"`
    # feed end
    if [ "${title}" = "" ]; then
      break
    fi

    category=`echo "${item_xml}" | grep category | sed "s#<category>\(.*\)</category>#\1#" | sed "s/^      //"`
    link=`echo "${item_xml}" | grep link | sed "s#<link>\(.*\)</link>#\1#" | sed "s/^      //" | sed "s/amp;//"`

    echo "[${category}] ${title} : ${link}" >> ${RESULT_FILE}
    (( hit_cnt++ ))

    if [ ${hit_cnt} -ge ${MAX_SRC_CNT} ]; then
      end
    fi
    (( cnt++ ))
  done
done < ${NYAA_LIST}