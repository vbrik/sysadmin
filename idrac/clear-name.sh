#!/bin/bash
# Clear an iDRAC's "DNS DRAC Name", which is used as the page title of the web
# interface and window title of the remote console. When this parameter is
# unset, it should default to OS hostname, which is what we usually want.

host=$1
user=$2
pass=$3

set -x
racadm -r $host -u $user -p $pass config -g cfgLanNetworking -o cfgDNSRacName ""
