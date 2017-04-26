#!/usr/bin/env bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE:-$0}")"; pwd)"
CHANNEL=$1
TEXT=$2
TOKEN=`cat ${SCRIPT_DIR}/token`

curl -XPOST -d "token=${TOKEN}" -d "channel=${CHANNEL}" -d "text=${TEXT}" -d "username=swirhentv" -d "link_names=1" "https://slack.com/api/chat.postMessage"
