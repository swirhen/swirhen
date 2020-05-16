#!/usr/bin/env bash
sudo docker kill `cat /home/swirhen/TIG/docker.id`
sleep 5
cd /home/swirhen/TIG
sudo docker run -d --rm -v /home/swirhen/TIG/:/app/ -p 16668:16668 mono:4.8 /bin/sh -c 'mono /app/TwitterIrcGatewayCLI.exe --BroadcastUpdate=true --port=16668 --encoding=utf-8 --disable-userlist=true --set-topic-onstatuschanged=true --broadcast-update-message-is-notice=true --enable-compression=false --disable-notice-at-first-time=true --OAuthClientKey=ZHt8Txf7vmHmWr4PzNQ5okFgf --OAuthSecretKey=f7QdBhK8GVsIIHyO8GQjEJ44OxG3m6p7lNjQ2zZXYlHpFIRV91 --bind-address=0.0.0.0' > docker.id
#nohup /home/swirhen/TIG/TwitterIrcGateway --BroadcastUpdate=true --port=16668 --encoding=utf-8 --disable-userlist=true --set-topic-onstatuschanged=true --broadcast-update-message-is-notice=true --enable-compression=false --disable-notice-at-first-time=true --OAuthClientKey=ZHt8Txf7vmHmWr4PzNQ5okFgf --OAuthSecretKey=f7QdBhK8GVsIIHyO8GQjEJ44OxG3m6p7lNjQ2zZXYlHpFIRV91 --bind-address=0.0.0.0 &
