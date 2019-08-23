#!/bin/bash
# 引数処理
if [ "$1" != "" ]; then
    # 日付形式チェック
    date +%Y%m%d --date "$1" > /dev/null 2>&1
    if [ $? -eq 1 ]; then
        echo "# 引数の日付形式 ($1) が無効。終了します"
        exit 1
    fi
    DATE="$1"
    TARGET_DIR="/data/share/temp/torrentsearch/${DATE}"
else
    echo "# usage: $0 YYYYMMDD"
    exit 1
fi
if [ "$2" != "" ]; then
    KEYWORD="$2"
    echo "# 指定キーワード ${KEYWORD}"
fi

if [ `ls ${TARGET_DIR}/*${KEYWORD}*.torrent 2> /dev/null | wc -l` -eq 0 ]; then
    echo "# 該当ディレクトリにtorrentファイルがありません。終了します"
else
    echo "# found seed list:"
    ls /data/share/temp/torrentsearch/${DATE}/*${KEYWORD}*.torrent
    echo "# mv /data/share/temp/torrentsearch/${DATE}/*${KEYWORD}*.torrent \"${PWD}\""
    mv /data/share/temp/torrentsearch/${DATE}/*${KEYWORD}*.torrent "${PWD}"
fi
