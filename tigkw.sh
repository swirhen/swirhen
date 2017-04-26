kill `cat /home/swirhen/tig.pid`
sleep 10
cd /home/swirhen/TIG
nohup /home/swirhen/TIG/TwitterIrcGateway --BroadcastUpdate=true --port=16668 --bind-address=0.0.0.0 --encoding=utf-8 --disable-userlist=true --set-topic-onstatuschanged=true --broadcast-update-message-is-notice=true --enable-compression=false --disable-notice-at-first-time=true --OAuthClientKey=Cjx5NIRxdYKuTbKZbZHfR1AVM --OAuthSecretKey=rYHeaHLwnaFOC3XG2qwcyy3yvHNSKvpJRjfHHcqDQqWB5ZZwVl >/dev/null 2>&1 & echo "TIG beta restarted at "`date` > /home/swirhen/tig.restart
