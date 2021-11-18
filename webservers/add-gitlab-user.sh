#!/bin/sh
#########################################################
#                                                       #
#   Name: Add gitlab user                               #
#   Author: Diego Castagna (diegocastagna.com)          #
#   Description: Add a user named gitlab and            #
#   generates his private key in the /root directory    #
#   License: diegocastagna.com/license                  #
#                                                       #
#########################################################

# Exit signal
trap 'stty echo' INT

# Asking for a passphrase
stty -echo
read -p "Enter the passphrase (leave blank to not set): " pass
stty echo

# Creating gitlab user
adduser --disabled-password gitlab

# Creating user directory and files
mkdir -p /home/gitlab/.ssh
touch /home/gitlab/.ssh/authorized_keys
chown -R gitlab.gitlab /home/gitlab/.ssh/
chmod 700 /home/gitlab/.ssh/
chmod 600 /home/gitlab/.ssh/authorized_keys

# Generating SSH key for gitlab user - You should delete the keys after downloading them
ssh-keygen -b 4096 -t rsa -m PEM -C "gitlab" -f "/root/gitlab-runner.pem" -N "$pass"

# Copying pub key to authorized_keys
cat /root/gitlab-runner.pem.pub > /home/gitlab/.ssh/authorized_keys

# Securing keys
chmod 600 /root/gitlab-runner.pem /root/gitlab-runner.pem.pub

# Adding groups to users
if [ $(getent passwd admin) ]; then
    usermod -aG gitlab admin
fi
if [ $(getent group nginx) ]; then
    usermod -aG nginx gitlab
else
if [ $(getent group www-data) ]; then
    usermod -aG www-data gitlab
fi