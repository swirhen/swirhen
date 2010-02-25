if [ $# -gt 0 ]; then
  for a in "$@"
  do
    if [ -f "$a" ]; then
      ncftpput -u swirhen -p npQWBEDhhxy swirhen.bashi.org /public_html/archive/konoyarou "$a"
      /data/share/movie/tw.py "【konoyarou】$a"
    fi
  done
fi
