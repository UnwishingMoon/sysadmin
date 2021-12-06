#!/bin/sh
#########################################################
#                                                       #
#   Name: Docker Installer                              #
#   Author: Diego Castagna (diegocastagna.com)          #
#   Description: Install Docker from official repo      #
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
curl -fsL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

# Adding the source
printf "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/$(lsb_release -is | awk '{print tolower($0)}') $(lsb_release -cs) stable" > /etc/apt/sources.list.d/docker.list

# Updating and installing docker
apt-get update -yq
apt-get install -yq docker-ce docker-ce-cli containerd.io

# Installing docker compose
curl -fsL "https://github.com/docker/compose/releases/download/v2.1.1/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose