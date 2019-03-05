#!/bin/bash

key=$1

openssl req -config eugridpma-robot-openssl.cnf -new \
    -key $key \
    -subj "/CN=admin@icecube.wisc.edu/CN=Robot - Rucio FTS"
