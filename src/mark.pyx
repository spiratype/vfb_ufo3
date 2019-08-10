# coding: utf-8
# cython: wraparound=False
# cython: boundscheck=False
# cython: infer_types=True
# cython: cdivision=True
# cython: auto_pickle=False
from __future__ import absolute_import, division, unicode_literals
include 'includes/future.pxi'
include 'includes/cp1252.pxi'

from collections import defaultdict
import os
import time

from FL import fl

from . import user

include 'includes/fea.pxi'
include 'includes/mark.pxi'

def mark_feature(ufo):
	return _mark_feature(ufo)

def _mark_feature(ufo):

	if ufo.scale is not None:
		global UFO_SCALE
		UFO_SCALE = <double>ufo.scale

	font = fl[ufo.instance.ifont]

	mark_classes = set()
	bases = defaultdict(list)
	for i, glyph in enumerate(font.glyphs):
		if glyph.anchors and i not in ufo.glyph_sets.omit:
			glyph_name = py_unicode(glyph.name)
			for anchor in glyph.anchors:
				if anchor.name:
					if b'_' in anchor.name[0]:
						anchor_name = anchor.name[1:]
						if anchor_name in ufo.anchors:
							mark_classes.add(mark_class(glyph_name, anchor))
							continue
					bases[glyph_name].append(anchor)

	mark_bases = defaultdict(list)
	for base, anchors in items(bases):
		for anchor in anchors:
			if anchor.name in ufo.anchors:
				mark_bases[anchor.name].append(mark_base(base, anchor))

	mark_bases = [bases for i, bases in enumerate(values(mark_bases)) if bases]
	mark_lookups = [fea_lookup(f'mark{i+1}', sorted(bases))
		for i, bases in enumerate(mark_bases)]
	mark_classes = '\n'.join(sorted(mark_classes))

	lookups = '\n'.join([f'\tlookup mark{i+1};' for i in range(len(mark_bases))])

	return fea_feature('mark', [mark_classes, *mark_lookups, lookups])
