#!/bin/bash
# Enable IPMI in iDRAC using racadm, and set IPMI LAN privilege to allow remote access.

host=$1
user=$2
pass=$3
target=${4-$user}
# privilege 4 means administrator
priv=${5-4}

set -ex
racadm="idracadm7 -r $host -u $user -p $pass"
$racadm set iDRAC.IPMILan.Enable 1

cfg=$(mktemp)
$racadm get -t json -f $cfg -c iDRAC.Embedded.1 || exit
index=$(jq ".SystemConfiguration.Components.[] | select(.FQDD==\"iDRAC.Embedded.1\") | .Attributes[] | select(.Value==\"$target\").Name" $cfg | grep -o '[0-9]*')
rm $cfg
if [ -z "$index" ]; then
	echo Failed to determine index of user $target
	exit 1
fi

# By default, IPMI LAN privilege is 0, which means no access.
$racadm set iDRAC.Users.$index.IpmiLanPrivilege 4
