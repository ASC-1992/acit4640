### INSTALL BASELINE CONFIG ###
yum install @core epel-release vim git tcpdump nmap-ncat curl wget -y

### FIREWALL SECTION :D ###
firewall-cmd --zone=public --add-port=22/tcp --permanent
firewall-cmd --zone=public --add-port=80/tcp --permanent
firewall-cmd --zone=public --add-port=443/tcp --permanent

systemctl restart firewalld


### NGINX PACKAGES ###
yum install nginx -y
systemctl start nginx
systemctl enable nginx
systemctl restart nginx

### MARIADB SETUP ###
yum install mariadb-server mariadb -y

mysql -u root < ./mariadb_security_config.sql

systemctl enable mariadb
systemctl restart mariadb


### PHP SETUP ###
yum install php php-mysql php-fpm -y

cp ./php.ini /etc/ -f
cp ./www.conf /etc/php-fpm.d/ -f


systemctl start php-fpm
systemctl enable php-fpm
systemctl restart php-fpm

cp ./nginx.conf /etc/nginx/ -f
cp ./info.php /usr/share/nginx/html/ -f

systemctl restart nginx


### WP SETUP ###
## DB CONFIGURATION ##
mysql -u root < ./wp_mariadb_config.sql

## WP SOURCE SETUP ##
wget http://wordpress.org/latest.tar.gz


tar xzvf latest.tar.gz


cp ./wp-config.php wordpress/ -f

rsync -avP wordpress/ /usr/share/nginx/html/

mkdir /usr/share/nginx/html/wp-content/uploads

chown -R admin:nginx /usr/share/nginx/html/*

### SSH CONFIGURATION ###
exit
admin
P@ssw0rd
cd /home/admin
cat acit_admin_id_rsa.pub >> ~/.ssh/authorized_keys
chmod 700 ~/.ssh
chmod 600 ~/.ssh/authorized_keys