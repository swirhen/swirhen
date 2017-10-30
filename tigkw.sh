#!/usr/bin/env zsh
kill `cat /home/swirhen/tig.pid`
sleep 5
cd /home/swirhen/TIG
#nohup /home/swirhen/TIG/TwitterIrcGateway --BroadcastUpdate=true --port=16668 --encoding=utf-8 --disable-userlist=true --set-topic-onstatuschanged=true --broadcast-update-message-is-notice=true --enable-compression=false --disable-notice-at-first-time=true --OAuthClientKey=Cjx5NIRxdYKuTbKZbZHfR1AVM --OAuthSecretKey=rYHeaHLwnaFOC3XG2qwcyy3yvHNSKvpJRjfHHcqDQqWB5ZZwVl  --bind-address=0.0.0.0 &
nohup /home/swirhen/TIG/TwitterIrcGateway --BroadcastUpdate=true --port=16668 --encoding=utf-8 --disable-userlist=true --set-topic-onstatuschanged=true --broadcast-update-message-is-notice=true --enable-compression=false --disable-notice-at-first-time=true --OAuthClientKey=PVWGw9NYJcIO1zJv3jbv35io3 --OAuthSecretKey=rllcZQkfbXzElgfYWFyaRkudstpMkTo9EDPlaAOSHsa0sF0pLe --bind-address=0.0.0.0 &
