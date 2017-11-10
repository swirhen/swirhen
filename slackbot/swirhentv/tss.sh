#!/usr/bin/env bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE:-$0}")"; pwd)"

KEYWORD="$1"
MAX_SRC_CNT=10
SRC_CAT="ALL"
if [ "$2" != "" ]; then
  SRC_CAT=$2
fi
if [ "$3" != "" ]; then
  MAX_SRC_CNT=$3
fi

DATE=`date "+%Y/%m/%d %H:%M:%S"`
DATE2=`date "+%Y%m%d%H%M%S"`
HIT_FLG=0
TRACKER_LIST=${SCRIPT_DIR}/list/tracker.txt
CRAWL_TEMP=${SCRIPT_DIR}/temp/tss_${DATE2}.crawl.temp
CRAWL_XML=${SCRIPT_DIR}/temp/tss_${DATE2}.crawl.xml

end()
{
  rm -f ${CRAWL_TEMP}
  rm -f ${CRAWL_XML}
  exit 0
}

hit_cnt=0
while read CATEGORY URI
do
  if [ "${SRC_CAT}" = "ALL" -o "${SRC_CAT}" = "${CATEGORY}" ]; then
    curl -s -S "${URI}" > ${CRAWL_TEMP}
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

      if [ "`echo ${title} | grep \"${KEYWORD}\"`" != "" ]; then
        category=`echo "${item_xml}" | grep category\> | sed "s#<.*category>\(.*\)</.*category>#\1#" | sed "s/^      //"`
        link=`echo "${item_xml}" | grep link | sed "s#<link>\(.*\)</link>#\1#" | sed "s/^      //" | sed "s/amp;//"`
#        link=`echo "${item_xml}" | grep link | sed "s#<link><\!\[CDATA\[\(.*\)\]\]></link>#\1#" | sed "s/^      //" | sed "s/amp;//"`

        echo "[${category}] ${title} : ${link}"
        (( hit_cnt++ ))
      fi

      if [ ${hit_cnt} -ge ${MAX_SRC_CNT} ]; then
        end
      fi
      (( cnt++ ))
    done
  fi
done < ${TRACKER_LIST}

if [ ${hit_cnt} -eq 0 ]; then
  echo -n "no result."
fi
end