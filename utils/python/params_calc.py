#!/usr/bin/env python
# -*- encoding: utf-8 -*-
import sys
import math

reload(sys)  # Reload does the trick!
sys.setdefaultencoding('UTF8')

import spectral.io.envi as envi
from os import listdir
from os.path import isfile, join, splitext


class EnviReader():
    def __init__(self, filename):
        self._lib = envi.open(filename)
        if len(self._lib.spectra) == 1:
            self._spectra_0 = self._lib.spectra[0]
        else:
            raise ValueError('spectra has not 1 dimension.')
        self._centers = self._lib.bands.centers
        self._bands_len = len(self._centers)
        if len(self._spectra_0) != len(self._centers):
            print "Warn: bandwidth of spectra and centers are not the same."
        self._data = [(self._centers[i], self._spectra_0[i]) for i in xrange(self._bands_len)]

    def get_data(self):
        """
        return the spectra data as an array, and each point is (bandwidth, spectra).
        """
        return self._data

    def get_lib(self):
        return self._lib

    def get_data_as_map(self):
        """
        return the map data, key is bandwidth, and value is spectra data
        """
        self._data_as_map = {}
        for e in self._data:
            self._data_as_map[e[0]] = e[1]

        return self._data_as_map

def calc_params(spectra_data):
    r800 = spectra_data[800]
    r780 = spectra_data[780]
    r740 = spectra_data[740]
    r700 = spectra_data[700]
    r680 = spectra_data[680]
    r675 = spectra_data[675]
    r670 = spectra_data[670]
    r550 = spectra_data[550]
    r450 = spectra_data[450]

    try:
        mcari2 = (1.5 * (2.5 * (r800 - r670) - 1.3 * (r800 - r550))/math.sqrt((2 * r800 + 1) - (6 * r800 - 5 * math.sqrt(r670)) - 0.5))
    except ValueError, e:
        mcari2 = None

    ndvi = (r800 - r680)/(r800 + r680)
    rvi = r800 / r680
    evi = 2.5 * (r800 - r680)/(r800 + 6 * r680 - 7.5 * r450 + 1)
    osavi = 1.16 * (r800 - r680) / (r800 + r680 + 0.16)
    msavi = 0.5 * (2 * r800 + 1 - math.sqrt((2 * r800 + 1) ** 2 - 8 * (r800 - r670)))
    tci = (r800 + 1.5 * r550 - r675)/(r800 - r700)
    rep = 700 + (740 - 700) * ((r670 + r780)/2 - r700)/(r740 - r700)
    arvi = (r800 - (2 * r680 -r450))/(r800 + (2 * r680 - r450))

    return mcari2, ndvi, rvi, evi, osavi, msavi, tci, rep, arvi

data_path = 'processed'
onlyfiles = [f for f in listdir(data_path) if isfile(join(data_path, f))]
hdr_files = filter(lambda f: splitext(f)[1].lower() == '.hdr', onlyfiles)

with open('out.csv', 'w') as fout:
    fout.write("filename, mcari2, ndvi, rvi, evi, osavi, msavi, tci, rep, arvi\n")
    for filename in hdr_files:
        f_path = join(data_path, filename)
        envi_r = EnviReader(f_path)
        d = envi_r.get_data_as_map()
        fout.write(filename + ',' + ','.join(map(lambda e: str(e), calc_params(d))) + '\n')
