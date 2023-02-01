#!/bin/bash
#ps -ef | grep tiarra.conf | grep -v grep | awk '{print $2}' | xargs kill -9
#sleep 10
#nohup /home/swirhen/sh/perlenv.sh /home/swirhen/tiarra/tiarra --config=/home/swirhen/tiarra/tiarra.conf >/dev/null 2>&1 &
docker kill `cat /home/swirhen/tiarra/docker.id`
sleep 5
cd /home/swirhen/tiarra
docker run --name tiarra --network host -d --rm -v /home/swirhen/tiarra/:/tiarra/ -v /var/www/tm/:/var/www/tm/ swirhen/perl4tiarra /bin/sh -c '/tiarra/tiarra --config=/tiarra/tiarra.conf > /tiarra/tiarra.log' > docker.id
sleep 5
/usr/bin/php /home/swirhen/tiasock/tiasock.php "#Console@t" "g"
