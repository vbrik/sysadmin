#!/bin/bash
#
# Create and manage a memory cgroup hierarchy in /cgroup/memory/users/USERNAME
# for non-system processes, i.e. whose owner's real user id >= 500. Real, rather
# than effective user ids are used so that system processes that use setuid,
# like Condor, are not misidentified as user processes.
#
# The main goal is to restrict the amount of memory and swap available to user
# processes so that, if we are low on memory, user processes are killed before
# the machine completely runs out of memory and system processes are killed.
#
# Just having /cgroup/memory/users (without per-user subgroups) would be 
# sufficient for achieving the main goal. Nevertheless, creating per-user 
# subgroups provides nice accounting information, allows fine-grained tuning,
# and prevents a single user from monopolizing resources that are meant to be 
# shared (however, fair memory allocation among users is not a goal (yet)).
#
# This script looks for user processes (owner's real user id >= 500) in 
# /cgroup/memory/tasks and moves them to /cgroup/memory/users/USERNAME. 
# The fraction of memory and swap made available to user processes is 
# controlled by $percent variable: /cgroup/memory/users will be limited 
# to $percent of total memory and swap, and /cgroup/memory/users/USERNAME 
# will be limited to $percent of memory and swap available to its parent.
#
# The script accepts a single command line argument, whose presence indicates
# a debugging mode. If the argument is "remove", the /cgroup/memory/users 
# hierarchy will be removed. Any other string will make the script print out
# existing /cgroup/memory/users hierarcy and relevant settings.
#
# This script is meant to run every minute from crontab to catch user processes
# started in new sessions. An alternative implementation could use cgrulesengd
# or a PAM cgroup module, whose advantage is that all new processes would be 
# assigned to appropriate cgroup immediately. However, those mechanisms are
# less flexible, require somewhat more complex configuration, and are less 
# puppet-friendly.
#

debug=$1
percent=90

get_proc_ruid() {
	awk '/^Uid:/{print $2}' /proc/$1/status
}

get_user_name() {
	getent passwd $1 | awk -F : '{print $1}'
}

#create new restricted sub-group
create_rgroup() {
	local parent=$1
	local name=$2
	local percent=$3
	local memlim=$4
	local memswlim=$5
	local dir="$parent/$name"
	memlim=$((memlim * percent / 100))
	memswlim=$((memswlim * percent / 100))
	local safety_margin=1000000000
	if [ "$memlim" -lt "$safety_margin" ] ; then
		echo "Memory limits invalid or less than safety margin:" > /dev/stderr
		echo "\$memlim='$memlim', \$safety_margin='$safety_margin'." > /dev/stderr
		exit 1
	fi
	mkdir -p $dir || exit 1
	echo $memlim > $dir/memory.limit_in_bytes || exit 1
	echo $memswlim > $dir/memory.memsw.limit_in_bytes || exit 1
	echo 1 > $dir/memory.move_charge_at_immigrate || exit 1
}

# /proc/meminfo is in kb
memtotal=$(awk '/MemTotal:/{print int($2*1024)}' /proc/meminfo)
swaptotal=$(awk '/SwapTotal:/{print int($2*1024)}' /proc/meminfo)
memswtotal=$((memtotal + swaptotal))

if [ "$debug" == "remove" ]; then
	echo "Resetting cgroups"
	for d in $(find /cgroup/memory/users -depth -type d); do
		echo $d
		for p in $(<$d/tasks); do
			echo $p > /cgroup/memory/tasks
		done
		rmdir $d
	done
	exit
elif [ -n "$debug" ]; then
	format="%-35s %6s  %6s  %5s  %8s  %8s %6s\n"
	printf "$format" "" mem swmem procs failcnt maxswmem maxmem
	for d in $(find /cgroup/memory -type d); do
		mem=$(<$d/memory.limit_in_bytes)
		if [ "$mem" -eq 9223372036854775807 ]; then 
			mem="unlim"
		else
			mem="$((mem/1024/1024/1024))G"
		fi
		swmem=$(<$d/memory.memsw.limit_in_bytes)
		if [ "$swmem" -eq 9223372036854775807 ]; then 
			swmem="unlim"
		else
			swmem="$((swmem/1024/1024/1024))G"
		fi
		procs=$(wc -l $d/tasks | awk '{print $1}')
		failcnt=$(<$d/memory.memsw.failcnt)
		maxswmem=$(<$d/memory.memsw.max_usage_in_bytes)
		maxmem=$(<$d/memory.usage_in_bytes)
		printf "$format" $d $mem $swmem $procs $failcnt \
							$((maxswmem/1024/1024/1024))G \
							$((maxmem/1024/1024/1024))G
	done
	exit
fi

if [ ! -f /cgroup/memory/tasks ]; then
	echo "/cgroup/memory/tasks not found" > /dev/stderr
	exit 1
fi
if [ $(</cgroup/memory/memory.use_hierarchy) != "1" ]; then
	echo 1 > /cgroup/memory/memory.use_hierarchy || exit 1
fi

create_rgroup /cgroup/memory users $percent $memtotal $memswtotal

for pid in $(</cgroup/memory/tasks); do
	# ignore errors whenever $pid is involved, since it may not exist any more
	ruid=$(get_proc_ruid $pid 2> /dev/null) || continue
	if [ "$ruid" -ge 500 ] ; then
		user=$(get_user_name $ruid) || continue
		if [ ! -d /cgroup/memory/users/$user ]; then
			create_rgroup /cgroup/memory/users $user $percent \
						$(</cgroup/memory/users/memory.limit_in_bytes) \
						$(</cgroup/memory/users/memory.memsw.limit_in_bytes)
		fi
		# assigning $pid to cgroup with charge migration enabled 
		# may fail if destination is full (unlikely).
		if (! echo $pid > /cgroup/memory/users/$user/tasks 2> /dev/null); then
			if [ -d /proc/$pid ]; then
				echo "Warning: failed to assign $pid to $user's cgroup" > /dev/stderr
			fi
		fi
	fi
done

# do not remove directories with no tasks to keep failcnt and other stats
#rmdir /cgroup/memory/users/* &> /dev/null



