#########################################################
#                                                       #
#   Name: Generate Certificate                          #
#   Author: Diego Castagna (diegocastagna.com)          #
#   Description: This script will generate a            #
#   self-signed certificate                             #
#   License: diegocastagna.com/license                  #
#                                                       #
#########################################################

keyName=""
certName=""
domain=""
genKey="-signkey"

read -p "Enter the Key name (leave blank to generate one): " keyName
if [ -z "$keyName" ]; then
    keyName="key.pem"
    genKey="-newkey rsa:4096 -keyout"
fi

read -p "Enter the Certificate name (leave blank to use 'cert.pem'): " certName
if [ -z "$certName" ]; then
    certName="cert.pem"
fi

read -p "Enter the domain for the certificate (leave blank to use 'localhost'): " domain
if [ -z "$domain" ]; then
    domain="localhost"
fi

openssl req -x509 $genKey "$keyName" -out "$certName" -sha256 -days 365 -subj "/C=IT/ST=Italy/L=Milan/O=Company/OU=Org/CN=$domain" -nodes