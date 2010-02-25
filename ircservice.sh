killall tiarra
killall keitairc
killall ruby
#killall bitlbee
sleep 10
cd /home/swirhen
nohup /home/swirhen/tiarra/tiarra --config=/home/swirhen/tiarra/tiarra.conf >/dev/null 2>&1 &
nohup /home/swirhen/keitairc >/dev/null 2>&1 &
#nohup /usr/sbin/bitlbee >/dev/null 2>&1 &
nohup /usr/bin/ruby /home/swirhen/ruby-hig/hig.rb -p 36672 -h 192.168.0.51 >/dev/null 2>&1 &
