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
else
    echo "# usage: $0 YYYYMMDD"
    exit 1
fi
if [ `ls /data/share/temp/torrentsearch/${DATE}/*.torrent 2> /dev/null | wc -l` -eq 0 ]; then
    echo "# 該当ディレクトリにtorrentファイルがありません。終了します"
else
    echo "# found seed list:"
    ls /data/share/temp/torrentsearch/${DATE}/*.torrent
    echo "# mv /data/share/temp/torrentsearch/${DATE}/*.torrent \"${PWD}\""
    mv /data/share/temp/torrentsearch/${DATE}/*.torrent "${PWD}"
fi
