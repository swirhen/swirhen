#!/usr/bin/env bash
# ip updater
CHANNEL="bot-open"

curl -sS "https://dyn.value-domain.com/cgi-bin/dyn.fcg?ip" | grep ".*\..*\..*\..*" > /tmp/myip.txt
DOMAIN_IP=`dig @8.8.8.8 swirhen.tv | grep ANSWER -A 1 | grep swirhen.tv | awk '{print $5}'`
if [ "${DOMAIN_IP}" = "" ]; then
    sleep 5
    DOMAIN_IP=`dig @8.8.4.4 swirhen.tv | grep ANSWER -A 1 | grep swirhen.tv | awk '{print $5}'`
fi
if [ "`cat /tmp/myip.txt`" != "" ]; then
    if [ "`cat /tmp/myip.txt`" != "`cat /home/swirhen/Dropbox/temp/myip.txt`" ]; then
        TEXT="@channel [ALERT] chenges globalip on swirhen.tv: `cat /tmp/myip.txt`"
        python /data/share/movie/sh/python-lib/swirhentv_util.py discord_post -i "${CHANNEL}" "${TEXT}"
    elif [ "$1" != "" ]; then
        TEXT="@here [INFO] swirhen.tv globalip is: `cat /tmp/myip.txt`"
        TEXT+="
        "
        TEXT+="dns ip check: ${DOMAIN_IP}"
        python /data/share/movie/sh/python-lib/swirhentv_util.py discord_post -i "${CHANNEL}" "${TEXT}"
    fi
    if [ "`cat /tmp/myip.txt`" != "${DOMAIN_IP}" ]; then
        TEXT="@channel [ALERT] DNS not updates on swirhen.tv: ${DOMAIN_IP}"
        python /data/share/movie/sh/python-lib/swirhentv_util.py discord_post -i "${CHANNEL}" "${TEXT}"
        curl "https://dyn.value-domain.com/cgi-bin/dyn.fcg?d=swirhen.tv&p=irankae1"
    fi

    mv /tmp/myip.txt /home/swirhen/Dropbox/temp/
fi
