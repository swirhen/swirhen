#!/usr/bin/env zsh
cd /data/share/movie
/usr/bin/wine aria2c.exe --listen-port=38888 --max-upload-limit=200K --seed-ratio=0.01 --seed-time=1 *.torrent
/data/share/movie/sh/tdlstop.sh 38888