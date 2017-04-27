#!/usr/bin/env bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE:-$0}")"; pwd)"

KEYWORD="$1"
DATE=`date "+%Y/%m/%d %H:%M:%S"`
DATE2=`date "+%Y%m%d%H%M%S"`
HIT_FLG=0
NYAA_LIST=${SCRIPT_DIR}/list/nyaa.txt
CRAWL_TEMP=${SCRIPT_DIR}/temp/tss_${DATE2}.crawl
RESULT_FILE=${SCRIPT_DIR}/temp/tss.result

rm -f ${RESULT_FILE}
while read URI
do
  curl -L -X GET "${URI}&page=rss" | grep "${KEYWORD}" > ${CRAWL_TEMP}
  if [ -z "${CRAWL_TEMP}" ]; then
    echo "${URI}" > ${RESULT_FILE}
    exit 0
  fi
  curl -L -X GET "${URI}&offset=2&page=rss" | grep "${KEYWORD}" > ${CRAWL_TEMP}
  if [ -z "${CRAWL_TEMP}" ]; then
    echo "${URI}&offset=2" > ${RESULT_FILE}
    exit 0
  fi
  curl -L -X GET "${URI}&offset=3&page=rss" | grep "${KEYWORD}" > ${CRAWL_TEMP}
  if [ -z "${CRAWL_TEMP}" ]; then
    echo "${URI}&offset=3" > ${RESULT_FILE}
    exit 0
  fi
done < ${NYAA_LIST}