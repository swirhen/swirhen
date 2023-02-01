#!/bin/sh
PYTHON_PATH="python3"
CHANNEL="bot-open"

slack_post() {
    ${PYTHON_PATH} /home/swirhen/sh/slack_post.py "${CHANNEL}" "$1"
}

echo "`date`"
# mysqllive=`systemctl status mysql | grep Active | grep running`

# if [ "${mysqllive}" != "" ]; then
#     echo "mysql live."
mysqlerror=`tail -10 /home/swirhen/tiarra/tiarra.log | grep "Lost connection to MySQL server"`

if [ "${mysqlerror}" = "" ]; then
    echo "mysql and tiarra connection is normal."
else
    sudo systemctl restart mysql
    sleep 5
    /home/swirhen/sh/tiarrakw.sh
    TEXT="@here [INFO] mysql and tiarra connection is error. mysql and tiarra restarted. irssi must be re-connect."
    slack_post "${TEXT}"
fi