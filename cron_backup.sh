#!/usr/bin/env bash
# cronのバックアップ
cd /home/swirhen/sh1
crontab -l > crontab.backup

git commit -m 'crontab backup' crontab.backup
git pull
git push origin master
