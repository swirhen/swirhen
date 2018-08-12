#!/usr/bin/env bash
# もろもろバックアップ
sudo cp -rp /etc/bind/named.conf ~/Dropbox/config/bind/
sudo cp -rp /etc/bind/named.conf.default-zones ~/Dropbox/config/bind/
sudo cp -rp /etc/bind/named.conf.local ~/Dropbox/config/bind/
sudo cp -rp /etc/bind/named.conf.options ~/Dropbox/config/bind/
sudo cp -rp /etc/bind/swirhen.tv ~/Dropbox/config/bind/
sudo cp -rp /etc/bind/0.168.192.in-addr.arpa ~/Dropbox/config/bind/
sudo cp -rp /etc/dhcp/dhcpd.conf ~/Dropbox/config/
sudo cp -rp /etc/fstab ~/Dropbox/config/
#sudo cp -rp 
tar zcvf ~/Dropbox/config/www.tgz /var/www
tar zcvf ~/Dropbox/config/ssh.tgz ~/.ssh
