wget http://www.luft.co.jp/cgi/ipcheck.php -O /tmp/myip.html
#wget http://swirhen.net/cgi-bin/ipcheck.cgi -O /tmp/myip.html
#grep name=\"IP\" /tmp/tmp.html | cut -d" " -f4 | cut -d"\"" -f2 > /tmp/myip.txt
cp /tmp/myip.html /home/swirhen/Dropbox/temp/
#ncftpput -u swirhen -p irankae swirhen.net /httpdocs /tmp/myip.html
#ncftpput -u swirhen -p irankae swirhen.net /httpdocs /tmp/myip.html
#rm /tmp/myip.html /tmp/tmp.txt
rm /tmp/myip.html
