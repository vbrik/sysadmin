#!/bin/bash

key=$1
cn=$2

openssl req -new -key $key \
    -subj "/CN=$cn" # I think DoIT provides all other fields
    #-subj "/C=US/ST=Wisconsin/L=Madison/O=University of Wisconsin at Madison/OU=IceCube/CN=$cn"
