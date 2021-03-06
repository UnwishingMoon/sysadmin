#!/bin/sh
#########################################################
#                                                       #
#   Name: Certbot Installer                             #
#   Author: Diego Castagna (diegocastagna.com)          #
#   Description: Install Certbot using snapd            #
#   License: diegocastagna.com/license                  #
#                                                       #
#########################################################

# Checking if I'm root
if [ $(id -u) -ne 0 ]; then
    printf "This script must be run as root\n"
    exit 1;
fi

# Installing required packages
apt-get update -yq
apt-get install -yq snapd

# Removing certbot if already installed
apt-get remove -yq certbot

# Installing snapd
snap install core
snap refresh core

# Installing certbot
snap install --classic certbot
ln -s /snap/bin/certbot /usr/bin/certbot
