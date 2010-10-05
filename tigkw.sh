kill `cat /home/swirhen/tig.pid`
sleep 10
nohup /home/swirhen/TIG/TwitterIrcGateway --BroadcastUpdate=true --port=16668 --bind-address=0.0.0.0 --encoding=utf-8 --disable-userlist=true --set-topic-onstatuschanged=true --broadcast-update-message-is-notice=true --enable-compression=false --disable-notice-at-first-time=true >/dev/null 2>&1 & echo "TIG beta restarted at "`date` > /home/swirhen/tig.restart
