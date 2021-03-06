# coding: utf-8
# cython: wraparound=False
# cython: boundscheck=False
# cython: infer_types=True
# cython: cdivision=True
# cython: auto_pickle=False
# distutils: extra_compile_args=[-O2, -fno-strict-aliasing]
from __future__ import division, unicode_literals
include 'includes/future.pxi'

cimport fenv
from libc.math cimport nearbyint

cdef double SCALE = 1.0

from collections import defaultdict
import time

from FL import fl

include 'includes/fea.pxi'

def mark_feature(ufo):
  return _mark_feature(ufo)

def _mark_feature(ufo):

  if ufo.scale is not None:
    global SCALE
    SCALE = ufo.scale

  font = fl[ufo.instance.ifont]
  fenv.set_nearest()

  mark_classes = set()
  bases = defaultdict(list)
  for i, glyph in enumerate(font.glyphs):
    if i in ufo.glyph_sets.omit:
      continue
    if glyph.anchors:
      for anchor in glyph.anchors:
        if anchor.name:
          if anchor.name.startswith(b'_'):
            anchor_name = anchor.name[1:]
            if anchor_name in ufo.mark_classes:
              mark_classes.add(mark_class(ufo.glyph_names[i], anchor))
              continue
          if anchor.name in ufo.mark_classes:
            bases[ufo.glyph_names[i]].append(anchor)

  mark_bases = defaultdict(list)
  for base, anchors in items(bases):
    for anchor in anchors:
      if anchor.name in ufo.mark_bases:
        mark_bases[anchor.name].append(mark_base(base, anchor))

  mark_bases = list(values(mark_bases))
  mark_lookups = [fea_lookup(f'mark{i}', sorted(bases))
    for i, bases in enumerate(mark_bases, start=1)]
  mark_classes = '\n'.join(sorted(mark_classes))

  lookups = '\n'.join(f'\tlookup mark{i+1};' for i in range(len(mark_bases)))

  feature = [mark_classes, *mark_lookups, lookups]
  return fea_feature('mark', feature) if mark_bases else ''

def int_anchor_coords(double x, double y):
  x, y = nearbyint(x * SCALE), nearbyint(y * SCALE)
  return int(x), int(y)

def mark_class(parent, anchor):
  x, y = int_anchor_coords(anchor.x, anchor.y)
  return f'\tmarkClass {parent} <anchor {x} {y}> @{anchor.name[1:].decode("cp1252")};'

def mark_base(base, anchor):
  x, y = int_anchor_coords(anchor.x, anchor.y)
  return f'\tpos base {base} <anchor {x} {y}> mark @{anchor.name.decode("cp1252")};'
