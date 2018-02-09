#!/bin/bash
# dump /cgroup/memory hierarcy

readable() {
	local v=$1
	if [ "$v" -eq 9223372036854775807 ]; then
		echo unl
	elif [ "$v" -gt $((1024*1024*1024)) ]; then
		echo $((v/1024/1024/1024))G
	elif [ "$v" -gt $((1024*1024)) ]; then
		echo $((v/1024/1024))M
	elif [ "$v" -gt $((1024)) ]; then
		echo $((v/1024))K
	else
		echo $v
	fi
}

format="%-35s %5s %14s %5s %5s %10s %4s %14s %10s %10s %10s %10s %5s %6s\n"
files="soft_limit limit usage max_usage fail memsw.lim memsw.usag memsw.max memsw.fail"
stats="unevict cache mapped"

printf "$format" "" procs $files $stats

for d in $(find /cgroup/memory -type d); do
	line=""
	procs=$(wc -l $d/tasks | awk '{print $1}')
	line="$line $procs"
	for f in $files; do
		line="$line $(readable $(<$d/memory.$f*))"
	done
	for s in $stats; do
		line="$line $(readable $(awk "/^$s/{print \$2}" $d/memory.stat))"
	done
	printf "$format" $d $line
done
