#!/bin/bash
CHANNEL=$1
POST=$2
if [ ${#POST} -gt 140 ]; then
  POST="${POST:0:137}(ry"
fi

/usr/bin/php /home/swirhen/tiasock/tiasock.php "${CHANNEL}" "${POST}"