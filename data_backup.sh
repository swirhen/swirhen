#!/bin/sh
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE:-$0}")"; pwd)"
LOGFILE="${SCRIPT_DIR}/logs/daily_backup.log"

# Discord 投稿設定（discord_webhook_url の「ターゲット名 URL」形式の行から取得）
WEBHOOK_CONF="${SCRIPT_DIR}/discord_webhook_url"
DISCORD_TARGET="${DISCORD_TARGET:-bot-open}"
HOST_NAME="$(hostname)"

# マウント確認対象
BACKUP_MOUNTS="/backup1 /backup2 /backup3 /backup4 /backup5 /sora_data1 /sora_data2 /sora_data3"

# Discord へメッセージを投稿する（失敗してもバックアップ処理は止めない）
discord_post() {
    if [ ! -f "${WEBHOOK_CONF}" ]; then
        echo "[WARN] Webhook設定ファイルが見つかりません: ${WEBHOOK_CONF}" >> "${LOGFILE}"
        return 0
    fi
    webhook_url=$(awk -v target="${DISCORD_TARGET}" '$1 == target {print $2; exit}' "${WEBHOOK_CONF}")
    if [ -z "${webhook_url}" ]; then
        echo "[WARN] ターゲット '${DISCORD_TARGET}' の Webhook URL が未定義です" >> "${LOGFILE}"
        return 0
    fi
    # 改行や記号を含むメッセージを安全に JSON 化する
    payload=$(python3 -c 'import json,sys; print(json.dumps({"content": sys.argv[1][:2000]}))' "$1")
    curl -s -S -H "Content-Type: application/json" -X POST -d "${payload}" "${webhook_url}" > /dev/null 2>> "${LOGFILE}"
}

# rsync を実行し、失敗したら記録する
# 引数: $1=コピー元 $2=コピー先
FAILED_LIST=""
run_rsync() {
    echo "## rsync $1 -> $2" >> "${LOGFILE}"
    rsync -auv --delete --exclude '.DAV' "$1" "$2" >> "${LOGFILE}" 2>&1
    rc=$?
    # rc=24（転送中にファイルが消えた）は日常的に起きうるため成功扱いとする
    if [ ${rc} -ne 0 ] && [ ${rc} -ne 24 ]; then
        echo "[ERROR] rsync failed (rc=${rc}): $1 -> $2" >> "${LOGFILE}"
        FAILED_LIST="${FAILED_LIST}
- $1 -> $2 (rc=${rc})"
    fi
}

START_TIME="$(date '+%Y-%m-%d %H:%M:%S')"
echo "# DAILY BACKUP START: `date`" > "${LOGFILE}"

# バックアップ先のマウント状況を確認し、1つでも未マウントなら中止
UNMOUNTED=""
for mp in ${BACKUP_MOUNTS}; do
    if ! mountpoint -q "${mp}"; then
        UNMOUNTED="${UNMOUNTED} ${mp}"
    fi
done
if [ -n "${UNMOUNTED}" ]; then
    echo "[ERROR] 未マウントのバックアップ先があるため中止します:${UNMOUNTED}" >> "${LOGFILE}"
    echo "# DAILY BACKUP ABORTED: `date`" >> "${LOGFILE}"
    discord_post ":x: [${HOST_NAME}] デイリーバックアップ中止
未マウント:${UNMOUNTED}
開始: ${START_TIME}"
    exit 1
fi

# book
run_rsync /sora_data2/book/ /backup1/book/
# v_old
run_rsync /sora_data1/v_old/ /backup2/v_old/
# anime_old, anime_lib3
run_rsync /sora_data2/anime_old/ /backup5/anime_old/
run_rsync /sora_data1/anime_lib3/ /backup3/anime_lib3/
# share, idol_media
run_rsync /sora_data1/share/ /backup1/share/
run_rsync /sora_data3/idol_media/ /backup4/idol_media/

END_TIME="$(date '+%Y-%m-%d %H:%M:%S')"
echo "# DAILY BACKUP END: `date`" >> "${LOGFILE}"

if [ -n "${FAILED_LIST}" ]; then
    discord_post ":warning: [${HOST_NAME}] デイリーバックアップでエラーが発生しました
開始: ${START_TIME} / 終了: ${END_TIME}
失敗:${FAILED_LIST}
詳細: ${LOGFILE}"
    exit 1
fi

discord_post ":white_check_mark: [${HOST_NAME}] デイリーバックアップ完了
開始: ${START_TIME} / 終了: ${END_TIME}"
