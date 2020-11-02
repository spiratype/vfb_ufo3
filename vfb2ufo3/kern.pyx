# coding: utf-8
# cython: wraparound=False
# cython: boundscheck=False
# cython: infer_types=True
# cython: cdivision=True
# cython: auto_pickle=False
# distutils: extra_compile_args=[-O2, -fno-strict-aliasing]
from __future__ import division, unicode_literals
include 'includes/future.pxi'

cimport cython
from cpython.dict cimport PyDict_SetItem
from libc.stdlib cimport abs

import time

from FL import fl

include 'includes/fea.pxi'
include 'includes/ordered_dict.pxi'

def kerning(ufo, font):
  start = time.clock()
  _kerning(ufo, font)
  ufo.instance_times.kern = time.clock() - start

def kern_feature(ufo):
  return _kern_feature(ufo)

cdef inline int pair_calc(int n_glyphs):

  '''
  find the number of possible pairs for a number of glyphs

  >>> pair_calc(20)
  190
  >>> pair_calc(10)
  45
  '''

  cdef int n_pairs = (n_glyphs * (n_glyphs - 1)) / 2
  return n_pairs

def _kerning(ufo, font):

  instance_kerning = _instance_kerning(ufo, font, ufo.scale)

  if instance_kerning:
    ufo.instance.kerning = ordered_dict()
    for first, kerning_pairs in sorted(items(instance_kerning)):
      if first in ufo.kern.firsts_by_key_glyph:
        first = ufo.kern.firsts_by_key_glyph[first]
      kerns = ordered_dict()
      for second, value in sorted(kerning_pairs):
        if second in ufo.kern.seconds_by_key_glyph:
          second = ufo.kern.seconds_by_key_glyph[second]
        kerns[second] = value
      ufo.instance.kerning[first] = kerns


def _instance_kerning(ufo, font, scale):

  def kern_pair(kern):
    if scale is not None:
      return ufo.glyph_names[kern.key], int(kern.value * scale)
    return ufo.glyph_names[kern.key], kern.value

  kerning = {}
  for i, glyph in enumerate(font.glyphs):
    if glyph.kerning:
      kerning[ufo.glyph_names[i]] = [kern_pair(kern) for kern in glyph.kerning]

  return kerning


def _kern_feature(ufo):

  cdef:
    long CHECK_LIMIT = 700_000
    long BLOCK_LIMIT = 720_000 # first subtable
    long STEP = 208_000        # step down for subsequent subtables
    long new_kerns = 0
    int MIN_VALUE = 0
    int value = 0
    int n_glyphs = 0
    int kerns = 0
    int subtables = 0
    bint check_next = 0
    bint first_group = 0
    bint second_group = 0

  if ufo.opts.kern_min_value is not None:
    MIN_VALUE = ufo.opts.kern_min_value

  pair_calcs = {}
  feature, no_block, block = [], [], []
  first_enum_block, second_enum_block = [], []
  for first, kerning_pairs in ufo.instance.kerning.items():
    first_group = 0
    if kerns > CHECK_LIMIT:
      check_next = 1
    if 'public.kern' in first:
      first_group = 1
    for second, value in kerning_pairs.items():
      second_group = 0
      if abs(value) < MIN_VALUE:
        continue
      if 'public.kern' in second:
        second_group = 1
      if first_group and second_group:
        n_glyphs = ufo.kern.glyphs_len[first] + ufo.kern.glyphs_len[second]
        if n_glyphs not in pair_calcs:
          new_kerns = pair_calc(n_glyphs)
          pair_calcs[n_glyphs] = new_kerns
        else:
          new_kerns = pair_calcs[n_glyphs]
        if check_next:
          if kerns + new_kerns > BLOCK_LIMIT:
            if not feature:
              CHECK_LIMIT -= STEP
              BLOCK_LIMIT -= STEP
            block.append('\tsubtable;')
            subtables += 1
            feature += block
            block = [f'\tpos @{first} @{second} {value};']
            kerns = new_kerns
            check_next = 0
            continue
        kerns += new_kerns
        block.append(f'\tpos @{first} @{second} {value};')
      elif first_group:
        first_enum_block.append(f'\tenum pos @{first} {second} {value};')
      elif second_group:
        second_enum_block.append(f'\tenum pos {first} @{second} {value};')
      else:
        no_block.append(f'\tpos {first} {second} {value};')

  feature += block

  if first_enum_block:
    first_enum_block.append('\tsubtable;')
  if second_enum_block:
    second_enum_block.append('\tsubtable;')

  feature = no_block + first_enum_block + second_enum_block + feature

  if subtables:
    feature = fea_lookup('kern1', feature, kern=1)

  groups = []
  if ufo.opts.features_import_groups:
    groups = [fea_group(name, glyphs, 1)
      for name, (_, glyphs) in sorted(items(ufo.groups.kerning))]

  feature = groups + feature

  return fea_feature('kern', feature)
