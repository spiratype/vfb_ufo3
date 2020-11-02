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
from cpython.dict cimport PyDict_SetItem
from libcpp.string cimport string
from libcpp_vector cimport vector

import os
import shutil
import stat
import threading
import time
import uuid

from FL import fl

include 'includes/thread.pxi'
include 'includes/path.pxi'
include 'includes/unique.pxi'
include 'includes/file.pxi'
include 'includes/flc.pxi'
include 'includes/groups.pxi'
include 'includes/plist.pxi'
include 'includes/ordered_dict.pxi'

def groups(ufo):
  start = time.clock()
  _groups(ufo)
  ufo.total_times.groups = time.clock() - start

def _groups(ufo):

  ufo.groups.opentype = {}
  ufo.groups.kerning = {}
  ufo.kern.firsts_by_key_glyph = {}
  ufo.kern.seconds_by_key_glyph = {}
  ufo.kern.key_glyph_from_group = {}
  ufo.kern.glyphs_len = {}

  master = fl[ufo.master.ifont]
  if ufo.opts.groups_flc_path is not None:
    import_flc_groups(ufo, master)
  elif ufo.opts.groups_plist_path is not None:
    import_plist_groups(ufo, master)
  else:
    import_groups(ufo, master)

  finish_groups(ufo)

  if ufo.opts.groups_export_flc:
    write_flc(ufo)

def finish_groups(ufo):

  if ufo.groups.opentype or ufo.groups.kerning:
    ufo.groups.all = ordered_dict()

  if ufo.groups.opentype:
    for name, glyphs in sorted(items(ufo.groups.opentype)):
      ufo.groups.all[name] = glyphs

  if ufo.groups.kerning:
    for name, (second, glyphs) in sorted(items(ufo.groups.kerning)):
      ufo.groups.all[name] = glyphs
      ufo.kern.glyphs_len[name] = len(glyphs)
      if second:
        ufo.kern.seconds.update(glyphs)
      else:
        ufo.kern.firsts.update(glyphs)

def import_groups(ufo, font):

  print(b' Processing font groups..')

  ufo.groups.opentype, kern_groups, key_glyphs = parse_groups(font)
  firsts, seconds = parse_kerns(ufo, font)

  no_kerning = {}
  for name, glyphs in items(kern_groups):
    lc_name = name.lower()
    key_glyph = key_glyphs[name]
    first = (
      key_glyph in firsts or PREFIX_1 in lc_name or
      'mmk_l' in lc_name or lc_name.endswith('_l')
      )
    second = (
      key_glyph in seconds or PREFIX_2 in lc_name or
      'mmk_r' in lc_name or lc_name.endswith('_r')
      )
    if first:
      ufo.groups.kerning[name] = (0, glyphs)
      ufo.kern.firsts_by_key_glyph[key_glyph] = name
      ufo.kern.key_glyph_from_group[name] = key_glyph
    if second:
      ufo.groups.kerning[name] = (1, glyphs)
      ufo.kern.seconds_by_key_glyph[key_glyph] = name
      ufo.kern.key_glyph_from_group[name] = key_glyph
    if not first and not second:
      no_kerning[name] = key_glyph

  if no_kerning and not ufo.opts.groups_ignore_no_kerning:
    parse_no_kerns(ufo, font, no_kerning, key_glyphs)


def parse_groups(font):

  opentype_groups, kern_groups, key_glyphs = {}, {}, {}
  for group in font.classes:
    if group.startswith(b'.mtrx'):
      continue
    name, glyphs = group.decode('cp1252').split(': ')
    if name.startswith('_'):
      name = name[1:]
      key_glyph, no_key_glyph = group_key_glyph(glyphs, ("'" in glyphs))
      if no_key_glyph:
        KeyGlyphWarning(name, key_glyph)
        key_glyph = glyphs[0]
      kern_groups[name] = glyphs.replace("'", '').split()
      key_glyphs[name] = key_glyph
    else:
      opentype_groups[name] = glyphs.split()

  return opentype_groups, kern_groups, key_glyphs


def parse_kerns(ufo, font):

  firsts, seconds = set(), set()
  for i, glyph in enumerate(font.glyphs):
    if glyph.kerning:
      firsts.add(ufo.glyph_names[i])
      for kern in glyph.kerning:
        seconds.add(ufo.glyph_names[kern.key])

  return firsts, seconds


def parse_no_kerns(ufo, font, no_kerning, key_glyphs):

  print(b' Processing groups with no kerning for master.vfb...')

  ufo.groups.no_kerning = no_kerning = set(no_kerning.keys())
  for i, group in enumerate(font.classes):
    if not group.startswith(b'_'):
      continue
    name, glyphs = group[1:].decode('cp1252').replace("'", '').split(': ')
    if name not in no_kerning:
      continue
    glyphs = glyphs.split()
    key_glyph = key_glyphs[name]
    first, second = font.GetClassLeft(i), font.GetClassRight(i)
    if not first and not second:
      ClassMarkerWarning(name)
      continue
    if first:
      name = PREFIX_1 + key_glyph
      ufo.groups.kerning[name] = (0, glyphs)
      ufo.kern.firsts_by_key_glyph[key_glyph] = name
      ufo.kern.key_glyph_from_group[name] = key_glyph
    if second:
      name = PREFIX_2 + key_glyph
      ufo.groups.kerning[name] = (1, glyphs)
      ufo.kern.seconds_by_key_glyph[key_glyph] = name
      ufo.kern.key_glyph_from_group[name] = key_glyph


def import_flc_groups(ufo, font):

  print(f' Importing groups from {os_path_basename(ufo.paths.flc)}..')

  flc_file = read_file(ufo.paths.flc).decode('cp1252')
  flc_groups = parse_flc(flc_file)

  for name, (flag, glyphs) in items(flc_groups):
    if flag is None:
      ufo.groups.opentype[name] = glyphs.split()
      continue
    key_glyph, no_key_glyph = group_key_glyph(glyphs, ("'" in glyphs))
    if no_key_glyph:
      KeyGlyphWarning(name, key_glyph)
      glyphs = glyphs.split()
    else:
      glyphs = glyphs.replace("'", '').split()
    if 'L' in flag:
      name = PREFIX_1 + key_glyph
      ufo.groups.kerning[name] = (0, glyphs)
      ufo.kern.firsts_by_key_glyph[key_glyph] = name
      ufo.kern.key_glyph_from_group[name] = key_glyph
    if 'R' in flag:
      name = PREFIX_2 + key_glyph
      ufo.groups.kerning[name] = (1, glyphs)
      ufo.kern.seconds_by_key_glyph[key_glyph] = name
      ufo.kern.key_glyph_from_group[name] = key_glyph

  ufo.groups.imported = 1


def import_plist_groups(ufo, font):

  print(f' Importing groups from {os_path_basename(ufo.paths.groups_plist)}..')

  plist = read_file(ufo.paths.groups_plist).decode('utf_8')

  if '@MMK' in plist:
    for (ver1, ver2) in (('@MMK_L_', PREFIX_1), ('@MMK_R_', PREFIX_2)):
      plist = plist.replace(ver1, ver2)

  plist_groups = parse_plist(plist)

  for name, glyphs in items(plist_groups):
    if 'public.kern' not in name:
      ufo.groups.opentype[name] = glyphs
      continue
    key_glyph = name[13:]
    if PREFIX_1 in name:
      name = PREFIX_1 + key_glyph
      ufo.groups.kerning[name] = (0, glyphs)
      ufo.kern.firsts_by_key_glyph[key_glyph] = name
      ufo.kern.key_glyph_from_group[name] = key_glyph
    else:
      name = PREFIX_2 + key_glyph
      ufo.groups.kerning[name] = (1, glyphs)
      ufo.kern.seconds_by_key_glyph[key_glyph] = name
      ufo.kern.key_glyph_from_group[name] = key_glyph

  ufo.groups.imported = 1

def write_flc(ufo):

  if ufo.opts.groups_export_flc_path:
    filename = os_path_basename(ufo.opts.groups_export_flc_path)
    flc_export_path = ufo.opts.groups_export_flc_path
  else:
    version = ufo.master.version.replace('.', '_')
    if ufo.master.font_style in (1, 33):
      filename = f'{ufo.master.family_name}_Italic_{version}.flc'
    else:
      filename = f'{ufo.master.family_name}_{version}.flc'
    flc_export_path = os_path_join(ufo.paths.out, filename)

  if os_path_isfile(flc_export_path):
    if ufo.opts.force_overwrite:
      remove_path(flc_export_path, force=1)
    else:
      raise RuntimeError(b'%s already exists.\n'
        b'Please rename or move existing class file' % flc_export_path)

  print(f' Writing {filename}..')

  flc_file = [f'{FLC_HEADER}\n']
  flc_end_marker = f'{FLC_END_MARKER}\n'
  for name, glyphs in sorted(items(ufo.groups.opentype)):
    flc_file += [
      f'{FLC_GROUP_MARKER} {name}',
      f'{FLC_GLYPHS_MARKER} {" ".join(glyphs)}',
      flc_end_marker,
      ]
  for name, (second, glyphs) in sorted(items(ufo.groups.kerning)):
    key_glyph = ufo.kern.key_glyph_from_group[name]
    glyphs = insert_key_glyph(glyphs, key_glyph)
    group_marker = FLC_RIGHT_KERNING_MARKER if second else FLC_LEFT_KERNING_MARKER
    flc_file += [
      f'{FLC_GROUP_MARKER} _{name}',
      f'{FLC_GLYPHS_MARKER} {glyphs}',
      group_marker,
      flc_end_marker,
      ]

  write_file(flc_export_path, '\n'.join(flc_file))
