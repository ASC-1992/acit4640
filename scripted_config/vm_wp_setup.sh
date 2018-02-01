### FIREWALL SECTION :D ###
firewall-cmd --zone=public --add-port=22/tcp --permanent
firewall-cmd --zone=public --add-port=80/tcp --permanent
firewall-cmd --zone=public --add-port=443/tcp --permanent

systemctl restart firewalld

yum install @core epel-release vim git tcpdump nmap-ncat curl -y

### NGINX PACKAGES ###
yum install nginx -y
systemctl start nginx
systemctl restart nginx

### MARIADB SETUP ###
yum install mariadb-server mariadb -yum