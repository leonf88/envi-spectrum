#!/usr/bin/env python
# -*- encoding: utf-8 -*-

import spectral.io.envi as envi
import numpy as np
import math

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
        self._data_as_map = None
        self._data_processed_as_map = None

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
        if not self._data_as_map:
            self._data_as_map = {}
            for e in self._data:
                self._data_as_map[e[0]] = e[1]

        return self._data_as_map

    def get_processed_data_as_map(self, base = 1):
        """
        1. remove the decimal of the bandwidth by using round function
        2. fill the bandwidth with linear method

        :: base the divisor of value
        """
        if not self._data_processed_as_map:
            spectra_data = self.get_data_as_map()
            for k in spectra_data.keys():
                spectra_data[k] = spectra_data[k] / base
            bw = sorted(spectra_data.keys())

            self._data_processed_as_map = {}
            for idx in xrange(0, len(bw) - 1):
                x1, x2 = bw[idx], bw[idx + 1]
                y1, y2 = spectra_data[x1], spectra_data[x2]
                if x2 - x1 == 1:
                    self._data_processed_as_map[x1] = y1
                    self._data_processed_as_map[x2] = y2
                else:
                    a = np.array([
                            [x1, 1],
                            [x2, 1]
                        ])
                    b = np.array([y1, y2])
                    inv_a = np.linalg.inv(a)
                    p = np.dot(inv_a, b)

                    x_min = int(math.ceil(x1))
                    x_max = int(math.floor(x2))
                    for x in range(x_min, x_max + 1):
                        y = p[0] * x + p[1]
                        self._data_processed_as_map[x] = y

        return self._data_processed_as_map


