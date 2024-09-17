#!/bin/bash
# Creates user if necessary, grants admin privileges, and sets password.
# When changing root password, some commands will fail, but it's ok.

host=$1
admin_user=$2
admin_pass=$3
# By default, 1 is Anonymous, 2 is root; by convention 3 is local admin
useridx=$4
username=$5
userpw=$6

racadm="idracadm7 -r $host -u $admin_user -p $admin_pass"

echo $host =========================================================
set -x
{
    $racadm set iDRAC.Users.$useridx.UserName "$username" || exit
	$racadm set iDRAC.Users.$useridx.Password "$userpw" || exit
	$racadm set iDRAC.Users.$useridx.Enable 1 || exit
	# password must already be set for this to work
    $racadm set iDRAC.IPMILan.Enable 1 || exit
	$racadm set iDRAC.Users.$useridx.IpmiLanPrivilege 4 || exit
	$racadm set iDRAC.Users.$useridx.SolEnable 1 || exit
	$racadm set iDRAC.Users.$useridx.IpmiSerialPrivilege 4 || exit
	$racadm set iDRAC.Users.$useridx.Privilege 511 || exit
} | grep -v 'self-signed\|^Continuing\|Certificate is invalid'
set +x
echo ===============================================================
