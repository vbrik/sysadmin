#!/bin/bash
# Enable IPMI in iDRAC using racadm, and set IPMI LAN privilege to allow remote access.

host=$1
user=$2
pass=$3
target=${4-$user}
# privilege 4 means administrator
priv=${5-4}

set -x
racadm="racadm -r $host -u $user -p $pass"
$racadm config -g cfgIpmiLan -o cfgIpmiLanEnable 1
index=$($racadm getconfig -u $target | grep cfgUserAdminIndex | awk -F = '{print $2}' | tr -d '\r')
if [ -z "$index" ]; then
	echo Failed to determine index of user $target
	exit 1
fi

# By default, IPMI LAN privilege is 0, which means no access.
$racadm config -g cfgUserAdmin -o cfgUserAdminIpmiLanPrivilege -i $index $priv

