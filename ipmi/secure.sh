#!/bin/bash
# 
# This script is intended to make BMCs somewhat more secure following
# some of the recommendations from http://fish2.com/ipmi/
#
# This script assumes IPMI user ID 3 is the admin account we want to use.
#        ALL IPMI ACCOUNTS WITH USER ID != 3 WILL BE DISABLED
#        ALL IPMI ACCOUNTS WITH USER ID != 3 WILL BE DISABLED
#        ALL IPMI ACCOUNTS WITH USER ID != 3 WILL BE DISABLED
# (The idea behind this is that we don't want to use default user names
# for admin users, but it's not always possible to rename admin accounts.)
#
# What this script does:
#   - only allow MD5 authentication (least insecure)
#   - only allow cipher suite 3 (least insecure)
#   - disable anonymous user
#   - set anonymous user's privilege to "no access" 
#           (in case disabling fails)
#   - disable default administrator
#   - set defaul administrator's privilege to "no access" 
#           (in case disabling fails)
#   - set a random password for default administrator's 
#           (because IPMI 2.0 leaks password hashes)
#
# Some of the measures taken by this script are redundant. The reason for
# that is that different vendors impose different restrictions on how their
# BMCs can be configured. For example, it may not be possible to disable or
# rename the default administrator account.

host=$1
user=$2
pass=$3

if [ "$#" -ne 3 ]; then
    echo "Wrong number of arguments. Usage:"
    echo "$0 HOST USER PASSWORD"
    exit 1
fi

ipmi_cmd="ipmitool -I lanplus -H $host -U $user -P $pass"
fail() {
       echo Error: ipmitool failed. Wrong host or credentials?
       exit 1
}

# check that we have been given credentials for UID 3 because other accounts
# will be disabled and we don't want to get locked out.
uid3=$($ipmi_cmd channel getaccess 1 3) || fail

if ! echo "$uid3" | grep -q "User Name            : $user"; then
    echo "Sanity check failed: UID of $user != 3"
    exit 1
fi
if ! echo "$uid3" | grep -q "Privilege Level      : ADMINISTRATOR"; then
    echo "Sanity check failed: $user is not an administrator"
    exit 1
fi

pw=$(cat /dev/urandom|tr -dc "a-zA-Z0-9"|fold -w 20|head -n 1)
set -x
# disable NONE authentication method
$ipmi_cmd lan set 1 auth Callback MD5
$ipmi_cmd lan set 1 auth User MD5
$ipmi_cmd lan set 1 auth Operator MD5
$ipmi_cmd lan set 1 auth Admin MD5

# only allow cipher 3
$ipmi_cmd lan set 1 cipher_privs XXXaXXXXXXXXXXX

# disable anonymous
$ipmi_cmd user disable 1
$ipmi_cmd channel setaccess 1 1 link=off ipmi=off callin=off privilege=15

# disable default account
$ipmi_cmd user disable 2
$ipmi_cmd channel setaccess 1 2 link=off ipmi=off callin=off privilege=15
# set default account's password to random because RAKP leaks hashes
$ipmi_cmd user set password 2 $pw

set +x
$ipmi_cmd user list 1
$ipmi_cmd lan print 1 | grep -v 'IP\|MAC\|SNMP\|VLAN\|^Set\|Support\|Mask\|ARP'

