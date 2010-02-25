wget http://swirhen.bashi.org/filemanager.cgi -O /tmp/tmp.txt
grep member /tmp/tmp.txt > /tmp/myip.txt
ncftpput -u swirhen -p npQWBEDhhxy swirhen.bashi.org /public_html /tmp/myip.txt
rm /tmp/myip.txt /tmp/tmp.txt
