#!/bin/sh
#########################################################
#                                                       #
#   Name: GPG Key Generator                             #
#   Author: Diego Castagna (diegocastagna.com)          #
#   Description: This script will generate GPG keys     #
#   License: diegocastagna.com/license                  #
#                                                       #
#########################################################

name=""
email=""

read -p "Enter your full name: " name
read -p "Enter your email for the key: " email

printf "Generating GPG Keys..\n"
gpg --batch --gen-key <<EOF
Key-Type: RSA
Key-Length: 4096
Subkey-Type: RSA
Subkey-Length: 4096
Name-Real: $name
Name-Email: $email
Expire-Date: 0
%no-protection
EOF

printf "Printing GPG public key!!\n"
gpg --export -a