#!/bin/bash
# 
# This script is intended for and has been tested on SuperMicro BMCs.
# It "deletes" an IPMI user. Since some users can't be deleted, this
# script disables the user, changes the name (otherwise you won't be
# able to create a user with the same name with different id), sets
# the user's password to a random string (in case it's re-enabled by
# accident), sets user's channel 1 access to "none" (otherwise, as
# far as I understand, the only way to confirm with ipmitool that a
# user has been disabled is to try to log in with it).
#
# Note that, at least on SuperMicros, it's impossible to rename and set
# channel access for users 1 and 2 (anonymous and ADMIN), so that done
# only for $uid > 2.
#
host=$1
admin_user=$2
admin_pass=$3
uid=$4

ipmi_cmd="ipmitool -I lanplus -H $host -U $admin_user -P $admin_pass"

fail() {
	echo Error: ipmitool failed with code $?
	exit 1
}

set -x
# some operations fail for users with id < 3 (at least on supermicros)
if [ $uid -ge 3 ]; then
	$ipmi_cmd user set name $uid deleted$RANDOM
	$ipmi_cmd channel setaccess 1 $uid link=off ipmi=off callin=off privilege=15
fi
$ipmi_cmd user set password $uid $(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 16 | head -n 1) || fail
$ipmi_cmd user disable $uid
$ipmi_cmd user list

#? user priv 3 ADMIN
#? user enable 3
#? user disable <#ADMIN>
