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
from libc.math cimport nearbyint
from libcpp.string cimport string
from libcpp_vector cimport vector

from collections import defaultdict
import os
import shutil
import stat
import threading
import time
import unicodedata
import uuid

import FL
from FL import fl, Font, NameRecord, Rect

from . import fea, kern
from .fontinfo import fontinfo
from .user import load_encoding

include 'includes/string.pxi'
include 'includes/thread.pxi'
include 'includes/path.pxi'
include 'includes/unique.pxi'
include 'includes/file.pxi'
include 'includes/codepoints.pxi'
include 'includes/defaults.pxi'
include 'includes/glifname.pxi'
include 'includes/nameid.pxi'
include 'includes/master_glif.pxi'

def process_master(ufo, master):
  _process_master(ufo, master)

def add_instance(ufo, *instance):
  _add_instance(ufo, *instance)

def build_goadb(ufo, font):
  _build_goadb(ufo, font)

def font_names(ufo, font):
  _font_names(ufo, font)

def check_glyph_unicodes(font):
  _check_glyph_unicodes(font)

def _process_master(ufo, master):

  ufo.glyph_names = {}
  ufo.glifs = {}
  ufo.kern.firsts = set()
  ufo.kern.seconds = set()
  ufo.glyph_sets.omit = {-1}
  ufo.glyph_sets.decompose = set()
  ufo.glyph_sets.remove_overlap = set()
  anchors = set()
  ufo.mark_classes = set()
  ufo.mark_bases = set()
  glyphs_omit_names = ufo.opts.glyphs_omit_names
  glyphs_omit_suffixes = ufo.opts.glyphs_omit_suffixes
  user_decompose_glyphs = ufo.opts.glyphs_decompose_names
  user_remove_overlap_glyphs = ufo.opts.glyphs_remove_overlap_names

  optimize_makeotf = ufo.opts.glyphs_optimize_makeotf

  for i, glyph in enumerate(master.glyphs):

    ufo.glyph_names[i] = glyph_name = glyph.name.decode('cp1252')

    if glyph.nodes and glyph.components and optimize_makeotf:
      ufo.glyph_sets.decompose.add(i)
      ufo.glyph_sets.remove_overlap.add(i)

    if user_decompose_glyphs and glyph.name in user_decompose_glyphs:
      ufo.glyph_sets.decompose.add(i)

    if user_remove_overlap_glyphs and glyph.name in user_remove_overlap_glyphs:
      ufo.glyph_sets.remove_overlap.add(i)

    if glyph.kerning:
      ufo.kern.firsts.add(glyph_name)
      for kerning_pair in glyph.kerning:
        ufo.kern.seconds.add(master[kerning_pair.key].name.decode('cp1252'))

    if glyph.name in ufo.opts.glyphs_omit_names:
      ufo.glyph_sets.omit.add(i)

    if b'.' in glyph.name and glyphs_omit_suffixes and glyph.name.endswith(glyphs_omit_suffixes):
      ufo.glyph_sets.omit.add(i)

    if i not in ufo.glyph_sets.omit:
      for anchor in glyph.anchors:
        if anchor.name:
          anchors.add(anchor.name)

    for component in glyph.components:
      ufo.glyph_sets.bases.add(component.index)
      base_name = master[component.index].name
      if base_name in glyphs_omit_names and optimize_makeotf:
        ufo.glyph_sets.decompose.add(i)
        ufo.glyph_sets.remove_overlap.add(i)
        break
      if b'.' in base_name and glyphs_omit_suffixes and optimize_makeotf:
        if base_name.endswith(glyphs_omit_suffixes):
          ufo.glyph_sets.decompose.add(i)
          ufo.glyph_sets.remove_overlap.add(i)
          break

  if ufo.opts.mark_feature_generate and anchors:
    process_anchors(ufo, anchors)

  for i, glyph in enumerate(master.glyphs):
    omit = i in ufo.glyph_sets.omit
    base = i in ufo.glyph_sets.bases
    ufo.glifs[i] = master_glif(ufo, i, glyph, ufo.opts.afdko_makeotf_release, omit, base)

  if ufo.opts.glyphs_optimize or ufo.opts.glyphs_optimize_makeotf or ufo.opts.glyphs_decompose:
    build_optimize(ufo, master)

  glyph_order(ufo, master)


def process_anchors(ufo, anchors):

  if ufo.opts.mark_anchors_omit:
    omit_anchors = set()
    for anchor in ufo.opts.mark_anchors_omit:
      omit_anchors.add(anchor)
      if not anchor.startswith(b'_'):
        omit_anchors.add(b'_%s' % anchor)
    anchors ^= omit_anchors
  elif ufo.opts.mark_anchors_include:
    include_anchors = set()
    for anchor in ufo.opts.mark_anchors_include:
      include_anchors.add(anchor)
      if not anchor.startswith(b'_'):
        include_anchors.add(b'_%s' % anchor)
    anchors &= include_anchors
  for anchor in anchors:
    if anchor.startswith(b'_'):
      ufo.mark_classes.add(anchor[1:])
    else:
      ufo.mark_bases.add(anchor)
  ufo.mark_classes = {anchor for anchor in ufo.mark_classes
    if anchor in ufo.mark_bases}


def master_instance(ufo, name, attributes, path):

  ufo.instance_times.total = time.clock()
  print(b'\nBuilding UFO ..\n')

  instance = fl[ufo.master.ifont]
  ufo.instance.ifont = ufo.master.ifont

  if ufo.master.ot_prefix or ufo.master.ot_features:
    fea.load_opentype(ufo, instance)

  load_encoding(ufo, instance)

  fontinfo(ufo, instance, attributes)
  font_names(ufo, instance)

  if ufo.instance.kerning:
    kern.kerning(ufo, instance)

  if ufo.opts.afdko_parts:
    fea.tables(ufo, instance)

  build_instance_paths(ufo, attributes, path)


def _add_instance(ufo, index, value, name, attributes, path):

  if ufo.instance_from_master:
    return master_instance(ufo, name, attributes, path)

  if ufo.start:
    ufo.start = 0
    if len(ufo.instance_values) > 1:
      print(b'\nBuilding instance UFOs..\n')
    else:
      print(b'\nBuilding instance UFO..\n')

  if index + 1 == len(ufo.instance_values):
    ufo.last = 1

  ufo.instance_times.total = time.clock()
  master = fl[ufo.master.ifont]
  instance = Font(master, value)
  fl.Add(instance)
  ufo.instance.ifont = ifont = fl.ifont
  rect = Rect(0, 0, 0, 0)
  fl.SetFontWindow(ifont, rect, 1)
  fl.SetFontWindow(ifont, rect, 1)

  instance = fl[ifont]
  instance.modified = 0
  family_name = ufo.master.family_name.encode('cp1252', 'ignore')
  instance.full_name = f'{family_name} {name}'.encode('cp1252', 'ignore')
  instance.family_name = family_name

  ufo.instance.index = index

  load_encoding(ufo, instance)
  fontinfo(ufo, instance, attributes)
  font_names(ufo, instance)

  kern.kerning(ufo, instance)

  if ufo.opts.afdko_parts:
    fea.tables(ufo, instance)

  build_instance_paths(ufo, attributes, path)


def build_instance_paths(ufo, attributes, path):

  ufo.paths.instance.ufoz = path.replace('.ufo', '.ufoz')
  bare_filename = os_path_basename(path).replace('.ufo', '')

  if ufo.opts.ufoz:
    ufo.paths.instance.ufo = ufo_path = os_path_basename(path)
    if ufo.opts.force_overwrite and os_path_isfile(ufo.paths.instance.ufoz):
      remove_path(ufo.paths.instance.ufoz, force=1)
  else:
    ufo.paths.instance.ufo = ufo_path = path
    if ufo.opts.force_overwrite and os_path_isdir(ufo.paths.instance.ufo):
      remove_path(ufo.paths.instance.ufo, force=1)

  ufo.paths.instance.glyphs = glyphs = os_path_join(ufo_path, 'glyphs')
  ufo.paths.instance.features = os_path_join(ufo_path, 'features.fea')
  ufo.paths.instance['glyphs_contents'] = os_path_join(glyphs, 'contents.plist')
  for plist, _ in UFO_PATHS_INSTANCE_PLISTS:
    ufo.paths.instance[plist] = os_path_join(ufo_path, f'{plist}.plist')

  if not ufo.opts.ufoz:
    os_makedirs(glyphs)

  if ufo.opts.afdko_parts:
    exts = {
      'fontnamedb': '.FontMenuNameDB',
      'goadb': '.GlyphOrderAndAliasDB',
      'makeotf_cmd': '_makeotf.bat',
      }
    postscript_name = attributes.get('postscriptFontName', bare_filename)
    ufo.paths.instance.otf = os_path_join(ufo.paths.out, f'{postscript_name}.otf')
    for file, _ in UFO_PATHS_INSTANCE_AFDKO:
      path = os_path_join(ufo.paths.out, f'{bare_filename}{exts[file]}')
      ufo.paths.instance[file] = path
    if os_path_isfile(ufo.paths.GOADB):
      ufo.paths.afdko.goadb = ufo.paths.GOADB

  if ufo.opts.psautohint_cmd:
    path = os_path_join(ufo.paths.out, f'{bare_filename}_psautohint.bat')
    ufo.paths.instance.psautohint_cmd = path

  for key, path in items(ufo.paths.instance):
    if path is not None:
      ufo.paths.instance[key] = path


def _build_goadb(ufo, font):

  if os_path_isfile(ufo.paths.GOADB):
    ufo.afdko.GOADB = [line.split()
      for line in read_file(ufo.paths.GOADB).splitlines()]
  else:
    goadb_from_encoding(ufo, font)


def goadb_from_encoding(ufo, font):

  def font_glyph_code_point(glyph_name):
    glyph = font[font.FindGlyph(glyph_name)]
    if glyph.unicode:
      return [glyph_name.decode('cp1252'), uni_name(glyph.unicode)]
    return [glyph_name.decode('cp1252'), None]

  first_256 = []
  first_256_names = []

  if ufo.opts.afdko_makeotf_GOADB_win1252:
    first_256 = WIN_1252
  elif ufo.opts.afdko_makeotf_GOADB_macos_roman:
    first_256 = MACOS_ROMAN

  if first_256:
    first_256_names = [font[font.FindGlyph(code_point)].name.decode('cp1252')
      for code_point in first_256 if font.has_key(code_point)]
  elif font.has_key(b'.notdef'):
    first_256_names = ['.notdef']
  goadb_names = [glyph for glyph in ufo.glyph_order
    if glyph not in set(first_256_names)]

  ufo.afdko.GOADB = [[glyph_name, None] for glyph_name in first_256_names]
  ufo.afdko.GOADB += [font_glyph_code_point(glyph) for glyph in goadb_names]


def glyph_order(ufo, font):

  encoding = read_file(ufo.paths.encoding).encode('cp1252', 'ignore').splitlines()
  encoding = [line.split()[0] for line in encoding[1:] if line]
  glyphs_from_encoding = [glyph for glyph in encoding
    if font.has_key(glyph) and font.FindGlyph(glyph) not in ufo.glyph_sets.omit]
  glyphs = set(glyphs_from_encoding) | ufo.glyph_sets.omit
  for glyph in font.glyphs:
    if glyph.name not in glyphs:
      glyphs_from_encoding.append(glyph.name)
  ufo.glyph_order = glyphs_from_encoding


def _font_names(ufo, font):

  # Font full name
  font.full_name = f'{font.family_name} {font.style_name}'.encode('cp1252')
  # PS font name
  font.font_name = f'{font.family_name}-{font.style_name}'.replace(' ', '')[:31].encode('cp1252')
  # Menu name
  font.menu_name = font.family_name
  # FOND name
  font.apple_name = font.full_name
  # TrueType Unique ID
  if font.source:
    font.tt_u_id = f'{font.source}: {font.full_name}: {font.year}'.encode('cp1252')
  else:
    font.tt_u_id = f'{font.full_name}: {font.year}'.encode('cp1252')
  # Font style name
  if font.font_style in {1, 33}:
    font.style_name = f'{font.weight} Italic'.encode('cp1252')
  else:
    font.style_name = font.weight
  # OpenType family name
  font.pref_family_name = font.family_name
  # OpenType Mac name
  font.mac_compatible = font.apple_name
  # OpenType style name
  font.pref_style_name = font.style_name


def ms_mac_names(ufo, font, platform_id):

  if not font.pref_family_name:
    font.pref_family_name = font.family_name

  if not font.pref_style_name:
    font.pref_style_name = font.style_name

  font.tt_version = b'Version %s' % ufo.master.version

  names = [
    font.copyright,        # 0
    font.family_name,      # 1
    font.style_name,       # 2
    font.tt_u_id,          # 3
    font.full_name,        # 4
    font.tt_version,       # 5
    font.font_name,        # 6
    font.trademark,        # 7
    font.source,           # 8
    font.designer,         # 9
    font.notice,           # 10
    font.vendor_url,       # 11
    font.designer_url,     # 12
    font.license,          # 13
    font.license_url,      # 14
    '',                    # 15
    font.pref_family_name, # 16
    font.pref_style_name,  # 17
    # mac_name             # 18
    # sample_text          # 19
    # postscript cid name  # 20
    ]

  if platform_id == 1:
    names.append(font.mac_compatible)
  elif platform_id == 3:
    names[4] = font.font_name

  return [(nid, nameid_str(name.decode('cp1252'), platform_id, 1))
    for nid, name in enumerate(names) if name]


def _check_glyph_unicodes(font):

  code_points = set()
  unicode_errors = defaultdict(list)
  for glyph in font.glyphs:
    for code_point in glyph.unicodes:
      if code_point not in code_points:
        code_points.add(code_point)
      else:
        glyph_name = glyph.name.decode('cp1252')
        unicode_errors[code_point].append(glyph_name)

  message = []
  if unicode_errors:
    for code_point, glyph_names in sorted(items(unicode_errors)):
      message.append(f"'{hex_code_point(code_point)}' is mapped to more than one glyph:")
      for glyph_name in glyph_names:
        message.append(f'  {glyph_name}')

    raise GlyphUnicodeError('\n'.join(message))


def build_optimize(ufo, master):

  '''
  check font for glyphs with Unicode code points in the code point set
  check font for small cap variants of glyphs
  '''

  # add all glyphs with components to optimized glyph set if not removing overlaps
  if ufo.opts.glyphs_decompose and not ufo.opts.glyphs_remove_overlaps:
    ufo.glyph_sets.optimized = {i for i, glyph in enumerate(master.glyphs)
      if glyph.components}
    return

  # check glyphs in code point glyph set and user glyph name set
  ufo.glyph_sets.optimized, names = set(), []
  for i, glyph in enumerate(master.glyphs):
    if glyph.unicode and glyph.unicode in ufo.code_points.optimize and glyph.components:
      ufo.glyph_sets.optimized.add(i)
      names.append(glyph.name)
      continue
    if glyph.name in ufo.opts.glyphs_optimize_names:
      glyph_index = master.FindGlyph(glyph.name)
      if glyph_index > -1:
        glyph = master[glyph_index]
        ufo.glyph_sets.optimized.add(glyph_index)
        names.append(glyph.name)

  # check for small cap variants of glyphs found in code point glyph set
  suffixes = (b'.sc', b'.smcp', b'.c2sc')
  sc_names = [(b'%s.sc' % name, b'%s.smcp' % name, b'%s.c2sc' % name)
    for name in names if not name.endswith(suffixes)]
  for names in sc_names:
    for name in names:
      glyph_index = master.FindGlyph(name)
      if glyph_index > -1 and master[glyph_index].components:
        ufo.glyph_sets.optimized.add(glyph_index)
        break


def master_glif(ufo, i, glyph, release, omit, base):
  glyph_name = glyph.name
  glif_name = GLIFNAMES.get(glyph_name)
  if glif_name is None:
    glif_name = glifname(glyph_name, release, omit)
  return c_master_glif(ufo.glyph_names[i].encode('utf_8'), glif_name.encode('utf_8'),
    min(glyph.mark, 255), glyph.unicodes, omit, base)
