kill `cat /home/swirhen/tig.pid`
sleep 10
nohup /home/swirhen/TIG/TwitterIrcGateway --BroadcastUpdate=true --port=16668 --bind-address=192.168.0.51 --encoding=utf-8 --disable-userlist=true --set-topic-onstatuschanged=true --broadcast-update-message-is-notice=true --enable-compression=false --disable-notice-at-first-time=true >/dev/null 2>&1 &
#/home/swirhen/TIG/TwitterIrcGateway --BroadcastUpdate=true --port=16668 --bind-address=192.168.0.51 --encoding=utf-8 --disable-userlist=true --set-topic-onstatuschanged=true --broadcast-update-message-is-notice=true --enable-compression=false --disable-notice-at-first-time=true &
echo "TIG restarted at "`date` > /home/swirhen/tig.restart
