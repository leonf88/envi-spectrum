#!/usr/bin/env python
# -*- encoding: utf-8 -*-

import sys
import math

reload(sys)  # Reload does the trick!
sys.setdefaultencoding('UTF8')

from os import listdir
from os.path import isfile, join, splitext
from utils import EnviReader


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
