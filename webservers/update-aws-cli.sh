#!/bin/sh
#########################################################
#                                                       #
#   Name: Update AWS Cli                                #
#   Author: Diego Castagna (diegocastagna.com)          #
#   Description: Updates the AWS cli and removing       #
#   the default one                                     #
#   License: diegocastagna.com/license                  #
#                                                       #
#########################################################

AWSCliUrl="https://www.diegocastagna.com/files/awscli.tar.xz"   # Just the awscli but with tar.xz compression

# Updating AWS Cli
apt -yq remove awscli
wget -U "Mozilla/5.0 (Macintosh; Intel Mac OS X 11_4) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.164 Safari/537.36" -O /root/awscli.tar.xz "$AWSCliUrl"
tar -xf /root/awscli.tar.xz -C /root/
bash /root/aws/install
rm -r /root/aws/
rm /root/awscli.tar.xz