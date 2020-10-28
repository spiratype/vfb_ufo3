# coding: utf-8
# cython: wraparound=False
# cython: boundscheck=False
# cython: infer_types=True
# cython: cdivision=True
# cython: auto_pickle=False
# cython: c_string_type=unicode
# cython: c_string_encoding=utf_8
# distutils: language=c++
# distutils: extra_compile_args=[-O2, -fconcepts, -Wno-register, -fno-strict-aliasing, -std=c++17]
from __future__ import division, unicode_literals, print_function
include 'includes/future.pxi'

cimport cython
cimport fenv
from cpython.dict cimport PyDict_SetItem
from libc.math cimport nearbyint
from libcpp.string cimport string

cdef double SCALE = 1.0

import time

from FL import fl, Feature, TrueTypeTable

from . import kern, mark

include 'includes/file.pxi'
include 'includes/fea.pxi'
include 'includes/opentype.pxi'
include 'includes/ordered_dict.pxi'

def copy_opentype(ufo, font):
  _copy_opentype(ufo, font)

def load_opentype(ufo, font):
  _load_opentype(ufo, font)

def tables(ufo, font):
  _tables(ufo, font)

def features(ufo):
  if ufo.master.ot_prefix or ufo.master.ot_features:
    start = time.clock()
    _features(ufo)
    ufo.instance_times.features = time.clock() - start

def _features(ufo):

  cdef bytes fea_file_bytes_str

  kern_file = ufo.opts.kern_feature_file_path

  groups = ''
  if ufo.opts.features_import_groups:
    if ufo.opts.kern_feature_passthrough:
      ufo_groups = ufo.groups.all
    else:
      ufo_groups = ufo.groups.opentype
    groups = [fea_group(*group) for group in sorted(items(ufo_groups))]
    groups = '# OpenType groups\n' + '\n'.join(groups)

  ot_features = []
  if ufo.master.ot_features:
    ot_features = list(ufo.master.ot_features.values())
  features = [groups, ufo.master.ot_prefix] + ot_features

  if ufo.opts.kern_feature_generate:
    if ufo.instance.kerning:
      features.append(kern.kern_feature(ufo))

  if ufo.opts.mark_feature_generate:
    features.append(mark.mark_feature(ufo))

  tables = []
  if ufo.opts.afdko_parts:
    tables = list(values(ufo.instance.tables))

  feature_file = features + tables

  if feature_file:
    feature_file = '\n\n'.join(feature_file) + '\n'
    if ufo.opts.ufoz:
      ufo.archive[ufo.paths.instance.features] = feature_file
    else:
      write_file(ufo.paths.instance.features, feature_file)


def _copy_opentype(ufo, master):

  # copy opentype features
  if master.features:
    ufo.master.ot_features = features = ordered_dict()
    for feature in master.features:
      if feature.tag == b'kern':
        if not ufo.opts.kern_feature_passthrough:
          continue
      features[feature.tag.decode('cp1252')] = feature.value.decode('cp1252').strip()

  # copy opentype prefix
  if master.ot_classes:
    ot_prefix = master.ot_classes.decode('cp1252').strip()
    if ot_prefix:
      ufo.master.ot_prefix = '\n'.join(ot_prefix.splitlines())


def _load_opentype(ufo, font):

  master = fl[ufo.master.ifont]
  if master.ot_classes:
    font.ot_classes = master.ot_classes
  if master.features:
    font.features.clean()
    for feature in master.features:
      if feature.tag == b'kern' and not ufo.opts.kern_feature_passthrough:
        continue
      font.features.append(Feature(feature.tag, feature.value))


def _tables(ufo, font):

  if ufo.scale is not None:
    global SCALE
    SCALE = ufo.scale

  fenv.set_nearest()

  tables = {}

  tables['OS/2'] = [
    ('TypoAscender', font.ttinfo.os2_s_typo_ascender),
    ('TypoDescender', font.ttinfo.os2_s_typo_descender),
    ('TypoLineGap', font.ttinfo.os2_s_typo_line_gap),
    ('winAscent', font.ttinfo.os2_us_win_ascent),
    ('winDescent', font.ttinfo.os2_us_win_descent),
    ('WeightClass', font.ttinfo.os2_us_weight_class),
    ('WidthClass', font.ttinfo.os2_us_width_class),
    ('FSType', font.ttinfo.os2_fs_type),
    ('XHeight', font.x_height[0]),
    ('CapHeight', font.cap_height[0]),
    ('Panose', (' '.join(str(i) for i in font.panose)
      if any(font.panose) else None)),
    ('Vendor', (f'"{font.vendor[:4]}"'
      if font.vendor or font.vendor.lower() != b'pyrs' else None)),
    ]

  code_pages = [CODE_PAGES.get(code_page)
    for code_page in sorted(font.codepages)]
  code_pages = [str(code_page) for code_page in code_pages
    if code_page is not None]
  if code_pages:
    tables['OS/2'].append(('CodePageRange', ' '.join(code_pages)))

  unicode_ranges = [str(unicode_range)
    for unicode_range in sorted(font.unicoderanges)]
  if unicode_ranges:
    tables['OS/2'].append(('UnicodeRange', ' '.join(unicode_ranges)))

  attributes, instance = ufo.instance_attributes, ufo.instance.completed
  tables['hhea'] = (
    ('CaretOffset', attributes[instance].get('openTypeHheaCaretOffset')),
    ('Ascender', font.ttinfo.hhea_ascender),
    ('Descender', font.ttinfo.hhea_descender),
    ('LineGap', font.ttinfo.hhea_line_gap),
    )

  tables['head'] = (
    ('FontRevision', attributes[instance].get('openTypeNameVersion', ufo.master.version)),
    )

  tables['name'] = []
  for name_record in ufo.instance.fontinfo['openTypeNameRecords']:
    nid = name_record['nameID']
    if nid not in OMIT_NIDS:
      pid = name_record['platformID']
      eid = name_record['encodingID']
      lid = name_record['languageID']
      nid_str = name_record['string']
      ids = ' '.join(str(i) for i in [pid, eid, lid] if i)
      tables['name'].append((nid, ('nameid', f'{nid} {ids} "{nid_str}"')))

  tables['name'] = [line for nid, line in sorted(tables['name'])]

  def scaled_table(table):
    return [(key, int(nearbyint(value * SCALE)))
      if key in SCALABLE_TABLE_KEYS and value else (key, value)
      for (key, value) in table]

  if ufo.scale:
    tables['OS/2'] = scaled_table(tables['OS/2'])
    tables['hhea'] = scaled_table(tables['hhea'])

  ufo.instance.tables = {tag: fea_table(tag, table)
    for tag, table in items(tables)}
