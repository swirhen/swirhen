#!/bin/bash
docker kill `cat /home/swirhen/tiarra/docker.id`
#ps -ef | grep tiarra.conf | grep -v grep | awk '{print $2}' | xargs kill -9
sleep 5
cd /home/swirhen/tiarra
docker run --name tiarra --network host -d --rm -v /home/swirhen/tiarra/:/tiarra/ -v /var/www/tm/:/var/www/tm/ perl-tiarra /bin/sh -c '/tiarra/tiarra --config=/tiarra/tiarra.conf' > docker.id
#nohup /home/swirhen/sh/perlenv.sh /home/swirhen/tiarra/tiarra --config=/home/swirhen/tiarra/tiarra.conf >/dev/null 2>&1 &
