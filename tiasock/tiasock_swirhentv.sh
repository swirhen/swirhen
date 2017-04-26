#!/bin/bash
POST=$1
if [ ${#POST} > 140 ]; then
  POST="${POST:0:137}(ry"
fi

/usr/bin/php /home/swirhen/tiasock/tiasock.php "#Twitter@t2" "${POST}"