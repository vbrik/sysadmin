#!/bin/bash

host=$1
admin_user=$2
admin_pass=$3
user=$4
pass=$5

ipmi_cmd="ipmitool -I lanplus -H $host -U $admin_user -P $admin_pass"

uid=$($ipmi_cmd user list | grep $user | grep -o '^[0-9]\+')
echo $uid
set -x
$ipmi_cmd user set password $uid $pass

