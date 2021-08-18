#!/bin/sh
#########################################################
#                                                       #
#   Name: Debian Webserver Generator                    #
#   Author: Diego Castagna (diegocastagna.com)          #
#   Description: This script will set-up                #
#   a webserver with Apache2, MariaDB, PHP              #
#   and PHPMyAdmin, all passwords                       #
#   are saved under /root directory                     #
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

# Constants - Editing this is up to you!
AWSCliUrl="https://www.diegocastagna.com/files/aws/awscli.tar.xz"
PHPVersion="7.3"
PHPType="fpm" # fpm (recommended) / mod

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

# Updating and installing packages
apt update -yq
apt dist-upgrade -yq
printf "phpmyadmin phpmyadmin/dbconfig-install boolean true" | debconf-set-selections
printf "phpmyadmin phpmyadmin/mysql/admin-pass password $DBRootPass" | debconf-set-selections
printf "phpmyadmin phpmyadmin/app-password-confirm password $DBPMAPass" | debconf-set-selections
printf "phpmyadmin phpmyadmin/mysql/app-pass password $DBPMAPass" | debconf-set-selections
printf "phpmyadmin phpmyadmin/reconfigure-webserver multiselect apache2" | debconf-set-selections
apt install -yqt buster-backports php-twig
apt install -yq apache2 mariadb-server php libapache2-mod-php php-mysqli php-cli php-yaml php-xml php-mbstring php-zip php-gd php-curl php-twig snapd phpmyadmin
printf PURGE | debconf-communicate phpmyadmin

# Installing certbot
snap install core
snap refresh core
snap install --classic certbot
ln -s /snap/bin/certbot /usr/bin/certbot

# Creating gitlab user and .ssh files
adduser --disabled-password gitlab
mkdir -p /home/gitlab/.ssh
touch /home/gitlab/.ssh/authorized_keys
chown -R gitlab.gitlab /home/gitlab/.ssh/
chmod 700 /home/gitlab/.ssh/
chmod 600 /home/gitlab/.ssh/authorized_keys

# Generating SSH key for gitlab user
ssh-keygen -b 4096 -t rsa -m PEM -C "gitlab@$WBMainURI" -f "/root/gitlab-runner.pem" -N ""
cat /root/gitlab-runner.pem.pub > /home/gitlab/.ssh/authorized_keys
chmod 600 /root/gitlab-runner.pem /root/gitlab-runner.pem.pub

# Adding groups to users
usermod -aG www-data,gitlab admin
usermod -aG www-data gitlab

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

# Updating AWS Cli
apt -yq remove awscli
wget -U "Mozilla/5.0 (Macintosh; Intel Mac OS X 11_4) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.164 Safari/537.36" -O /root/awscli.tar.xz "$AWSCliUrl"
tar -xf /root/awscli.tar.xz -C /root/
bash /root/aws/install
rm -r /root/aws/
rm /root/awscli.tar.xz

# Ehnancing Apache2 security
printf 'ServerTokens Prod
ServerSignature Off
TraceEnable Off
<DirectoryMatch "/\.git">
    Require all denied
</DirectoryMatch>' > /etc/apache2/conf-available/security_enhanced.conf

# Enabling htaccess rewrite and password login on phpmyadmin page
sed --follow-symlinks -i "/DirectoryIndex index.php/a\    AllowOverride All" /etc/apache2/conf-available/phpmyadmin.conf
printf 'AuthType Basic
Authname "Restricted files"
AuthUserFile /etc/phpmyadmin/.htpasswd
Require valid-user' > /usr/share/phpmyadmin/.htaccess
htpasswd -bc /etc/phpmyadmin/.htpasswd "$HtUser" "$HtPass"

# Enhancing SSLProtocol
sed --follow-symlinks -i "/SSLProtocol all -SSLv3/c\        SSLProtocol all -SSLv3 -TLSv1 -TLSv1.1" /etc/apache2/mods-available/ssl.conf

# Enhancing PHP Security
sed --follow-symlinks -i "/^disable_functions =/ s/$/\passthru,shell_exec,system,proc_open,popen,parse_ini_file,show_source,/" "/etc/php/${PHPVersion}/apache2/php.ini"       # Disabling insecure PHP functions
sed --follow-symlinks -i "/^error_reporting =/c\error_reporting = E_ALL \& ~E_DEPRECATED \& ~E_STRICT \& ~E_NOTICE \& ~E_WARNING" "/etc/php/${PHPVersion}/apache2/php.ini"     # Excluding Notice and Warning error reporting
sed --follow-symlinks -i "/^allow_url_fopen =/c\allow_url_fopen = Off" "/etc/php/${PHPVersion}/apache2/php.ini"          # Disabling url_fopen

# Basic Apache2 setup
a2disconf charset javascript-common other-vhosts-access-log serve-cgi-bin localized-error-pages security
a2dismod status
a2enconf security_enhanced phpmyadmin
a2enmod rewrite headers ssl expires
printf "<VirtualHost *:80>
    ServerAlias ${WBAliasURI}
    ServerName ${WBMainURI}
    ServerAdmin webmaster@localhost
    DocumentRoot /var/www/${WBMainURI}/www

    LogLevel error
    ErrorLog \${APACHE_LOG_DIR}/${WBMainURI}_error.log
    CustomLog \${APACHE_LOG_DIR}/${WBMainURI}_access.log combined

    <Directory /var/www/${WBMainURI}/www/>
        Options -Indexes +SymLinksIfOwnerMatch -Includes
        AllowOverride All
    </Directory>
</VirtualHost>" > /etc/apache2/sites-available/000-default.conf
a2ensite 000-default.conf

# Enabling extra PHP modules
phpenmod mbstring

# Creating apache2 virtualhost logs files
install -m 640 -o root -g adm /dev/null "/var/log/apache2/${WBMainURI}_error.log"
install -m 640 -o root -g adm /dev/null "/var/log/apache2/${WBMainURI}_access.log"

# Setting up webserver folders
rm -r "/var/www/html"
mkdir -p "/var/www/$WBMainURI/www/"
chown admin:admin "/var/www/$WBMainURI/"
chown gitlab:gitlab "/var/www/$WBMainURI/www/"
chmod -R 775 "/var/www/$WBMainURI/"
chmod -R g+s "/var/www/$WBMainURI/"

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

# If PHP-FPM enable other settings
if [ "$PHPType" = "fpm" ]; then
    apt install -yq php-fpm libapache2-mod-fcgid
    a2dismod "php$PHPVersion" mpm_prefork
    a2enmod mpm_event proxy_fcgi proxy
    a2enconf "php$PHPVersion-fpm"
    install -m 640 -o www-data -g www-data /dev/null "/var/log/php-${WBMainURI}.log"
    sed --follow-symlinks -i '/fcgi:\/\/localhost"/a\        ProxyErrorOverride On' "/etc/apache2/conf-available/php$PHPVersion-fpm.conf"   # Adding ProxyErrorOverride to apache2 conf
    sed --follow-symlinks -i "/^disable_functions = / s/$/\passthru,shell_exec,system,proc_open,popen,parse_ini_file,show_source,/" "/etc/php/${PHPVersion}/fpm/php.ini"       # Disabling insecure PHP functions
    sed --follow-symlinks -i "/^error_reporting =/c\error_reporting = E_ALL \& ~E_DEPRECATED \& ~E_STRICT \& ~E_NOTICE \& ~E_WARNING" "/etc/php/${PHPVersion}/fpm/php.ini"      # Excluding Notice and Warning error reporting
    sed --follow-symlinks -i "/^allow_url_fopen =/c\allow_url_fopen = Off" "/etc/php/${PHPVersion}/fpm/php.ini"         # Disabling url_fopen

    # Configuring default pool
    printf "[www]
user = www-data
group = www-data
listen = /run/php/php${PHPVersion}-fpm.sock
listen.owner = www-data
listen.group = www-data
pm = dynamic
pm.max_children = 5
pm.start_servers = 2
pm.min_spare_servers = 1
pm.max_spare_servers = 3
php_admin_flag[log_errors] = on
php_admin_value[error_log] = /var/log/php-${WBMainURI}.log
php_admin_value[memory_limit] = 128M
php_admin_value[open_basedir] = /tmp/:/var/www/${WBMainURI}/
"> "/etc/php/${PHPVersion}/fpm/pool.d/www.conf"
fi

# Requesting certificates for domains
domains="$(printf "$WBMainURI $WBAliasURI" | sed -E 's/ /,/g;')"
certbot --apache -n --agree-tos -m "$WBEmail" -d "$domains"

# Deleting .ssh folder
rm -r /root/.ssh

# Some personal customization
printf "" > /etc/motd                               # Removing default motd
printf "\nalias ll='ls -alF'\n" >> /etc/profile     # Adding ll alias

# Cleaning and exiting
apt autoremove -yq
apt autoclean -yq

# Restarting services with new configurations
service apache2 stop
service apache2 start
service php*-fpm restart
service mysql restart

touch /root/.done