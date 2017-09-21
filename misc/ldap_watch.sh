#!/bin/bash

logdir=$1
conn2host=()
cache[xxx]=yyy

function find_conn_creator() {
	local conn=$1
	local log=$2
	#echo "Searching for creator of $conn in $log" > /dev/stderr
	ip=$(grep "conn=$conn .* SSL connection from" $log | awk '{print $9}')
	if [ "$ip" ]; then
		host $ip | awk '{print $5}' | grep -o '^[^.]\+'
		return $?
	else
		return 1
	fi
}

function get_host() {
	local conn=$1
	local cache=$2
	if [ ! "${cache[$conn]}" ]; then
		echo "Cache miss!" > /dev/stderr
		host=$(find_conn_creator $conn access)
		if [ ! "$host" ]; then
			for log in $(ls -r $logdir/access.[0-9]*); do
				host=$(find_conn_creator $conn $log)
				if [ "$host" ]; then
					break
				fi
			done
		fi
		if [ "$host" ]; then
			cache[$conn]=$host
		else
			cache[$conn]=UNKNOWN
		fi
	else
		echo "Cache hit!" > /dev/stderr
	fi
	echo ${cache[$conn]}
	echo "XXX $conn ${cache[@]}" > /dev/stderr
}

function get_conn() {
	echo "$1" | awk '{print $3}' | awk -F = '{print $2}'
}

tail -f $logdir/access | grep --line-buffered ' op=' | grep --line-buffered -v ENTRY |  grep --line-buffered -v 'closed - U1' | grep --line-buffered -v BIND | grep --line-buffered '^\[' | while read line; do 
	conn=$(get_conn "$line")
	if [ ! "${cache[$conn]}" ]; then
		host=$(find_conn_creator $conn access)
		if [ ! "$host" ]; then
			for log in $(ls -r $logdir/access.[0-9]*); do
				host=$(find_conn_creator $conn $log)
				if [ "$host" ]; then
					break
				fi
			done
		fi
		if [ "$host" ]; then
			cache[$conn]=$host
		else
			cache[$conn]=UNKNOWN
		fi
	fi
	host=${cache[$conn]}
	op=$(echo "$line"| cut -d ' ' --complement -f 1,2,3,4 | cut -c -120)
	echo "$(printf '%-10s' $host) $op"
done
