#!/usr/bin/env bash
# ip updater
PYTHON_PATH="python3"
CHANNEL="bot-open"
DRIVES_NUM_CORRECT=8

slack_post() {
  ${PYTHON_PATH} /home/swirhen/sh/slackbot/swirhentv/post.py "${CHANNEL}" "$1"
}

slack_upload() {
  /usr/bin/curl -F channels="${CHANNEL}" -F file="@$1" -F title="$2" -F token=`cat ${SCRIPT_DIR}/token` -F filetype=text https://slack.com/api/files.upload
}

wget "https://dyn.value-domain.com/cgi-bin/dyn.fcg?ip" -O /tmp/myip.txt
DOMAIN_IP=`dig @8.8.8.8 swirhen.tv | grep ANSWER -A 1 | grep swirhen.tv | awk '{print $5}'`
if [ "`cat /tmp/myip.txt`" != "`cat /home/swirhen/Dropbox/temp/myip.txt`" ]; then
  TEXT="@channel [ALERT] chenges globalip on swirhen.tv: `cat /tmp/myip.txt`"
  slack_post "${TEXT}"
elif [ "$1" != "" ]; then
  TEXT="@here [INFO] swirhen.tv globalip is: `cat /tmp/myip.txt`"
  TEXT+="
"
  TEXT+="dns ip check: ${DOMAIN_IP}"
  slack_post "${TEXT}"
fi
if [ "`cat /tmp/myip.txt`" != "${DOMAIN_IP}" ]; then
  TEXT="@channel [ALERT] DNS not updates on swirhen.tv: ${DOMAIN_IP}"
  slack_post "${TEXT}"
fi

mv /tmp/myip.txt /home/swirhen/Dropbox/temp/
wget -O - "https://dyn.value-domain.com/cgi-bin/dyn.fcg?d=swirhen.tv&p=irankae1&h=*" > /dev/null 2>&1
