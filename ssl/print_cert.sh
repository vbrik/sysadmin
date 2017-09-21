#!/bin/bash
cert=$1
openssl x509 -in $cert -text | grep 'BEGIN CERTIFICATE' -B 1000
echo ...
