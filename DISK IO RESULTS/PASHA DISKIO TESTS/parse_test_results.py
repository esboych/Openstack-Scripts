#!/usr/bin/python

from __future__ import print_function

import sys
import numpy as np
import re
import argparse
import pprint

class SimpleReportParser(object):
    def __init__(self, filename):
        self.filename = filename

    def parse(self):
        result = []
        with file(self.filename) as fh:
            data = []
            for line in fh:
                if len(data) == len(self.REGEXPS):
                    t = {}
                    for v in data:
                        t.update(v)
                    result.append(t)
                    data = []
                for r in self.REGEXPS:
                    d = None
                    if callable(r):
                        d = r(line)
                    else:
                        m = r.search(line)
                        if m: d = m.groupdict()
                    if d: data.append(d)

        result = [
            tuple(t.get(k) for k in self.DTYPE.names) for t in result
        ]

        result = np.array(result, dtype=self.DTYPE)
        return result


class FIOReportParser(SimpleReportParser):
    HEADER_RE = re.compile(
        '(?P<op>\w+):.*rw=(?P=op), bs=(?P<bs>\w+).*iodepth=(?P<iodepth>\d+)'
    )

    # TODO merge BW_RE and LAT_RE parsing
    BW_RE = re.compile(
        'bw.*(?P<prefix>[KMG])B.*/s.*:\s*'
        'min=\s*(?P<bw_min>[0-9.]+)\s*,\s*'
        'max=\s*(?P<bw_max>[0-9.]+)\s*,\s*'
        'per=\s*(?P<bw_per>[0-9.]+)%\s*,\s*'
        'avg=\s*(?P<bw_avg>[0-9.]+)\s*,\s*'
        'stdev=\s*(?P<bw_stdev>[0-9.]+)'
    )
    LAT_RE = re.compile(
        '\slat.*(?P<unit>[mu]sec).*:\s*'
        'min=\s*(?P<lat_min>[0-9.]+[KM]?)\s*,\s*'
        'max=\s*(?P<lat_max>[0-9.]+[KM]?)\s*,\s*'
        'avg=\s*(?P<lat_avg>[0-9.]+[KM]?)\s*,\s*'
        'stdev=\s*(?P<lat_stdev>[0-9.]+[KM]?)'
    )

    def bw_re(i):
        r = FIOReportParser.BW_RE.search(i)
        if not r:
            return

        r = r.groupdict()
        prefix = r.pop('prefix')
        mul = dict(K=1, M=1024, G=1024*1024)[ prefix ]
        for k in 'bw_min', 'bw_max', 'bw_avg', 'bw_stdev':
            r[k] = float(r[k]) * mul

        return r

    def lat_re(i):
        r = FIOReportParser.LAT_RE.search(i)
        if not r:
            return

        r = r.groupdict()
        unit = r.pop('unit')
        mul = dict(usec=1, msec=1000)[unit]
        for k in 'lat_min', 'lat_max', 'lat_avg', 'lat_stdev':
            if r[k].endswith('K'):
                r[k] = float(r[k][:-1]) * 1000
            r[k] = float(r[k]) * mul

        return r

    REGEXPS = [HEADER_RE, bw_re, lat_re]
    DTYPE = np.dtype([
            ('op', 'S10'), ('bs', 'S10'), ('iodepth', np.int),

            ('bw_min', float), ('bw_max', float), ('bw_avg', float), 
            ('bw_per', float), ('bw_stdev', float),

            ('lat_min', float), ('lat_max', float), ('lat_avg', float), 
            ('lat_stdev', float)
    ])


def main():
    import argparse
    parser = argparse.ArgumentParser(description="Report parser")
    parser.add_argument('input', type=str, help='Input file name')
    parser.add_argument('output', type=str, help='Output file name')
    args = parser.parse_args()
    r = FIOReportParser(args.input)
    r = r.parse()
    np.save(args.output, r)

if __name__ == '__main__':
    main()
