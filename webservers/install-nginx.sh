#!/bin/sh
#########################################################
#                                                       #
#   Name: NGINX Installer                               #
#   Author: Diego Castagna (diegocastagna.com)          #
#   Description: Install NGINX from official repo       #
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
apt-get install -yq curl gnupg2 ca-certificates lsb-release

# Downloading and adding the signing key
curl -fsL https://nginx.org/keys/nginx_signing.key | gpg --dearmor -o /usr/share/keyrings/nginx-archive-keyring.gpg

# Adding the source
printf "deb [signed-by=/usr/share/keyrings/nginx-archive-keyring.gpg] http://nginx.org/packages/mainline/debian `lsb_release -cs` nginx" > /etc/apt/sources.list.d/nginx.list

# Pinning the new repository
printf "Package: *
Pin: origin nginx.org
Pin: release o=nginx
Pin-Priority: 900" > /etc/apt/preferences.d/99nginx

# Updating and installing nginx
apt-get update -yq
apt-get install -yq nginx