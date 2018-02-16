#!/bin/bash
ps -ef | grep tiarra.conf | grep -v grep | awk '{print $2}' | xargs kill -9
sleep 10
cd /home/swirhen
nohup /home/swirhen/tiarra/tiarra --config=/home/swirhen/tiarra/tiarra.conf >/dev/null 2>&1 &
