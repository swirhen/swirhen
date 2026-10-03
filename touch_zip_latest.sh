#!/bin/bash

# フラグ初期値
VERBOSE=0
DRY_RUN=0

# オプション解析
while [[ "$1" =~ ^- ]]; do
  case "$1" in
    -v|--verbose)
      VERBOSE=1
      shift
      ;;
    -d|--dry-run)
      DRY_RUN=1
      shift
      ;;
    *)
      echo "不明なオプションです: $1"
      echo "Usage: $0 [-d|--dry-run] [-v|--verbose] <path-to-zip-file>"
      exit 1
      ;;
  esac
done

ZIP_FILE="$1"

# 引数チェック
if [ -z "$ZIP_FILE" ] || [ ! -f "$ZIP_FILE" ]; then
  echo "Usage: $0 [-d|--dry-run] [-v|--verbose] <path-to-zip-file>"
  exit 1
fi

[ $VERBOSE -eq 1 ] && echo "=== [DEBUG] 対象ファイル: $ZIP_FILE ==="

# zipinfo から DOS date/time の行のみを抽出し、正規表現で安全にキャプチャ
PARSED_DATES=$(zipinfo -v "$ZIP_FILE" | while read -r line; do
  if [[ "$line" =~ file\ last\ modified\ on\ \(DOS\ date/time\):\ +([0-9]{4}\ +[A-Za-z]{3}\ +[0-9]{1,2}\ +[0-9]{2}:[0-9]{2}:[0-9]{2}) ]]; then
    RAW_DATE="${BASH_REMATCH[1]}"
    FORMATTED_DATE=$(echo "$RAW_DATE" | sed -E 's/([0-9]{4}) +([A-Za-z]{3}) +([0-9]{1,2}) +(.*)/\3 \2 \1 \4/')
    
    if [ $VERBOSE -eq 1 ]; then
      echo "[DEBUG] Extracted: $RAW_DATE -> $FORMATTED_DATE" >&2
    fi
    echo "$FORMATTED_DATE"
  fi
done)

# dateコマンドで正規化（YYYY-MM-DD HH:MM:SS）して最新値を取得
LATEST_DATE=$(echo "$PARSED_DATES" | while read -r d; do
  [ -z "$d" ] && continue
  formatted=$(date -d "$d" "+%Y-%m-%d %H:%M:%S" 2>/dev/null)
  if [ -n "$formatted" ]; then
    [ $VERBOSE -eq 1 ] && echo "[DEBUG] Normalized: '$d' -> '$formatted'" >&2
    echo "$formatted"
  fi
done | sort | tail -n 1)

if [ -z "$LATEST_DATE" ]; then
  echo "エラー: ZIP内に有効なDOSタイムスタンプが見つかりませんでした。"
  exit 1
fi

# ドライラン判定と実行
if [ $DRY_RUN -eq 1 ]; then
  echo "[DRY-RUN] ファイル名: $ZIP_FILE | 最新日時: $LATEST_DATE (変更されません)"
else
  touch -d "$LATEST_DATE" "$ZIP_FILE"
  echo "ZIPファイル ($ZIP_FILE) のタイムスタンプを更新しました: $LATEST_DATE"
fi
