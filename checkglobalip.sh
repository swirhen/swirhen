#!/bin/sh
IPFILE='/tmp/globalip'

PREVIP=`cat $IPFILE` 2>/dev/null
IP=`curl inet-ip.info` 2>/dev/null

echo "`date`"
if [ "$IP" != "" ]; then
  echo "Global IP address: $IP"

  if [ "$PREVIP" != "$IP" ]; then
    echo $IP > $IPFILE
    if [ "$PREVIP" != "" ]; then
      echo "Global IP address changed from $PREVIP"
      echo
      whois -h whois.nic.ad.jp $IP | grep -Eo '[0-9]{1,3}\.[0-9]{1,3}\.\S*' | tr '\n' ' '
      exit 1
    fi
  fi
else
  echo "Can't get IP address"
  exit 1
fi

return 0
