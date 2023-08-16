#!/usr/bin/env bash
# data drive checker
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE:-$0}")"; pwd)"
PYTHON_PATH="python3"
CHANNEL="bot-open"
#CHANNEL="bot-sandbox"
DRIVES_NUM_CORRECT=8

slack_post() {
  ${PYTHON_PATH} /home/swirhen/sh/slack_post.py "${CHANNEL}" "$1"
}

slack_upload() {
  /usr/bin/curl -F channels="${CHANNEL}" -F file="@$1" -F title="$2" -F token=`cat ${SCRIPT_DIR}/token` -F filetype=text https://slack.com/api/files.upload
}

timeout 5 df | grep data > /dev/null
if [ $? -eq 0 ]; then
    DRIVES=`df -h | grep data`
    DRIVES_NUM=`echo "${DRIVES}" | wc -l`
else
    NFS_ISDEAD=`/usr/bin/ssh 192.168.0.109 -p 49880 sudo systemctl status nfs-server | grep Active | grep dead | wc -l`
    if [ ${NFS_ISDEAD} -eq 1 ]; then
        /usr/bin/ssh 192.168.0.109 -p 49880 sudo systemctl start nfs-server
        sleep 10
    fi
    timeout 5 df | grep data > /dev/null
    if [ $? -eq 0 ]; then
        DRIVES=`df -h | grep data`
        DRIVES_NUM=`echo "${DRIVES}" | wc -l`
    else
        slack_post "@channel [ALERT] df command timeout: logical drives mount check progress."
        exit 1
    fi
fi

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

