#!/usr/bin/env zsh
cd /data/share/movie
echo "`date '+%Y/%m/%d %H:%M:%S'` rm *.torrent"
rm *.torrent
echo "`date '+%Y/%m/%d %H:%M:%S'` movie files rename start."
/data/share/movie/sh/mre.sh
echo "`date '+%Y/%m/%d %H:%M:%S'` movie files rename end."
