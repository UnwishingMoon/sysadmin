#!/bin/sh
#########################################################
#                                                       #
#   Name: Git Set-Up                                    #
#   Author: Diego Castagna (diegocastagna.com)          #
#   Description: This script will set-up Git            #
#   License: diegocastagna.com/license                  #
#                                                       #
#########################################################

name=""
email=""

read -p "Enter your full name: " name
read -p "Enter your commit email: " email

printf "Configuring git..\n"

git config --global user.name "$name"
git config --global user.email "$email"
git config --global credential.helper store
git config --global commit.gpgsign true

printf "Git configured!!\n"