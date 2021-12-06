#!/bin/sh
#########################################################
#                                                       #
#   Name: Deploy Certificates                           #
#   Author: Diego Castagna (diegocastagna.com)          #
#   Description: Deploy certificates using certbot      #
#   License: diegocastagna.com/license                  #
#                                                       #
#########################################################

domains=""
serverType="--nginx"

# Checking if I'm root
if [ $(id -u) -ne 0 ]; then
    printf "This script must be run as root\n"
    exit 1;
fi

read -p "Enter all the domains for the certificate separated by space ',' (leave blank to exit): " domains

if [ -z "$domains" ]; then
    exit 0;
fi

if [ $(getent group www-data) ]; then
    serverType="--apache"
fi

certbot "$serverType" -n --agree-tos -d "$domains"