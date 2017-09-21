#!/bin/bash
# Set iDRAC LCD to display OS hostname (by default it displays service tag).
# This only works on iDRAC7+. For iDRAC6, you have to use omconfig.

host=$1
user=$2
pass=$3

set -x
racadm -r $host -u $user -p $pass set System.LCD.Configuration 16
