#!/usr/bin/env zsh
cd /data/share/movie
ls *.torrent
ST=`date +%s`
echo "`date '+%Y/%m/%d %H:%M:%S'` # torrent download start."
/data/share/movie/sh/tdlstop.sh 38888 &
/usr/bin/wine aria2c.exe --listen-port=38888 --max-upload-limit=200K --seed-ratio=0.01 --seed-time=1 *.torrent
ED=`date +%s`
ERAP=$(( ((${ED} - ${ST}) / 60) + 1 ))
echo "`date '+%Y/%m/%d %H:%M:%S'` # torrent download end."
find . -maxdepth 1 -type f -mmin -${ERAP}