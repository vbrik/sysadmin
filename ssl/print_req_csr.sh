#!/bin/bash
csr=$1
openssl req -in $csr -text
