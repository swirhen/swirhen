killall tiarra
killall keitairc
killall keitaircb
sleep 10
cd /home/swirhen
nohup /home/swirhen/tiarra/tiarra --config=/home/swirhen/tiarra/tiarra.conf >/dev/null 2>&1 &
nohup /home/swirhen/tiarra/tiarra --config=/home/swirhen/tiarra/jimae-.conf >/dev/null 2>&1 &
nohup /home/swirhen/keitairc >/dev/null 2>&1 &
nohup /home/swirhen/keitaircb >/dev/null 2>&1 &
