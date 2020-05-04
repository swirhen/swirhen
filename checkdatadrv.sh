#!/usr/bin/env bash
# data drive checker
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE:-$0}")"; pwd)"
PYTHON_PATH="python3"
CHANNEL="bot-open"
#CHANNEL="bot-sandbox"
DRIVES_NUM_CORRECT=7

slack_post() {
  ${PYTHON_PATH} /home/swirhen/sh/slackbot/swirhentv/post.py "${CHANNEL}" "$1"
}

slack_upload() {
  /usr/bin/curl -F channels="${CHANNEL}" -F file="@$1" -F title="$2" -F token=`cat ${SCRIPT_DIR}/token` -F filetype=text https://slack.com/api/files.upload
}

DRIVES=`df -h | grep data`
DRIVES_NUM=`echo "${DRIVES}" | wc -l`

if [ ${DRIVES_NUM} -ne ${DRIVES_NUM_CORRECT} ]; then
  TEXT="@channel [ALERT] logical drives mounted not ${DRIVES_NUM_CORRECT} drives. tring re-mount."
  TEXT+="

DRIVES:
"
  TEXT+="${DRIVES}"
  slack_post "${TEXT}"
  sudo mount -a
elif [ "$1" != "" ]; then
  TEXT="@here [INFO] logical drives mounted ${DRIVES_NUM} drives."
  TEXT+="

DRIVES:
"
  TEXT+="${DRIVES}"
  slack_post "${TEXT}"
fi

