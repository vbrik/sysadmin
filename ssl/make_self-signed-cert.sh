#!/bin/bash
host=$1
email=$2
# SuperMicro BMCs require keys to end with .pem
key="$host.key.pem"
cert="$host.cert.pem"

echo -e "Generating private key \e[42m$key\e[0m"
openssl genrsa -out $key 2048
echo -e "Generating self-signed certificate \e[42m$cert\e[0m"
openssl req -new -x509 -key $key -out $cert \
			-days 1460 \
			-subj "/C=US/ST=WI/L=Madison/O=University of Wisconsin at Madison/OU=IceCube/CN=$host/emailAddress=$email"
