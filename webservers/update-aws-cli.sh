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

# Just the awscli but with tar.xz compression
AWSCliUrl="https://www.diegocastagna.com/files/awscli.tar.xz"

# Installing required packages
apt-get update -yq
apt-get install -yq curl

# Removing distribution AWS Cli
apt-get -yq remove awscli

# Downloading the cli
curl -o /root/awscli.tar.xz "$AWSCliUrl"
tar -xf /root/awscli.tar.xz -C /root/

# Installing the cli
bash /root/aws/install

# Removing temporary files
rm -rf /root/aws/
rm -f /root/awscli.tar.xz