#!/bin/bash

key=$1
fqdn=$2

openssl req -config eugridpma-robot-openssl.cnf -new \
    -key $key \
    -subj "/C=US/ST=Wisconsin/O=University of Wisconsin-Madison/OU=OCIS/CN=$fqdn/emailAddress=admin@icecube.wisc.edu/CN=Robot - Rucio FTS"
