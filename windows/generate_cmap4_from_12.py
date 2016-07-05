#!/usr/bin/env python2
# -*- coding: utf-8 -*-
# 
# Some parts may be copyrighted Behdad Esfahbod and falls under the 
# LICENSE for FontTools found at https://github.com/behdad/fonttools/blob/master/LICENSE

"""\
usage: generate_cmap4_from_12.py [options] input.ttf output.ttf
"""
import os.path
import tempfile
import argparse
import sys

from fontTools.ttLib import TTFont
from fontTools.ttLib.tables._c_m_a_p import CmapSubtable


def main(argv):
    parser = argparse.ArgumentParser(
        description='Generate a cmap format 4 subtable when only a format 12 exists. This ensures Windows compatibility')
    parser.add_argument('input', metavar='input.ttf', help='the font with subtable 12')
    parser.add_argument('output', metavar='output.ttf',
        help='a filename where a copy of the font will be saved including subtable 4')

    args = parser.parse_args()
    font = TTFont(args.input)
    cmap = font['cmap']

    outtables = []

    for table in cmap.tables:
        outtables.append(table)
        if (table.format == 12 and
            table.platformID == 3 and
            table.platEncID == 10):
            # found a cmap12 3/10 subtable, create a matching cmap4 3/1 subtable
            # must restrict to BMP characters
            mapping = dict((k,v) for k,v in table.cmap.items() if k <= 0xFFFF)
            newtable = CmapSubtable.newSubtable(4)
            newtable.platformID = 3
            newtable.platEncID = 1
            newtable.language = table.language
            newtable.cmap = mapping
            outtables.append(newtable)

    if len(outtables) == len(cmap.tables):
        print("Whoops! Couldn't find a cmap subtable format 12, platform id 3, platform encoding 10.")
        return

    cmap.tables = outtables

    font.save(args.output)

if __name__ == "__main__":
    main(sys.argv)