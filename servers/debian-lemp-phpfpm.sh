#!/bin/sh
#########################################################
#                                                       #
#   Name: Debian based LEMP generator                   #
#   Author: Diego Castagna (diegocastagna.com)          #
#   Description: Nginx, MariaDB and PHP-FPM.            #
#   Certificate will be deployed if supported.          #
#   All passwords are saved under /root directory       #
#   Common Usage: AWS User Data                         #
#   License: diegocastagna.com/license                  #
#                                                       #
#########################################################

# Variables - EDIT THIS!
DBUser="example"                    # Database User
DBName="example_com"                # Database Name (It will be automatically escaped)
WBMainURI="example.com"             # Main hostname (only one allowed, will be used for folders and files)
WBAliasURI="www.example.com"        # Aliases hostnames (space separated)
HtUser="phpmyadmin"                 # PHPMyAdmin htaccess User
CertsEmail="example@example.com"    # Email for certbot notifications

DBRootPass=$(openssl rand -base64 32)   # Auto-generated database root password
DBUserPass=$(openssl rand -base64 32)   # Auto-generated database user password
DBPMAPass=$(openssl rand -base64 32)    # Auto-generated phpmyadmin user password
HtPass=$(openssl rand -base64 32)       # Auto-generated htaccess password

PHPVersion=""       # Updated after installing the php package

## Main Program ##

# Checking if I'm root
if [ $(id -u) -ne 0 ]; then
    printf "This script must be run as root\n"
    exit 1;
fi

# Saving all generated passwords. FILE SHOULD BE DELETED LATER!
printf "Root:$DBRootPass\n" >> /root/dbpass.txt
printf "User:$DBUserPass\n" >> /root/dbpass.txt
printf "PHPMyAdmin:$DBPMAPass\n" >> /root/dbpass.txt
printf "Htaccess:$HtUser $HtPass\n" >> /root/dbpass.txt
chmod 600 /root/dbpass.txt

# Updating and upgrading packages
apt-get update -yq
apt-get dist-upgrade -yq

# Setting up nginx repo
apt-get install -yq gnupg2 lsb-release
wget https://nginx.org/keys/nginx_signing.key -O /root/nginx_signing.key
apt-key add nginx_signing.key
printf "deb https://nginx.org/packages/mainline/debian/ `lsb_release -cs` nginx
deb-src https://nginx.org/packages/mainline/debian/ `lsb_release -cs` nginx" > /etc/apt/sources.list.d/nginx.list

# Installing all the others packages
apt-get update -yq
printf "phpmyadmin phpmyadmin/dbconfig-install boolean true" | debconf-set-selections
printf "phpmyadmin phpmyadmin/mysql/admin-pass password $DBRootPass" | debconf-set-selections
printf "phpmyadmin phpmyadmin/app-password-confirm password $DBPMAPass" | debconf-set-selections
printf "phpmyadmin phpmyadmin/mysql/app-pass password $DBPMAPass" | debconf-set-selections
printf "phpmyadmin phpmyadmin/reconfigure-webserver multiselect apache2" | debconf-set-selections
apt-get install -yq nginx mariadb-server php-fpm php-mysqli php-cli php-yaml php-xml php-mbstring php-zip php-gd php-curl php-twig snapd phpmyadmin
printf PURGE | debconf-communicate phpmyadmin

PHPVersion=$(php -v | head -n 1 | cut -d " " -f 2 | cut -c 1-3)

# Installing certbot
snap install core
snap refresh core
snap install --classic certbot
ln -s /snap/bin/certbot /usr/bin/certbot

# Adding groups to users
usermod -aG nginx admin

# Creating scripts and backups folders
mkdir /root/scripts/
chmod 500 /root/scripts/
mkdir -p /root/backups/db/ /root/backups/files/
chmod -R 700 /root/backups/

# Creating root mysql automatic login file
printf "[client]
user='root'
password='$DBRootPass'" > /root/.my.cnf
chmod 400 /root/.my.cnf

# Default server
printf "server {
    listen 80 default_server;
    server_name _ "";
    root /var/www/default;

    location / {
        return 200 'Nothing to see here.';
        add_header Content-Type text/html;
    }

    access_log /var/log/nginx/access.log main;
    error_log /var/log/nginx/error.log error;
}" > /etc/nginx/conf.d/default.conf

# Configured hostname
printf "server {
    listen 80;
    root  /var/www/${WBMainURI}/www;
    server_name ${WBMainURI} ${WBAliasURI};

    access_log /var/log/nginx/${WBMainURI}_access.log main;
    error_log /var/log/nginx/${WBMainURI}_error.log error;

    location ~ \.php$ {
        fastcgi_pass   unix:/run/php/php-${WBMainURI}.sock;
        fastcgi_index  index.php;
        fastcgi_param  SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        include        fastcgi_params;
    }

    location /phpmyadmin {
        root /usr/share/;
        index index.php index.html index.htm;

        auth_basic 'PHPMyAdmin';
        auth_basic_user_file /usr/share/phpmyadmin/.htpasswd;

        location ~ ^/phpmyadmin/(.+\.php)$ {
            try_files \$uri =404;
            root /usr/share/;
            fastcgi_pass unix:/run/php/php-${WBMainURI}.sock;
            fastcgi_index index.php;
            fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
            include fastcgi_params;
        }

        location ~* ^/phpmyadmin/(.+\.(jpg|jpeg|gif|css|png|js|ico|html|xml|txt))$ {
            root /usr/share/;
        }
    }

    location ~ /\.ht {
        deny  all;
    }
}" > "/etc/nginx/conf.d/${WBMainURI}.conf"

# PHP-fpm
printf "[www]
user = nginx
group = nginx
listen = /run/php/php-${WBMainURI}.sock
listen.owner = nginx
listen.group = nginx
pm = dynamic
pm.max_children = 5
pm.start_servers = 2
pm.min_spare_servers = 1
pm.max_spare_servers = 3
php_admin_flag[log_errors] = on
php_admin_value[memory_limit] = 128M
php_admin_value[open_basedir] = /tmp/:/var/www/${WBMainURI}/"> "/etc/php/${PHPVersion}/fpm/pool.d/www.conf"

# Creating nginx virtualhost logs files
install -m 640 -o root -g adm /dev/null "/var/log/nginx/${WBMainURI}_error.log"
install -m 640 -o root -g adm /dev/null "/var/log/nginx/${WBMainURI}_access.log"

# Setting up webserver folders
rm -r "/var/www/html"
mkdir -p "/var/www/default"
mkdir -p "/var/www/${WBMainURI}/www/"
chown -R admin:admin "/var/www/"
chmod -R 775 "/var/www/${WBMainURI}/"
chmod -R g+s "/var/www/${WBMainURI}/"

# Password for phpmyadmin page
htpasswd -bc /usr/share/phpmyadmin/.htpasswd "$HtUser" "$HtPass"

# Disabling insecure PHP functions
sed --follow-symlinks -i "/^disable_functions = / s/$/\passthru,shell_exec,system,proc_open,popen,parse_ini_file,show_source,/" "/etc/php/${PHPVersion}/fpm/php.ini"
# Excluding Notice and Warning error reporting
sed --follow-symlinks -i "/^error_reporting =/c\error_reporting = E_ALL \& ~E_DEPRECATED \& ~E_STRICT \& ~E_NOTICE \& ~E_WARNING" "/etc/php/${PHPVersion}/fpm/php.ini"
# Disabling url_fopen
sed --follow-symlinks -i "/^allow_url_fopen =/c\allow_url_fopen = Off" "/etc/php/${PHPVersion}/fpm/php.ini"

# Enabling extra PHP modules
phpenmod mbstring

# Basic database setup
ExDBName=$(printf "$DBName" | sed -E 's/[_]+/\\_/g')
mysql -u root <<_EOF_
ALTER USER 'root'@'localhost' IDENTIFIED BY '${DBRootPass}';
DELETE FROM mysql.user WHERE User='';
DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');
DROP DATABASE IF EXISTS `test`;
DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';
CREATE DATABASE `${DBName}`;
CREATE USER '${DBUserName}'@'localhost' IDENTIFIED BY '${DBUserPass}';
GRANT ALL PRIVILEGES ON `${ExDBName}`.* TO '${DBUserName}'@'localhost';
FLUSH PRIVILEGES;
_EOF_

# Requesting certificates for domains
domains="$(printf "$WBMainURI $WBAliasURI" | sed -E 's/ /,/g;')"
certbot --nginx -n --agree-tos -m "$WBEmail" -d "$domains"

# Deleting .ssh folder
rm -r /root/.ssh
rm /root/nginx_signing.key

# Some personal customization
printf "" > /etc/motd                               # Removing default motd
printf "\nalias ll='ls -alF'\n" >> /etc/profile     # Adding ll alias

# Cleaning and exiting
apt-get autoremove -yq
apt-get autoclean -yq

# Restarting services with new configurations
service nginx stop
service nginx start
service "php${PHPVersion}-fpm" restart
service mariadb restart

touch /root/.done