#!/bin/sh
#########################################################
#                                                       #
#   Name: Backup Database                               #
#   Author: Diego Castagna (diegocastagna.com)          #
#   Description: Secure MariaDB Database                #
#   License: diegocastagna.com/license                  #
#                                                       #
#########################################################

DBName=""
compress=""

# Database name
read -p "Enter the database name (leave blank to exit): " DBName
if [ -z "$DBName" ]; then
    exit 0;
fi

mysqldump -u root --opt --compact --force --skip-comments --add-drop-trigger --single-transaction "$DBName" > "$DBName.sql"

while [ "$compress" != "y" ] && [ "$compress" != "N" ] && [ "$compress" != "n" ] && [ "$compress" != "N" ]; do
    read -p "Do you want to compress the backup? (Y / N): " compress
done

case $compress in
    [yY] ) xz -9 "$DBName.sql";;
esac
