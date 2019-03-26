#!/bin/bash

key=$1
fqdn=$2

openssl req -new \
    -key $key \
    -subj "/C=US/ST=Wisconsin/L=Madison/O=University of Wisconsin-Madison/OU=OCIS/CN=$fqdn"
