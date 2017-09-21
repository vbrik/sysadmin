#!/bin/bash
# Creates user if necessary, grants admin privileges, and sets password.
# When changing root password, some commands will fail, but it's ok.
# Password-only changes can also be done using:
# racadm config -g cfgUserAdmin -o cfgUserAdminPassword -i <idx> <pw>

host=$1
admin_user=$2
admin_pass=$3
# By default, 1 is Anonymous, 2 is root; by convention 3 is local admin
useridx=$4
username=$5
userpw=$6

useradmin="racadm -r $host -u $admin_user -p $admin_pass config -g cfgUserAdmin"

echo $host =========================================================
set -x
{
	$useradmin -i $useridx -o cfgUserAdminUserName "$username" 
	$useradmin -i $useridx -o cfgUserAdminPassword "$userpw"
	# password must already be set for this to work
	$useradmin -i $useridx -o cfgUserAdminEnable 1
	$useradmin -i $useridx -o cfgUserAdminPrivilege  0x000001ff
	# setting options below is not necessary for web interface access,
	# and may not be supported by all iDRACs
	$useradmin -i $useridx -o cfgUserAdminIpmiLanPrivilege 4
	$useradmin -i $useridx -o cfgUserAdminSolEnable 1
	# looks like blades don't have this
	#$useradmin -i $useridx -o cfgUserAdminIpmiSerialPrivilege 4
} | grep -v 'self signed\|^Continuing'
set +x
echo ===============================================================
