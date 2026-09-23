#!/usr/bin/env bash
# ==============================================================================
# Dynamic DNS (Value-Domain) IP Updater & Discord Notifier
#
# 動作概要:
#   1. 現在のグローバルIPを取得 (Value-DomainのIP取得API)
#   2. swirhen.tv の正引きIP (Aレコード) を DNS から取得
#   3. グローバルIPの変化、またはDNSとの不一致を検知した場合に:
#      - Value-Domain の DDNS 更新 API を実行
#      - Discord へ Embed 形式でリッチ通知
#   4. 引数がある場合 (例: ./upip.sh -f) は状態変化にかかわらず現状を通知
# ==============================================================================
set -euo pipefail

# スクリプト配置ディレクトリ & Webhook設定
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WEBHOOK_CONF="${SCRIPT_DIR}/discord_webhook_url"
TARGET="bot-open"

# 前回IP保存先（Dropbox/tempが存在すれば優先、なければ /tmp/prev_global_ip.txt）
PREV_IP_FILE="/home/swirhen/Dropbox/temp/myip.txt"
if [[ ! -d "/home/swirhen/Dropbox/temp" ]]; then
    PREV_IP_FILE="/tmp/swirhen_myip.txt"
fi

HOST_NAME=$(hostname)
DOMAIN_NAME="swirhen.tv"

# ------------------------------------------------------------------------------
# Discord Webhook 通知関数
# ------------------------------------------------------------------------------
notify_discord() {
    local title="$1"
    local color="$2"
    local status="$3"
    local message="$4"
    local current_ip="$5"
    local dns_ip="$6"
    local prev_ip="${7:-なし}"
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')

    if [[ ! -f "${WEBHOOK_CONF}" ]]; then
        echo "[WARN] Webhook設定ファイルが見つかりません: ${WEBHOOK_CONF}" >&2
        return 0
    fi

    local webhook_url
    webhook_url=$(awk -v target="${TARGET}" '$1 == target {print $2; exit}' "${WEBHOOK_CONF}")
    if [[ -z "${webhook_url}" ]]; then
        echo "[WARN] ターゲット '${TARGET}' のWebhook URLが見つかりません。" >&2
        return 0
    fi

    local payload
    payload=$(cat <<EOF
{
  "embeds": [
    {
      "title": "${title}",
      "color": ${color},
      "fields": [
        { "name": "ホスト / ドメイン", "value": "${HOST_NAME} (${DOMAIN_NAME})", "inline": true },
        { "name": "ステータス", "value": "${status}", "inline": true },
        { "name": "現在のグローバルIP", "value": "\`${current_ip}\`", "inline": true },
        { "name": "DNS正引きIP", "value": "\`${dns_ip}\`", "inline": true },
        { "name": "前回記録IP", "value": "\`${prev_ip}\`", "inline": true },
        { "name": "詳細メッセージ", "value": "${message}", "inline": false }
      ],
      "footer": {
        "text": "DDNS Updater • ${timestamp}"
      }
    }
  ]
}
EOF
    )

    curl -s -S -H "Content-Type: application/json" -X POST -d "${payload}" "${webhook_url}" > /dev/null || true
}

# ------------------------------------------------------------------------------
# 1. 現在のグローバルIP取得
# ------------------------------------------------------------------------------
CURRENT_IP=$(curl -sS --max-time 10 "https://dyn.value-domain.com/cgi-bin/dyn.fcg?ip" 2>/dev/null | grep -E '^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+' || true)

if [[ -z "${CURRENT_IP}" ]]; then
    # バックアップ用IP取得
    CURRENT_IP=$(curl -sS --max-time 10 "https://inet-ip.info/ip" 2>/dev/null | grep -E '^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+' || true)
fi

if [[ -z "${CURRENT_IP}" ]]; then
    echo "[ERROR] グローバルIPアドレスの取得に失敗しました。" >&2
    exit 1
fi

# 前回のIPを読み込み
PREV_IP=""
if [[ -f "${PREV_IP_FILE}" ]]; then
    PREV_IP=$(cat "${PREV_IP_FILE}" | tr -d '\r\n[:space:]')
fi

# ------------------------------------------------------------------------------
# 2. swirhen.tv の正引きIP取得 (Google Public DNS)
# ------------------------------------------------------------------------------
DOMAIN_IP=$(dig +short @8.8.8.8 "${DOMAIN_NAME}" A 2>/dev/null | tail -n 1 || true)
if [[ -z "${DOMAIN_IP}" ]]; then
    sleep 3
    DOMAIN_IP=$(dig +short @8.8.4.4 "${DOMAIN_NAME}" A 2>/dev/null | tail -n 1 || true)
fi

if [[ -z "${DOMAIN_IP}" ]]; then
    DOMAIN_IP="取得失敗"
fi

# ------------------------------------------------------------------------------
# 3. 判定および DDNS 更新・通知
# ------------------------------------------------------------------------------
IP_CHANGED=0
DNS_MISMATCH=0

if [[ -n "${PREV_IP}" && "${CURRENT_IP}" != "${PREV_IP}" ]]; then
    IP_CHANGED=1
fi

if [[ "${DOMAIN_IP}" != "取得失敗" && "${CURRENT_IP}" != "${DOMAIN_IP}" ]]; then
    DNS_MISMATCH=1
fi

# A. グローバルIP変化 または DNS不一致がある場合 -> DDNS更新APIを実行して通知
if [[ ${IP_CHANGED} -eq 1 || ${DNS_MISMATCH} -eq 1 ]]; then
    # Value-Domain DDNS 更新実行
    DDNS_RES=$(curl -sS --max-time 15 "https://dyn.value-domain.com/cgi-bin/dyn.fcg?d=${DOMAIN_NAME}&p=irankae1" 2>/dev/null || echo "実行失敗")

    STATUS_DESC=""
    if [[ ${IP_CHANGED} -eq 1 && ${DNS_MISMATCH} -eq 1 ]]; then
        STATUS_DESC="グローバルIP変動 & DNS不一致検知"
    elif [[ ${IP_CHANGED} -eq 1 ]]; then
        STATUS_DESC="グローバルIP変動検知"
    else
        STATUS_DESC="DNS不一致検知（未反映）"
    fi

    MSG="グローバルIPまたはDNSレコードの不一致を検知したため、DDNS更新APIを実行しました。\\n\`\`\`\\nAPI応答: ${DDNS_RES}\\n\`\`\`"
    
    # Discord 通知（ALERT: オレンジ色 15105570）
    notify_discord "🚨 [ALERT] DDNS更新を実行しました" 15105570 "${STATUS_DESC}" "${MSG}" "${CURRENT_IP}" "${DOMAIN_IP}" "${PREV_IP}"

# B. 手動実行などの引数がある場合 ($1 != "") -> 現状報告通知
elif [[ $# -gt 0 ]]; then
    MSG="定期チェックまたは手動実行によるIP整合性確認です。グローバルIPとDNSレコードは正常に一致しています。"
    # Discord 通知（INFO: 青色 3447003）
    notify_discord "ℹ️ [INFO] グローバルIP整合性チェック" 3447003 "正常一致" "${MSG}" "${CURRENT_IP}" "${DOMAIN_IP}" "${PREV_IP}"
fi

# ------------------------------------------------------------------------------
# 4. 今回取得したIPを保存
# ------------------------------------------------------------------------------
echo "${CURRENT_IP}" > "${PREV_IP_FILE}"

exit 0
