#!/bin/sh
PYTHON_PATH="python3"
CHANNEL="bot-open"

slack_post() {
    ${PYTHON_PATH} /home/swirhen/sh/slack_post.py "${CHANNEL}" "$1"
}

echo "`date`"
mysqllive=`systemctl status mysql | grep Active | grep running`

if [ "${mysqllive}" != "" ]; then
    echo "mysql live."
else
    error=0
    until [ "${mysqllive}" != "" ];
    do
        (( error++ ))
        if [ $error -gt 5 ]; then
            break;
        fi
        sudo systemctl restart mysql
        mysqllive=`systemctl status mysql | grep Active | grep running`
    done
    if [ $error -gt 5 ]; then
        TEXT="@channel [ALERT] mysql service has gone and restart failed."
        slack_post "${TEXT}"
    elif [ "$1" != "" ]; then
        /home/swirhen/sh/tiarrakw.sh
        TEXT="@here [INFO] mysql service has gone. restart ok and tiarra restarted. irssi must be re-connect."
        slack_post "${TEXT}"
    fi
fi