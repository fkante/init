#as root
su -
apt-get update -y && apt-get upgrade -y
apt-get install sudo vim ufw portsentry fail2ban apache2 mailutils -y

adduser kante sudo
visudo
	|| under root
    || added kante    ALL=(ALL:ALL) NOPASSWD:ALL

#Setup a static IP
sudo vim /etc/network/interfaces
    || The primary network interface
    || auto enp0s3
sudo vim /etc/network/interfaces.d/enp0s3
    || iface enp0s3 inet static
    ||         address 10.12.1.108/30
    ||         netmask 255.255.255.252
    ||         gateway 10.12.254.254
sudo service networking restart
ip a
#Change SSH default Port
sudo vim /etc/ssh/sshd_config
    || Uncommented ligne 13: “Port 65432”
ssh roger@10.12.1.130 -p 65432
#Setup SSH access with publickeys
ssh-keygen -t rsa
    || passphrase: roger
ssh-copy-id -i ~/.ssh/id_rsa.pub roger@10.12.1.108 -p 65432
sudo vim /etc/ssh/sshd_config
    || Uncommented ligne 32: “PermitRootLogin no”
    || Uncommented ligne 56: “PasswordAuthentication no”
sudo service sshd restart

#setup firewall

#check
sudo ufw status
sudo ufw enable
sudo ufw allo 65432/tcp
sudo ufw allow 80/tcp
sudo ufw allow 443

sudo vim /etc/fail2ban/jail.d/custom.conf
--------------------------------------------
[DEFAULT]
ignoreip = 127.0.0.1
findtime = 3600
bantime = 86400
maxretry = 3

[sshd]
enabled = true
port = 65432
logpath = /var/log/auth.log
maxretry = 5

[http-get-dos]
enabled = true
port = http,https
filter = http-get-dos
logpath = /var/log/apache2/access.log
maxretry = 100
findtime = 30
bantime = 6000
action = iptables[name=HTTP, port=http, protocol=tcp]
------------------------------------------------------

sudo vim /etc/fail2ban/filter.d/http-get-dos.conf
------------------------------------------------------
[Definition]
failregex = ^<HOST> -.*"(GET|POST).*
ignoreregex =
------------------------------------------------------

sudo vim /etc/ufw/before.rules
------------------------------------------------------
# Allow ping
-A ufw-before-output -p icmp --icmp-type destination-unreachable -j ACCEPT
-A ufw-before-output -p icmp --icmp-type source-quench -j ACCEPT
-A ufw-before-output -p icmp --icmp-type time-exceeded -j ACCEPT
-A ufw-before-output -p icmp --icmp-type parameter-problem -j ACCEPT
-A ufw-before-output -p icmp --icmp-type echo-request -j ACCEPT
------------------------------------------------------------

sudo ufw reload
sudo service fail2ban restart

sudo vim /etc/default/portsentry
edit line 9 and  10 to
TCP_MODE="atcp"
UDP_MODE="audp"

sudo vim /etc/default/portsentry
edit line 136 and 137 to
BLOCK_UDP="1"
BLOCK_TCP="1"

sudo vim /etc/portsentry/portsentry.conf
comment line 171 actual kill route and uncomment line 210
KILL_ROUTE="/sbin/iptables -I INPUT -s $TARGET$ -j DROP"
dont uncomment line 244 KILL_HOSTS_DENY="ALL: $TARGET$ : DENY

sudo service portsentry restart

test with nmap -vv ipaddres
sudo tail -n 5 /var/log/syslog

find all open ports: sudo lsof -i

sudo service --status-all

#disable the service we don't need
sudo systemctl disable console-setup.service
sudo systemctl disable keyboard-setup.service
sudo systemctl disable apt-daily.timer
sudo systemctl disable apt-daily-upgrade.timer
sudo systemctl disable syslog.service

touch /root/update.sh
echo "sudo apt-get update -y >> /var/log/update_script.log" >> ~/update.sh
echo "sudo apt-get upgrade -y >> /var/log/update_script.log" >> ~/update.sh

touch /root/cronMonitor.sh
#!/bin/bash

FILE="/var/tmp/crontab_checksum"
FILE_TO_WATCH="/etc/crontab"
SHA1VALUE=$(sudo sha1sum $FILE_TO_WATCH)

if [ ! -f $FILE ]
then
	 echo "$SHA1VALUE" > $FILE
	 exit 0;
fi;

if [ "$SHA1VALUE" != "$(cat $FILE)" ];
	then
	echo "$SHA1VALUE" > $FILE
	echo "$FILE_TO_WATCH has been modified ! ༼ つ ಥ_ಥ ༽つ*" | mail -s "$FILE_TO_WATCH modified !" root
fi;

sudo crontab -e
@reboot sudo sh ~/update.sh
0 4 * * 1 sudo sh ~/update.sh
0 0 * * * sudo sh ~/cronMonitor.sh

sudo systemctl enable cron

#Generating a Self-Signed Certificate
sudo apt-get install apache2 && sudo systemctl start apache2
openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout roger.key -out roger.crt
--------------------------------------------------------------------------------
 +<VirtualHost *:443>
   +    DocumentRoot /var/www/domainname/Roger_Skyline
   +    ServerName domainname
   +    SSLEngine on
   +    SSLCertificateFile /etc/ssl/certs/roger.crt
   +    SSLCertificateKeyFile /etc/ssl/certs/roger.key
   +</VirtualHost>
--------------------------------------------------------------------------------

sudo a2enmod ssl
systemctl restart apache2
systemctl status apache2
