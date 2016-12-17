#!/usr/bin/env python
# -*- encoding: utf-8 -*-

import spectral.io.envi as envi

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
