#!/usr/bin/python

from __future__ import print_function

import sys

import numpy as np
import matplotlib.pyplot as plt
import collections

class PlotResults(object):
    def __init__(self, files, savefig=None):
        if len(files) == 1 and not files[0].endswith('.npy'):
            files = self._read_list_from_file(files[0])
        self.data = collections.OrderedDict()
        for filename in files:
            label = filename
            if ':' in filename:
                label, filename = filename.split(':', 1)
            v = np.load(filename)
            v = v.view(np.recarray)
            self.data[label] = v

        self.color=plt.cm.rainbow(np.linspace(0, 1, len(self.data)))
        self.savefig = savefig

    def plot_bw(self):
        return self._plot(ylabel='bandwidth KB/s', prefix='bw_')

    def plot_lat(self):
        return self._plot(ylabel='latency usec', prefix='lat_')

    def _plot(self, ylabel, prefix):
        v = self.data.values()[0]
        for bs in np.unique(v.bs):
            #f, axes = plt.subplots(1, 4)
            f = plt.figure(figsize=(10, 8))
            f.suptitle('blocksize %s' % bs)
            prevax = None
            for i, op in enumerate(np.unique(v.op)):
                kwargs = {}
                if i % 2:
                    kwargs['sharey'] = prevax
                ax = plt.subplot(2, 2, i + 1, **kwargs)
                ax.set_xlabel('queue depth')
                ax.set_xticks(range(len(np.unique(v.iodepth))))
                ax.set_xticklabels(v.iodepth)
                ax.set_title(op)
                ax.set_xlim(-0.5, len(np.unique(v.iodepth)))
                ax.yaxis.grid(True)
                if i % 2:
                    plt.setp(ax.get_yticklabels(), visible=False)
                else:
                    ax.set_ylabel(ylabel)
                for dn, (label, data) in enumerate(self.data.items()):
                    data = data[(data.bs == bs) * (data.op == op)]
                    line = ax.bar(
                        np.arange(len(data.iodepth)) + dn * 0.25,
                        data[prefix + 'avg'], 0.2,
                        yerr=data[prefix + 'stdev'], label=label,
                        align='center', color=self.color[dn],
                        error_kw={'ecolor': 'k', 'elinewidth': 2,
                                  'capsize': 5}
                    )
                prevax = ax
                if i == 0:
                    plt.legend(loc='best', numpoints=1)
                ax.set_ylim(ymin=0)

            f.tight_layout()

            if self.savefig:
                fname = self.savefig + '_' + bs + '.pdf'
                if '%' in self.savefig:
                    fname = self.savefig % bs
                f.savefig(fname)

        pass

if __name__ == '__main__':
    import argparse
    parser = argparse.ArgumentParser(description='Plot test results')
    parser.add_argument('results', metavar='result', nargs='+',
                        help='results to plot. use Title:Filename for titles')
    parser.add_argument('--save', dest='savefig_template',
                        help='savefig template')
    parser.add_argument('--dontshow', dest='show', action='store_const',
                        const=False, default=True,
                        help='dont show results, only savefig')
    parser.add_argument('--latency', action='store_const',
                        const=True, default=False,
                        help='plot latencies (default is to plot bandwidth)')
    args = parser.parse_args()
    plotter = PlotResults(files=args.results, savefig=args.savefig_template)
    if args.latency:
        plotter.plot_lat()
    else:
        plotter.plot_bw()
    if args.show:
        plt.show()
