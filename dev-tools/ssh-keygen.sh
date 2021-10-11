#!/bin/sh
#########################################################
#                                                       #
#   Name: SSH Key Generator                             #
#   Author: Diego Castagna (diegocastagna.com)          #
#   Description: This script will help you              #
#   create new SSH RSA keys                             #
#   License: diegocastagna.com/license                  #
#                                                       #
#########################################################

# Default domain
domain="example.com"

# Variables used in the script
name=""
pass=""
comment=""

# Error handling for the script
trap 'stty echo' INT

# Filename
read -p "Enter the name of the output file: " name

# Passphrase
stty -echo
read -p "Enter the passphrase for the key (blank or minimum five characters): " pass
stty echo

printf "\n"

# Comment
read -p "Enter the comment for the key (leave 'blank' to skip): " comment
if [ -z $comment ]; then
    comment="$name@$domain"
fi

# Generating the keys
ssh-keygen -b 4096 -t rsa -m PEM -C "$comment" -f "$name" -N "$pass"

printf "Keys generated!!\n"