#!/bin/bash
#
# Create and manage a cgroup hierarchy in /cgroup/cpu/users/USERNAME for 
# non-system processes, i.e. whose owner's real user id >= 500. Real, rather
# than effective user ids are used so that system processes that use setuid,
# like Condor, are not misidentified as user processes.
#
# The primary goal is fair sharing of CPU time among users. In particular, to 
# ensure that a single user cannot monopolize CPU resources by, for example,
# running a large number of processes. 
#
# The secondary goal is to ensure that system processes (owner's real user 
# id < 500) are not starved of CPU time by user processes under heavy load.
#
# Effects of this cgroup hierarchy on process scheduling can be non-obvious
# because fair share is computed on per-core basis and depends on demand.
# Roughly speaking, the key points are:
# 	- CPU time restrictions will become noticeable only under heavy load
#	- no user (real id >= 500) will be able to monopolize CPU time
#
# The script accepts a single command line argument, whose presence indicates
# a debugging mode. If this argument is "remove", the script will remove the
# /cgroup/cpu/users/USERNAME hierarchy. Otherwise, state of the existing
# /cgroup/cpu hierarcy will be printed out.
#
# This script is meant to run every minute from crontab to catch user processes
# started in new sessions. An alternative implementation could use cgrulesengd
# or a PAM cgroup module, whose advantage is that all new processes would be 
# assigned to appropriate cgroup immediately. However, those mechanisms are
# less flexible, require somewhat more complex configuration, and are less 
# puppet-friendly.

debug=$1

get_proc_name() {
	awk -F '\t' '/Name:/{print $2}' /proc/$1/status
}

get_proc_ruid() {
	awk '/^Uid:/{print $2}' /proc/$1/status
}

get_proc_euid() {
	awk '/^Uid:/{print $3}' /proc/$1/status
}

get_user_name() {
	getent passwd $1 | awk -F : '{print $1}'
}

if [ "$debug" == "remove" ]; then
	echo "Resetting cgroups"
	for d in $(find /cgroup/cpu/users -depth -type d); do
		echo $d
		for p in $(<$d/tasks); do
			echo $p > /cgroup/cpu/tasks
		done
		rmdir $d
	done
	exit
elif [ -n "$debug" ]; then
	format_group="%s numprocs=%s cpushares=%s\n"
	format_task="        %-9s %-20s %-15s  %s\n"
	for d in $(find /cgroup/cpu -type d); do
		procs=$(wc -l $d/tasks | awk '{print $1}')
		shares=$(<$d/cpu.shares)
		printf "$format_group" $d $procs $shares
		# ignore errors involving pids because they may have exited by now
		for pid in $(<$d/tasks); do
			cmdline="$(</proc/$pid/cmdline)" 2> /dev/null || continue
			rname=$(get_user_name $(get_proc_ruid $pid)) 2> /dev/null || continue
			ename=$(get_user_name $(get_proc_euid $pid)) 2> /dev/null || continue
			procname="$(get_proc_name $pid)" 2> /dev/null || continue
			printf "$format_task" $pid "$rname $ename" $procname "${cmdline:0:100}"
		done
	done
	exit
fi

if [ ! -d /cgroup/cpu/users ]; then
	mkdir /cgroup/cpu/users || exit 1
fi

for pid in $(</cgroup/cpu/tasks); do
	# ignore errors whenever $pid is involved, since it may not exist any more
	ruid=$(get_proc_ruid $pid 2> /dev/null) || continue
	if [ "$ruid" -ge 500 ] ; then
		user=$(get_user_name $ruid) || continue
		mkdir /cgroup/cpu/users/$user &> /dev/null
		echo $pid > /cgroup/cpu/users/$user/tasks 2> /dev/null
	fi
done

