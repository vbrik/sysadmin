#!/bin/bash

cgroot=/sys/fs/cgroup
controllers="cpuacct cpu memory"
mkdir $cgroot &> /dev/null

while read pid uid user; do
	if [ $uid -lt 1000 ]; then
		continue
	fi
	for ctl in $controllers; do
		mkdir -p $cgroot/$ctl/users/$user &> /dev/null
		echo $pid > $cgroot/$ctl/users/$user/tasks 2> /dev/null
	done
done <<< "$(ps -Ao pid,uid,user= h)"

# clean up processes and users that don't exist any more
for ctl in $controllers; do
	rmdir $cgroot/$ctl/users/*/* &> /dev/null
	rmdir $cgroot/$ctl/users/* &> /dev/null
done
