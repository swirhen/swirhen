killall tunnel-server.exe
#killall TunnelSVR.exe
#killall wineserver
rm -f /home/swirhen/mhptunnel/err*
sleep 10
/usr/bin/wine /home/swirhen/mhptunnel/tunnel-server.exe > /dev/null &
#nohup /usr/bin/wine /home/swirhen/mhptunnel/TunnelSVR.exe 30001 &
