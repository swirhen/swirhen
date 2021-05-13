#!/usr/bin/env bash
# data drive checker
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE:-$0}")"; pwd)"
PYTHON_PATH="python3"
CHANNEL="bot-open"
#CHANNEL="bot-sandbox"
DRIVES_NUM_CORRECT=8

slack_post() {
  ${PYTHON_PATH} /home/swirhen/sh/slackbot/swirhentv/post.py "${CHANNEL}" "$1"
}

slack_upload() {
  /usr/bin/curl -F channels="${CHANNEL}" -F file="@$1" -F title="$2" -F token=`cat ${SCRIPT_DIR}/token` -F filetype=text https://slack.com/api/files.upload
}

DRIVES=`df -h | grep data`
DRIVES_NUM=`echo "${DRIVES}" | wc -l`

error=0
until [ ${DRIVES_NUM} -eq ${DRIVES_NUM_CORRECT} ];
do
  (( error++ ))
  sudo /usr/bin/mount -a
  if [ $error -gt 5 ]; then
    break;
  fi
  DRIVES=`df -h | grep data`
  DRIVES_NUM=`echo "${DRIVES}" | wc -l`
done

if [ $error -gt 5 ]; then
  TEXT="@channel [ALERT] logical drives mounted not ${DRIVES_NUM_CORRECT} drives. tring re-mount."
  TEXT+="

DRIVES:
"
  TEXT+="${DRIVES}"
  slack_post "${TEXT}"
elif [ "$1" != "" ]; then
  TEXT="@here [INFO] logical drives mounted ${DRIVES_NUM} drives."
  TEXT+="

DRIVES:
"
  TEXT+="${DRIVES}"
  slack_post "${TEXT}"
fi

