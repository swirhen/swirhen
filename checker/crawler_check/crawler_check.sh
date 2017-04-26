#!/bin/bash
FILE=~/crawler_check/$1
URI="$2"
HIT_ST="$3"
HIT_ED="$4"

if [ "${HIT_ST}" != "" -a "${HIT_ED}" != "" ]; then
  curl "${URI}" | sed -n "/${HIT_ST}/,/${HIT_ED}/p" > "${FILE}"
else
  curl "${URI}" > "${FILE}"
fi

if [ "`diff ${FILE} ${FILE}.old`" != "" ]; then
  /home/swirhen/tiasock/tiasock_swirhentv.sh "d swirhen `date` クローラチェック差分あり チェックID: $1 URL:${URI}"
fi

mv ${FILE} ${FILE}.old
