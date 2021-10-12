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

# Creating gitlab user and .ssh files
adduser --disabled-password gitlab
mkdir -p /home/gitlab/.ssh
touch /home/gitlab/.ssh/authorized_keys
chown -R gitlab.gitlab /home/gitlab/.ssh/
chmod 700 /home/gitlab/.ssh/
chmod 600 /home/gitlab/.ssh/authorized_keys

# Generating SSH key for gitlab user - You should delete the keys after downloading them
ssh-keygen -b 4096 -t rsa -m PEM -C "gitlab" -f "/root/gitlab-runner.pem" -N ""
cat /root/gitlab-runner.pem.pub > /home/gitlab/.ssh/authorized_keys
chmod 600 /root/gitlab-runner.pem /root/gitlab-runner.pem.pub

# Adding groups to users
usermod -aG gitlab admin

if [ $(getent group nginx)]; then
    usermod -aG nginx gitlab
else
    usermod -aG www-data gitlab
fi