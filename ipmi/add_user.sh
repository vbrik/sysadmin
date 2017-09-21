#!/bin/bash
# 
# This script is intended for, and has been tested on, SuperMicro BMCs.
# It configures ipmi user with given name, password, and grants access 
# to channel 1 with given privilege.
#
# By default, new user's id will be 3 (first two typically are anonymous
# and ADMIN), and privilege will be 4 (administrator).
#
# Use `ipmitool user list` to determine which user id to use.
#
host=$1
admin_user=$2
admin_pass=$3
user=$4
pass=$5
uid=${6-3}
privilege=${7-4}

ipmi_cmd="ipmitool -I lanplus -H $host -U $admin_user -P $admin_pass"

fail() {
	echo Error: ipmitool failed with code $?
	exit 1
}

set -x
$ipmi_cmd user set name $uid $user || fail
$ipmi_cmd user set password $uid $pass || fail
$ipmi_cmd channel setaccess 1 $uid link=on ipmi=on callin=on privilege=4
$ipmi_cmd user enable $uid #in case this uid was disabled previously
$ipmi_cmd user list

#? user priv 3 ADMIN
#? user enable 3
#? user disable <#ADMIN>
