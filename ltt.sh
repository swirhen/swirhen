/usr/bin/cgt twitter-web `date '+%m%d'` . > /tmp/ltt.txt
ncftpput -u swirhen -p npQWBEDhhxy swirhen.bashi.org /public_html/log /tmp/ltt.txt
rm -rf /tmp/ltt.txt

