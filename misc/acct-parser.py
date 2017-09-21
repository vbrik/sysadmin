#!/usr/bin/env python

# XXX it looks like lastcomm does most of what this script does

from __future__ import division
from __future__ import print_function
import argparse
import sys
from pprint import pprint
import struct
import socket
import os

def comp_t_to_dec(u16):
    # comp_t are strange numbers -- of 16 bits, the first three are are
    # the exponent and the last 13 are the number.  The exp is base 8.
    mantissa = u16 & 017777
    exponent = u16 >> 13
    return mantissa * 8**exponent

def elapsed(t):
    t = int(t)
    days = t//60//60//24
    hours = (t - days * 24 * 60 *60) // 60 // 60
    mins = (t - days * 24 * 60 * 60 - hours * 60 * 60) // 60
    if days:
        return "%s+%02d:%02d" % (days, hours, mins)
    else:
        return "%d:%02d" % (hours, mins)

def main():
    parser = argparse.ArgumentParser(
            description="",
            formatter_class=argparse.ArgumentDefaultsHelpFormatter)
    parser.add_argument('pwfile')
    parser.add_argument('dumpfile')
    args = parser.parse_args()

    pw = {}
    gr = {}
    for line in open(args.pwfile):
        items = line.split(':')
        pw[int(items[2])] = items[0]
        gr[int(items[3])] = items[0]
    
    # flag masks linux/acct.h
    AFORK = 0x01 #   /* ... executed fork, but did not exec */
    ASU = 0x02   # /* ... used super-user privileges */
    ACOMPAT = 0x04 #   /* ... used compatibility mode (VAX only not used) */
    ACORE = 0x08   # /* ... dumped core */
    AXSIG = 0x10   # /* ... was killed by a signal */


    acct = open(args.dumpfile)
    while acct:
        item = acct.read(64)
        # see acct(5), prefix '_' indicates the field is always 0
        fields = ['flag', 'ver', 'tty', 'exitcode', 'uid', 'gid', 'pid', 'ppid', 
                    'btime', 'etime', 'utime', 'stime', 'mem', '_io', '_rw', 
                    'minflt', 'majflt', '_swaps', 'cmd']
        d = dict(zip(fields, struct.unpack('bbHIIIIIIfHHHHHHHH16s', item)))
        for f in ['utime', 'stime', 'mem', 'minflt', 'majflt']:
            d[f] = comp_t_to_dec(d[f])
        for f in ['utime', 'stime']:
            d[f] = d[f]*os.sysconf('SC_CLK_TCK')
        d['exitcode'] = socket.htons(d['exitcode']) # not sure why; other fields don't seem to need this
        d['cmd'] = d['cmd'].strip('\x00')
        d['tty'] = (d['tty'] >> 8, d['tty'] % 256)
        print(' '.join([
                '%-10s' % pw[d['uid']][:10],
                '%-15s' % d['cmd'],
                '%3s' % d['exitcode'],
                '%5sGB' % round(d['mem']/2**20, 1),
                '%3s%%' % (int(round(d['utime']/d['etime'])) if d['etime'] else '-'),
                '%3s%%' % (int(round(d['stime']/d['etime'])) if d['etime'] else '-'),
                '%s' % (elapsed(d['etime']) if d['etime'] else '-:--'),
                ]))
    return

    for line in open(args.dumpfile):
        items = line.strip().split('|')
        d = dict()
        print('%-15s     %-15s %-15s %10s  %s' % (
            items[8],
            pw[int(items[4].strip())],
            items[0].strip(),
            str(round(float(items[6])/2**20, 1)) + 'GB',
            '%s/%s/%s' % (int(float(items[1])), int(float(items[2])), int(float(items[3]))),
        ))


if __name__ == '__main__':
    sys.exit(main())

