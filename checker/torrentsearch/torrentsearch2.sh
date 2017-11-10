#!/bin/bash
# ここ
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE:-$0}")"; pwd)"
TEMP_DIR="${SCRIPT_DIR}/temp"
LOG_DIR="${SCRIPT_DIR}/logs"

CHECKLIST="${SCRIPT_DIR}/checklist.txt"
CHECKLIST_TMP="${SCRIPT_DIR}/checklist.txt.tmp"
URL_LIST="${SCRIPT_DIR}/urllist.txt"
DL_URL_LIST="${SCRIPT_DIR}/download_url.txt"
DATE=`date "+%Y/%m/%d %H:%M:%S"`
DATE2=`date "+%Y%m%d"`
LOGDATE=`date "+%Y%m%d%H%M"`
LOG_FILE="${LOG_DIR}/torrentsearch_${LOGDATE}.log"
DOWNLOAD_DIR="/data/share/temp/torrentsearch/${DATE2}"
PYTHON_PATH="python3"

hit_flg=0
check_list=()
check_list_temp=()
hit_keyword=()
category_list=()
download_url_list=()

# リストからカテゴリ、キーワードを取得
# カテゴリは別途配列に入れる（重複チェック）
while read line
do
  if [ "${line:0:1}" != "#" ]; then
    category=${line%\|*}
    check_list+=( "${line}" )
    cat_hit=0
    for cat in ${category_list[@]}
    do
      if [ "${cat}" = "${category}" ]; then
        cat_hit=1
        break
      fi
    done
    if [ ${cat_hit} -eq 0 ]; then
      category_list+=( "${category}" )
    fi
  fi
done < ${CHECKLIST}

# DL済みURLリスト
while read dlurl
do
  download_url_list+=( "${dlurl}" )
done < ${DL_URL_LIST}

# 取得したカテゴリ配列から、URL対応リストに対応するURLを取得し、クロール用のXMLを取得
rm -f ${TEMP_DIR}/*
while read category uri
do
  for cat in ${category_list[@]}
  do
    if [ "${cat}" = "${category}" ]; then
      curl -s -S "${uri}" > ${TEMP_DIR}/${cat}.temp
      xmllint --format ${TEMP_DIR}/${cat}.temp > ${TEMP_DIR}/${cat}.xml
    fi
  done
done < ${URL_LIST}

# カテゴリ名.xmlごとにクロール、リストのキーワードと突き合わせ
for crawl_xml in ${TEMP_DIR}/*.xml
do
  cnt=1
  while :
  do
    item_xml=`echo "cat /rss/channel/item[${cnt}]" | xmllint --shell "${crawl_xml}"`
    title=`echo "${item_xml}" | grep title | sed "s#<title>\(.*\)</title>#\1#" | sed "s/^      //"`
    # feed end
    if [ "${title}" = "" ]; then
      break
    fi

    for line in "${check_list[@]}"
    do
      category="${line%\|*}"
      keyword="${line#*\|}"
      erase_flg=0
      if [ "${keyword:0:1}" = "@" ]; then
        keyword="${keyword:1}"
        erase_flg=1
      fi

      if [ "${category}.xml" = "${crawl_xml##*/}" ]; then
        if [ "`echo \"${title}\" | grep \"${keyword}\"`" != "" ];then
          # キーワードヒットしたら、DL済みURLリストとも突き合わせ
          link=`echo "${item_xml}" | grep link | sed "s#<link>\(.*\)</link>#\1#" | sed "s/^      //" | sed "s/amp;//"`
          dled_flg=0
          for dluri in "${download_url_list[@]}"
          do
            if [ "${link}" = "${dluri}" ]; then
              dled_flg=1
              break
            fi
          done
          # DL済みリストになければ、ダウンロードして、DL済みリストにURLを追加
          if [ ${dled_flg} -eq 0 ]; then
            hit_flg=1
            mkdir -p ${DOWNLOAD_DIR}
            echo "# keyword hit : ${keyword} title: ${title}" >> ${LOG_FILE}
            curl "${link}" -o "${DOWNLOAD_DIR}/${title}.torrent"
            echo "${link}" >> ${DL_URL_LIST}

            # キーワードヒットリストに追加
            hkw_flg=0
            for hkw in "${hit_keyword[@]}"
            do
              if [ "${keyword}" = "${hkw}" ]; then
                hkw_flg=1
                break
              fi
            done
            if [ ${hit_flg} -eq 0 ]; then
              hit_keyword+=( "${keyword}" )
            fi
          fi
        fi
      fi
    done
    (( cnt++ ))
  done
done

# 報告
if [ ${hit_flg} -eq 1 ]; then
  ${PYTHON_PATH} /home/swirhen/sh/slackbot/swirhentv/post.py "bot-sandbox" "@here 【汎用種調査 ${DATE}】キーワードヒット: ダウンロードしました
\`\`\`
# 結果:
`cat ${LOG_FILE}`
# ダウンロードした種ファイル:
`ls -l ${DOWNLOAD_DIR}`
\`\`\`"
fi

# リスト整備
for line in "${check_list[@]}"
do
  keyword="${line#*\|}"
  erase_flg=0
  if [ "${keyword:0:1}" = "@" ]; then
    keyword="${keyword:1}"
    erase_flg=1
  fi

  hkw_flg=0
  for hkw in "${hit_keyword[@]}"
  do
    if [ "${keyword}" = "${hkw}" ]; then
      hkw_flg=1
      break
    fi
  done
  if [ ${hit_flg} -eq 0 ]; then
    hit_keyword+=( "${keyword}" )
  fi

  # ダウンロードが行われた and 消去するキーワードの場合、リストから消去する
  if [ ${hkw_flg} -eq 0 -o ${erase_flg} -eq 0 ]; then
    check_list_temp+=( "${line}" )
  fi
done

rm -f "${CHECKLIST_TMP}"
for clt in "${check_list_temp[@]}"
do
  echo "${clt}" >> "${CHECKLIST_TMP}"
done
cp -p "${CHECKLIST_TMP}" "${CHECKLIST}"

cd ${SCRIPT_DIR}
git commit -m 'checklist.txt update' checklist.txt
git pull
git push origin master
