#!/bin/sh
#########################################################
#                                                       #
#   Name: Server Administrator                          #
#   Author: Diego Castagna (diegocastagna.com)          #
#   Description: This script will help you              #
#   manage a server with ease                           #
#   License: diegocastagna.com/license                  #
#                                                       #
#########################################################

# Handle exit signals
trap 'stty echo' INT

## Menu Functions ##

# Apache2 sub-menu
menu_apache2(){
    while true; do
        printf "\n\n## Apache2 Menu ##\n\n"
        printf "Choose what you want to configure:\n"
        printf "1) Create folder and virtualhost\n"
        printf "2) Deploy certificates\n"
        printf "3) Secure PHPMyAdmin installation\n"
        printf "4) Enhance Apache2 security and privacy\n"
        printf "0) Return to previous menu\n"
        printf "00) Exit\n\n"

        read -p "#? " input

        printf "\n";
        case "$input" in
            1 ) create_a2_virtual;;
            2 ) deploy_a2_certs;;
            3 ) secure_a2_phpadmin;;
            4 ) enhance_a2_security;;
            0 ) return 0;;
            00 ) printf "Exiting script..\n"; exit 0;;
        esac
    done
}

# Database sub-menu
menu_database(){
    while true; do
        printf "\n\n## Database Menu ##\n\n"
        printf "Choose what you want to configure:\n"
        printf "1) Create database, user and assign itself\n"
        printf "2) Create database\n"
        printf "3) Create user\n"
        printf "4) Assign user to database\n"
        printf "5) Remove user from database\n"
        printf "6) Export entire database\n"
        printf "0) Return to previous menu\n"
        printf "00) Exit\n\n"

        read -p "#? " input

        printf "\n";
        case "$input" in
            1 ) create_db_assign_user;;
            2 ) create_db;;
            3 ) create_db_user;;
            4 ) assign_db_user;;
            5 ) remove_db_user;;
            6 ) export_db;;
            0 ) return 0;;
            00 ) printf "Exiting script..\n"; exit 0;;
        esac
    done
}

# PHP sub-menu
menu_php(){
    while true; do
        printf "\n\n## PHP Menu ##\n\n"
        printf "Choose what you want to configure:\n"
        printf "1) Switch between PHP-FPM and PHP-MOD\n"
        printf "2) Create new FPM pool\n"
        printf "3) Assign FPM Pool to virtualhost\n"
        printf "4) Edit php.ini settings\n"
        printf "5) Enhance PHP security\n"
        printf "0) Return to previous menu\n"
        printf "00) Exit\n\n"

        read -p "#? " input

        printf "\n";
        case "$input" in
            1 ) switch_php_engine;;
            2 ) create_php_pool;;
            3 ) assign_php_pool;;
            4 ) edit_php_settings;;
            5 ) enhance_php_security;;
            0 ) return 0;;
            00 ) printf "Exiting script..\n"; exit 0;;
        esac
    done
}

# System sub-menu
menu_system(){
    while true; do
        printf "\n\n## System Menu ##\n\n"
        printf "Choose what you want to configure:\n"
        printf "1) Add system user\n"
        printf "2) Lock system user\n"
        printf "3) Unlock system user\n"
        printf "4) Assign SSH Public Key to user\n"
        printf "5) Revoke all SSH Keys from user\n"
        printf "0) Return to previous menu\n"
        printf "00) Exit\n\n"

        read -p "#? " input

        printf "\n";
        case "$input" in
            1 ) add_system_user;;
            2 ) lock_system_user;;
            3 ) unlock_system_user;;
            4 ) assign_ssh_user;;
            5 ) revoke_ssh_user;;
            0 ) return 0;;
            00 ) printf "Exiting script..\n"; exit 0;;
        esac
    done
}

## Apache2 Functions ##

# Create Apache2 Virtualhost
create_a2_virtual(){
    local mainURI=""
    local aliasURI=""
    local DirName=""
    local DirFullPath=""

    # Main domain
    read -p "Enter the primary Domain name of the website (leave blank to exit): " mainURI

    if [ -z "$mainURI" ]; then
        return 0
    fi

    local DirFullPath="/var/www/$mainURI"

    # Domain alias
    read -p "Enter all domain aliases separated by space ' ' (leave blank to skip): " aliasURI

    # Dir name
    read -p "Enter a sub-folder name, leave blank to skip ($DirFullPath/): " DirName

    # Creating folders
    mkdir -p "$DirFullPath"
    chown admin.admin "$DirFullPath"

    # If subfolder need to be created
    if [ ! -z "$DirName" ]; then
        local DirName=$(printf "$DirName" | sed -E 's/[/]+/_/g')
        local DirFullPath="/var/www/$mainURI/$DirName"

        mkdir -p "$DirFullPath"
        chown admin.admin "$DirFullPath"
    fi

    if [ ! -z "$aliasURI" ]; then
        local aliasURI="$mainURI"
    fi

    # Creating Apache2 Virtualhost
    printf "<VirtualHost *:80>
    ServerName ${mainURI}
    ServerAlias ${aliasURI}
    ServerAdmin webmaster@localhost
    DocumentRoot ${DirFullPath}

    # If mod_php is enabled
    <IfModule mod_php>
        php_admin_value open_basedir '/tmp/:/var/www/${mainURI}/'
    </IfModule>

    # Redirect to local php-fpm if mod_php is not available
    <IfModule !mod_php>
        <IfModule proxy_fcgi_module>
            # Enable http authorization headers
            <IfModule setenvif_module>
                SetEnvIfNoCase ^Authorization$ \"(.+)\" HTTP_AUTHORIZATION=$1
            </IfModule>

            <FilesMatch \".+\.ph(ar|p|tml)$\">
                SetHandler \"proxy:unix:/run/php/php7.3-fpm.sock|fcgi://localhost\"
                ProxyErrorOverride On
            </FilesMatch>

            # Deny access to raw php sources by default
            <FilesMatch \".+\.phps$\">
                Require all denied
            </FilesMatch>

            # Deny access to files without filename (e.g. '.php')
            <FilesMatch \"^\.ph(ar|p|ps|tml)$\">
                Require all denied
            </FilesMatch>
        </IfModule>
    </IfModule>

    # Logs
    LogLevel error
    ErrorLog \${APACHE_LOG_DIR}/${mainURI}_error.log
    CustomLog \${APACHE_LOG_DIR}/${mainURI}_access.log combined

    <Directory ${DirFullPath}/>
        Options -Indexes +SymLinksIfOwnerMatch -Includes
        AllowOverride All
    </Directory>
    </VirtualHost>" > "/etc/apache2/sites-available/${mainURI}.conf"

    # Creating Access and Error logs
    install -m 640 -o root -g adm /dev/null "/var/log/apache2/${mainURI}_error.log"
    install -m 640 -o root -g adm /dev/null "/var/log/apache2/${mainURI}_access.log"
    install -m 640 -o www-data -g www-data /dev/null "/var/log/php-${mainURI}.log"

    # Enabling site and reloading apache2
    a2ensite -q "${mainURI}.conf"
    service apache2 reload

    printf "Done.\n"
}

# Deploy certificates on domains
deploy_a2_certs(){
    local domains=""

    read -p "Enter all the domains for the certificate separated by space ' ' (leave blank to exit): " domains

    if [ -z "$domains" ]; then
        return 0
    fi

    local domains="$(printf "$domains" | sed -E 's/ /,/g;')"
    certbot --apache -n --agree-tos -d "$domains"

    printf "Done.\n"
}

# Secure PHPMyAdmin folder
secure_a2_phpadmin(){
    local HtUser=""
    local HtPass=""

    # User name
    read -p "Enter the user name (leave blank to exit): " HtUser
    if [ -z "$HtUser" ]; then
        return 0;
    fi

    # User password
    stty -echo
    read -p "Enter the user password (leave blank to autogenerate): " HtPass
    stty echo
    if [ -z "$HtPass" ]; then
        local HtPass=$(openssl rand -base64 32)
        local autogen=1
    fi

    sed --follow-symlinks -i "/DirectoryIndex index.php/a\    AllowOverride All" /etc/apache2/conf-available/phpmyadmin.conf
    printf 'AuthType Basic
Authname "Restricted files"
AuthUserFile /etc/phpmyadmin/.htpasswd
Require valid-user' > /usr/share/phpmyadmin/.htaccess
    htpasswd -bc /etc/phpmyadmin/.htpasswd "$HtUser" "$HtPass"

    if [ "$autogen" -eq 1 ]; then
        printf "\nAutogenerated password: '$HtPass'"
    fi

    printf "\nDone.\n"
}

# Enhance Apache2 security and privacy
enhance_a2_security(){

    # Ehnancing Apache2 security
    printf 'ServerTokens Prod
    ServerSignature Off
    TraceEnable Off
    <DirectoryMatch "/\.git">
        Require all denied
    </DirectoryMatch>' > /etc/apache2/conf-available/security_enhanced.conf

    # Enhancing SSLProtocol
    sed --follow-symlinks -i "/SSLProtocol all -SSLv3/c\        SSLProtocol all -SSLv3 -TLSv1 -TLSv1.1" /etc/apache2/mods-available/ssl.conf

    # Disabling old conf and enabling the new one
    a2disconf security
    a2enconf security_enhanced

    # Reloading apache
    service apache2 reload

    printf "\nDone.\n"
}

## Database Functions ##

# Creates a database, user and assign itself
create_db_assign_user(){
    local DBUser=""
    local DBName=""
    local DBPass=""
    local DBExName=""
    local DBExist=""

    # Database name
    read -p "Enter the database name (leave blank to exit): " DBName
    if [ -z "$DBName" ]; then
        return 0;
    fi

    # Database user
    read -p "Enter the Database user (leave blank to use DB name): " DBUser
    if [ -z "$DBUser" ]; then
        local DBUser="$DBName"
    fi

    # User password
    stty -echo
    read -p "Enter the user password (leave blank to autogenerate): " DBPass
    stty echo
    if [ -z "$DBPass" ]; then
        local DBPass=$(openssl rand -base64 32)
        local autogen=1
    fi

    local DBName=$(printf "$DBName" | sed -E 's/[.]+/_/g; s/[/]+/_/g; s/[\]+/_/g;')
    local DBExName=$(printf "$DBName" | sed -E 's/[_]+/\\_/g')

    mysql -u root <<_EOF_
    CREATE DATABASE IF NOT EXISTS `${DBName}`;
    CREATE USER '${DBUser}'@'localhost' IDENTIFIED BY '${DBPass}';
    GRANT ALL PRIVILEGES ON `${DBExName}`.* TO '${DBUser}'@'localhost';
    FLUSH PRIVILEGES;
_EOF_;

    if [ "$autogen" -eq 1 ]; then
        printf "\nAutogenerated password: '$DBPass'"
    fi

    printf "\nDone.\n"
}

# Creates a database
create_db(){
    local DBName=""

    # Database name
    read -p "Enter the database name (leave blank to exit): " DBName
    if [ -z "$DBName" ]; then
        return 0;
    fi

    local DBName=$(printf "$DBName" | sed -E 's/[.]+/_/g; s/[/]+/_/g; s/[\]+/_/g;')

    mysql -u root <<_EOF_
    CREATE DATABASE IF NOT EXISTS `${DBName}`;
_EOF_

    printf "Done.\n"
}

# Creates a database user
create_db_user(){
    local DBUser=""
    local DBPass=""
    local autogen=0

    # User name
    read -p "Enter the user you want to create (leave blank to exit): " DBUser
    if [ -z "$DBUser" ]; then
        return 0;
    fi

    # User password
    stty -echo
    read -p "Enter theuser password (leave blank to autogenerate): " DBPass
    stty echo
    if [ -z "$DBPass" ]; then
        local DBPass=$(openssl rand -base64 32)
        local autogen=1
    fi

    mysql -u root <<_EOF_
    CREATE USER '${DBUser}'@'localhost' IDENTIFIED BY '${DBPass}';
_EOF_

    if [ "$autogen" -eq 1 ]; then
        printf "\nUser '$DBUser' created with password '$DBPass'"
    fi

    printf "\nDone.\n"
}

# Gives database privileges to a user
assign_db_user(){
    local DBName=""
    local DBUser=""

    # Database name
    read -p "Enter the database name (leave blank to exit): " DBName
    if [ -z "$DBName" ]; then
        return 0;
    fi

    # User name
    read -p "Enter the user to grant permissions to (leave blank to exit): " DBUser
    if [ -z "$DBUser" ]; then
        return 0;
    fi

    local DBName=$(printf "$DBName" | sed -E 's/[.]+/_/g; s/[/]+/_/g; s/[\]+/_/g;')
    local DBExName=$(printf "$DBName" | sed -E 's/[_]+/\\_/g')

    mysql -u root <<_EOF_
    GRANT ALL PRIVILEGES ON `${DBExName}`.* TO '${DBUser}'@'localhost';
    FLUSH PRIVILEGES;
_EOF_

    printf "Done.\n"
}

# Removes database privileges from a user
remove_db_user(){
    local DBName=""
    local DBUser=""

    # Database name
    read -p "Enter the database name (leave blank to exit): " DBName
    if [ -z "$DBName" ]; then
        return 0;
    fi

    # User name
    read -p "Enter the user to revoke permissions to (leave blank to exit): " DBUser
    if [ -z "$DBUser" ]; then
        return 0;
    fi

    local DBName=$(printf "$DBName" | sed -E 's/[.]+/_/g; s/[/]+/_/g; s/[\]+/_/g;')
    local DBExName=$(printf "$DBName" | sed -E 's/[_]+/\\_/g')

    mysql -u root <<_EOF_
    REVOKE ALL PRIVILEGES ON `${DBExName}`.* FROM '${DBUser}'@'localhost';
    FLUSH PRIVILEGES;
_EOF_

    printf "Done.\n"
}

# Export all the tables from a database
export_db(){
    local DBName=""
    local compress=""

    # Database name
    read -p "Enter the database name (leave blank to exit): " DBName
    if [ -z "$DBName" ]; then
        return 0;
    fi

    mysqldump -u root --compact --opt --force --add-drop-trigger "$DBName" > "$DBName.sql"

    while [ "$compress" != "y" ] && [ "$compress" != "N" ] && [ "$compress" != "n" ] && [ "$compress" != "N" ]; do
        read -p "Do you want to compress the backup? (Y / N): " compress
    done

    case $compress in
        [yY] ) xz -9 "$DBName.sql";;
    esac

    printf "Done.\n"
}

## PHP Functions ##

# Switch Apache2 PHP engine from mod php to fpm and viceversa
switch_php_engine(){
    printf ""
}

# Creates a new FPM pool
create_php_pool(){
    printf ""
}

# Assign a FPM pool to an apache2 virtualhost
assign_php_pool(){
    printf ""
}

# Edit php.ini settings
edit_php_settings(){
    printf ""
}

# Enchange PHP security with some standard settings
enhance_php_security(){
    printf ""
}

## System Functions ##

# Creates a new user inside the system with home directory
add_system_user(){
    local username=""

    read -p "Enter the username (leave blank to exit): " username

    if [ -z "$username" ]; then
        return 0
    fi

    adduser --disabled-password "$username"                     # You should never use passwords
    mkdir -p /home/"$username"/.ssh
    touch /home/"$username"/.ssh/authorized_keys
    chown -R "$username"."$username" /home/"$username"/.ssh/
    chmod 700 /home/"$username"/.ssh/
    chmod 644 /home/"$username"/.ssh/authorized_keys

    printf "Done.\n"
}

# Lock a user from accessing the system
lock_system_user(){
    local username=""

    read -p "Enter the username (leave blank to exit): " username

    if [ -z "$username" ]; then
        return 0
    fi

    usermod -L -e 0 -s /sbin/nologin "$username"    # Lock user account, set expire date to 0 and login shell to nologin

    printf "Done.\n"
}

# Unlock a user and permits to use the system again
unlock_system_user(){
    local username=""

    read -p "Enter the username (leave blank to exit): " username

    if [ -z "$username" ]; then
        return 0
    fi

    usermod -U -E "" -s "" "$username"  # Lock user account, disable expire date and set login shell to default

    printf "Done.\n"
}

# Append SSH Public Key to the authorized_keys file of a user
assign_ssh_user(){
    local username=""
    local key=""

    read -p "Enter the username to assign the key to (leave blank to exit): " username

    if [ -z "$username" ]; then
        return 0
    fi

    stty -echo
    printf "You must generate the keys on your device. You can use the ssh-keygen.sh script in this repo.\n"
    read -p "Paste here the public key: " key
    stty echo

    printf "$key" >> /home/"$username"/.ssh/authorized_keys

    printf "\nDone.\n"
}

# Removes all SSH Keys from the authorized_keys of a user
revoke_ssh_user(){
    local username=""

    read -p "Enter the username to revoke all SSH keys (leave blank to exit): " username

    if [ -z "$username" ]; then
        return 0
    fi

    printf "" > /home/"$username"/.ssh/authorized_keys

    printf "Done.\n"
}

## Main Program ##

# Checking if I'm root
if [ $(id -u) -ne 0 ]; then
    printf "This script must be run as root\n"
    exit 1;
fi

while true; do
    printf "\n## Server Administrator ##\n\n"
    printf "Choose what you want to configure:\n"
    printf "1) Apache2\n"
    printf "2) Database\n"
    printf "3) PHP\n"
    printf "4) System\n"
    printf "5) Auto-delete this script\n"
    printf "00) Exit\n\n"

    read -p "#? " input

    case "$input" in
        1 ) menu_apache2;;
        2 ) menu_database;;
        3 ) menu_php;;
        4 ) menu_system;;
        #5 ) rm -- "$0"; exit 0;;
        00 ) printf "\nExiting script..\n"; exit 0;;
    esac
done