#!/bin/bash
# Save iDRAC configuration to a file. 
# This is useful for diffing iDRAC configurations.

host=$1
user=$2
pass=$3
output=${4-$host.cfg}

echo "Will write configuration to file '$output'"
set -x
racadm -r $host -u $user -p $pass getconfig -f $output
