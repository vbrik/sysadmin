#!/bin/bash
#
# Move processes with non-system (500 and higher) real UIDs to their own CPU 
# cgroup "usertrap" in /cgroup/cpu/usertrap. This script is meant to be executed
# from crontab. If called with an argument, the script will list information
# about the processes currently in the usertrap group.
#
# The idea is to prevent user processes from interfering with system processes
# when CPUs are over-allocated. Real UID is used to make sure Condor processes 
# that use setuid are not affected.
# 
# Roughly speaking, time on each CPU (core) is allocated like this: 
# When under-utilized, CPU time will be allocated more or less normally. 
# When fully utilized, CPU time will be split between usertrap and the root 
# cgroup, according to the number of "shares" each group has.
#

debug=$1
cg=/cgroup/cpu/usertrap
shares=512

get_proc_ruid() {
	awk '/^Uid:/{print $2}' /proc/$1/status
}

get_proc_euid() {
	awk '/^Uid:/{print $3}' /proc/$1/status
}

get_user_name() {
	getent passwd $1 | awk -F : '{print $1}'
}

get_proc_name() {
	awk -F '\t' '/Name:/{print $2}' /proc/$1/status
}

if [ -n "$debug" ]; then
	format="%5s %11s %11s %15s  %s\n"
	echo Processes trapped in $cg:
	printf "$format" PID RUID EUID Name cmdline
	for pid in $(<$cg/tasks); do 
		rname=$(get_user_name $(get_proc_ruid $pid)) || continue
		ename=$(get_user_name $(get_proc_euid $pid)) || continue
		cmdline="$(</proc/$pid/cmdline)" || continue
		name="$(get_proc_name $pid)" || continue
		printf "$format" $pid $rname $ename "$name" "${cmdline:0:120}"
	done
	exit
fi

/etc/init.d/cgconfig status > /dev/null || /etc/init.d/cgconfig start > /dev/null

if [ ! -d $cg ]; then
	mkdir -p $cg
fi
echo $shares > $cg/cpu.shares

for pid in $(<$cg/../tasks); do
	ruid=$(get_proc_ruid $pid 2> /dev/null) || continue
	if [ "$ruid" -ge 500 ] ; then
		echo $pid > $cg/tasks
	fi
done

