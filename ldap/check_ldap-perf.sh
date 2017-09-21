#!/bin/bash
# A check_mk plugin to monitor ldap server's internal performance metrics.
# The script simply dumps the per-second average change rates of certain
# metrics.

# nagios status codes
pass=0
warn=1
crit=2
unkn=3

metrics="anonymousbinds entriesreturned errors inops modifyentryops searchops securityerrors simpleauthbinds unauthbinds wholesubtreesearchops"

set -o pipefail
stats=/tmp/ldap_perf

if ! timeout 5 ldapsearch -x -b "cn=snmp,cn=monitor" -H ldap://127.0.0.1 $metrics | sort \
		| awk '$2~/^[0-9]+$/{if(NF==2){print $0}}' | grep -v '^search: ' | tr -d : > $stats.cur; then
	echo "ldapsearch failed"
	exit $crit
fi

if [ ! -e $stats.prev ]; then
	mv $stats.cur $stats.prev
	echo "Waiting for more data"
	exit $unk
fi

if [[ $(wc -l $stats.cur | awk '{print $1}') != $(wc -l $stats.prev | awk '{print $1}') ]]; then
	echo "ldapsearch returned unexpected number of metrics"
	exit $crit
fi

cur_time=$(stat -c %Y $stats.cur)
prev_time=$(stat -c %Y $stats.prev)
dt=$((cur_time - prev_time))
paste -d " " $stats.cur $stats.prev | cut -d " " -f 1,2,4 | \
	awk -v dt=$dt '{print $0, ($2-$3)/dt}' > $stats.diff

perf=""
while read metric current previous rate; do
	perf="$perf $metric=$rate"
done < $stats.diff
echo "All plots are per-second averages |$perf"

mv $stats.cur $stats.prev
