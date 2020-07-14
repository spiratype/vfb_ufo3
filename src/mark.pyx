# coding: utf-8
# cython: wraparound=False
# cython: boundscheck=False
# cython: infer_types=True
# cython: cdivision=True
# cython: auto_pickle=False
# distutils: extra_compile_args=[-O3, -fno-strict-aliasing]
from __future__ import division, unicode_literals
include 'includes/future.pxi'
include 'includes/cp1252.pxi'

cdef extern from 'math.h' nogil:
	double nearbyint(double x)

cdef extern from 'fenv.h' nogil:
	const int FE_TONEAREST
	int fesetround(int)

cdef double SCALE = 1.0

from collections import defaultdict
import os
import time

from FL import fl

from . import user

include 'includes/fea.pxi'

def mark_feature(ufo):
	return _mark_feature(ufo)

def _mark_feature(ufo):

	if ufo.scale is not None:
		global SCALE
		SCALE = ufo.scale

	font = fl[ufo.instance.ifont]
	fesetround(FE_TONEAREST)

	mark_classes = set()
	bases = defaultdict(list)
	for i, glyph in enumerate(font.glyphs):
		if glyph.anchors and i not in ufo.glyph_sets.omit:
			glyph_name = py_unicode(glyph.name)
			for anchor in glyph.anchors:
				if anchor.name:
					if anchor.name.startswith(b'_'):
						anchor_name = anchor.name[1:]
						if anchor_name in ufo.mark_classes:
							mark_classes.add(mark_class(glyph_name, anchor))
							continue
					if anchor.name in ufo.mark_classes:
						bases[glyph_name].append(anchor)

	mark_bases = defaultdict(list)
	for base, anchors in items(bases):
		for anchor in anchors:
			if anchor.name in ufo.mark_bases:
				mark_bases[anchor.name].append(mark_base(base, anchor))

	mark_bases = list(values(mark_bases))
	mark_lookups = [fea_lookup(f'mark{i}', sorted(bases))
		for i, bases in enumerate(mark_bases, start=1)]
	mark_classes = '\n'.join(sorted(mark_classes))

	lookups = '\n'.join(f'\tlookup mark{i};' for i in range(1, len(mark_bases)))

	return fea_feature('mark', [mark_classes, *mark_lookups, lookups])

def int_anchor_coords(x, y):
	return int(nearbyint(x * SCALE)), int(nearbyint(y * SCALE))

def mark_class(parent, anchor):
	x, y = int_anchor_coords(anchor.x, anchor.y)
	return f'\tmarkClass {parent} <anchor {x} {y}> @{py_unicode(anchor.name[1:])};'

def mark_base(base, anchor):
	x, y = int_anchor_coords(anchor.x, anchor.y)
	return f'\tpos base {base} <anchor {x} {y}> mark @{py_unicode(anchor.name)};'
