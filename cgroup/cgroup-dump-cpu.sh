#!/bin/bash
# dump /cgroup/cpu hierarcy

format="%-35s %5s %6s\n"
printf "$format" "" procs shares

for d in $(find /cgroup/cpu -type d); do
	procs=$(wc -l $d/tasks | awk '{print $1}')
	shares=$(<$d/cpu.shares)
	printf "$format" $d $procs $shares
done
