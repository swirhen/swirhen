#!/usr/bin/env bash
# ==============================================================================
# Discord 通知汎用スクリプト
#
# 仕様:
#   - /home/swirhen/sh/discord_webhook_url から宛先（ターゲット名）に対応する
#     Webhook URL を取得してメッセージ（またはEmbed）を送信する。
#   - 投稿先ターゲットは環境変数 DISCORD_TARGET で指定（デフォルト: bot-open）
#   - 引数:
#       $1: ステータス ("開始", "成功", "失敗", または任意タイトル)
#       $2: メッセージ本文
#       $3: 更新前の証明書期限 (省略可)
#       $4: 更新後の証明書期限 (省略可)
#
# Certbot連携時:
#   - 環境変数 RENEWED_DOMAINS, RENEWED_LINEAGE が存在する場合は自動でEmbedに追加
# ==============================================================================
set -euo pipefail

# スクリプトの配置ディレクトリ
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WEBHOOK_CONF="${SCRIPT_DIR}/discord_webhook_url"

# 投稿先チャンネル名/ターゲット名（環境変数 DISCORD_TARGET、未設定時は "bot-open"）
TARGET="${DISCORD_TARGET:-bot-open}"

if [[ ! -f "${WEBHOOK_CONF}" ]]; then
    echo "[ERROR] Webhook設定ファイルが見つかりません: ${WEBHOOK_CONF}" >&2
    exit 1
fi

# discord_webhook_url から該当ターゲットの URL を抽出（第1カラムが一致する行の第2カラム）
WEBHOOK_URL=$(awk -v target="${TARGET}" '$1 == target {print $2; exit}' "${WEBHOOK_CONF}")

if [[ -z "${WEBHOOK_URL}" ]]; then
    echo "[ERROR] ターゲット '${TARGET}' に対応する Webhook URL が ${WEBHOOK_CONF} に定義されていません。" >&2
    exit 1
fi

STATUS="${1:-情報}"
MESSAGE="${2:-}"
PRE_EXPIRY="${3:-}"
POST_EXPIRY="${4:-}"
HOST_NAME=$(hostname)
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

# ステータスに応じたEmbedカラー設定
if [[ "${STATUS}" == "成功"* ]]; then
    COLOR=3066993   # 緑 (#2ecc71)
elif [[ "${STATUS}" == "失敗"* ]]; then
    COLOR=15158332  # 赤 (#e74c3c)
elif [[ "${STATUS}" == "開始"* ]]; then
    COLOR=15844367  # 黄・オレンジ (#f1c40f)
else
    COLOR=3447003   # 青 (#3498db)
fi

# Certbotの更新情報（環境変数が渡されている場合のみ取得）
DOMAINS="${RENEWED_DOMAINS:-}"
LINEAGE="${RENEWED_LINEAGE:-}"

# Fields JSON の組み立て
FIELDS="["
FIELDS+="{\"name\": \"ホスト名\", \"value\": \"${HOST_NAME}\", \"inline\": true},"
FIELDS+="{\"name\": \"ステータス\", \"value\": \"${STATUS}\", \"inline\": true}"

if [[ -n "${DOMAINS}" ]]; then
    FIELDS+=",{\"name\": \"更新ドメイン\", \"value\": \"\`\`\`\n${DOMAINS}\n\`\`\`\", \"inline\": false}"
fi

if [[ -n "${LINEAGE}" ]]; then
    FIELDS+=",{\"name\": \"証明書パス\", \"value\": \"\`\`\`\n${LINEAGE}\n\`\`\`\", \"inline\": false}"
fi

if [[ -n "${PRE_EXPIRY}" ]]; then
    FIELDS+=",{\"name\": \"更新前の証明書期限 (notAfter)\", \"value\": \"\`${PRE_EXPIRY}\`\", \"inline\": true}"
fi

if [[ -n "${POST_EXPIRY}" ]]; then
    FIELDS+=",{\"name\": \"更新後の証明書期限 (notAfter)\", \"value\": \"\`${POST_EXPIRY}\`\", \"inline\": true}"
fi

if [[ -n "${MESSAGE}" ]]; then
    # JSON 内のエスケープ処理
    ESCAPED_MESSAGE=$(printf '%s' "${MESSAGE}" | python3 -c 'import json,sys; print(json.dumps(sys.stdin.read())[1:-1])' 2>/dev/null || printf '%s' "${MESSAGE}")
    FIELDS+=",{\"name\": \"メッセージ\", \"value\": \"${ESCAPED_MESSAGE}\", \"inline\": false}"
fi
FIELDS+="]"

PAYLOAD=$(cat <<EOF
{
  "embeds": [
    {
      "title": "🔒 証明書更新・Apacheリロード通知",
      "color": ${COLOR},
      "fields": ${FIELDS},
      "footer": {
        "text": "${TIMESTAMP}"
      }
    }
  ]
}
EOF
)

# Discord への Webhook POST
curl -s -S -H "Content-Type: application/json" -X POST -d "${PAYLOAD}" "${WEBHOOK_URL}" > /dev/null
