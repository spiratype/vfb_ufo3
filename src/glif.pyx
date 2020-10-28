# coding: utf-8
# cython: wraparound=False
# cython: boundscheck=False
# cython: infer_types=True
# cython: cdivision=True
# cython: auto_pickle=False
# cython: c_string_type=unicode
# cython: c_string_encoding=utf_8
# distutils: language=c++
# distutils: extra_compile_args=[-O2, -fopenmp, -fconcepts, -Wno-register, -fno-strict-aliasing, -std=c++17]
# distutils: extra_link_args=[-fopenmp, -lz]
from __future__ import division, unicode_literals
include 'includes/future.pxi'

cimport cython
cimport fenv
from cython.operator cimport postincrement, preincrement
from vector cimport vector
from libcpp.string cimport string
from libcpp.utility cimport move, pair

include 'includes/archive.pxi'

import time

from FL import fl

def glifs(ufo):
  start = time.clock()
  _glifs(ufo)
  ufo.instance_times.glifs = time.clock() - start

def _glifs(ufo):

  '''
  build and write .glif files

  for glyph decomposition and overlap removal, UFO creation times can be
  reduced considerably by checking the font for glyphs normally consisting of
  components which do not overlap and build the contours for these components

  prior to building the contours for the selected components, the overlaps are
  removed

  the glyphs are selected based on Unicode code point and a user supplied glyph
  name list; the default list of these code points is located in `core.pxi` as
  `OPTIMIZE_CODE_POINTS`

  during the build process, the components will remain in component-form
  and the cached contour will be substituted in its place in the outline
  element of the .glif file, and shifted and/or scaled (if necessary) to match
  the component being replaced
  '''

  font = fl[ufo.instance.ifont]

  base_glyphs = ufo.glyph_sets.bases
  instance_glifs_path = ufo.paths.instance.glyphs
  path_sep = '/' if ufo.opts.ufoz else '\\'

  cdef:
    size_t i = 0
    size_t len_contours = 0
    size_t len_points = 0
    cpp_ufo ufo_lib
    cpp_glif glif
    string instance_ufoz_path = ufo.paths.instance.ufoz.encode('utf_8')
    float ufo_scale = ufo.scale if ufo.scale is not None else 0.0
    bytes name
    string glif_path
    long code_point = 0
    int mark = 0
    int width = 0
    bint base = 0
    bint omit = 0
    bint has_hints = 0
    bint build_hints = 0
    bint vertical_hints_only = ufo.opts.glyphs_hints_vertical_only
    bint build_hints_public = ufo.opts.glyphs_hints
    bint build_hints_afdko_v1 = ufo.opts.glyphs_hints_afdko_v1
    bint build_hints_afdko_v2 = ufo.opts.glyphs_hints_afdko_v2
    bint ufoz = ufo.opts.ufoz

  fenv.set_nearest()

  if build_hints_public or build_hints_afdko_v1 or build_hints_afdko_v2:
    build_hints = 1
    if build_hints_afdko_v1:
      ufo_lib.hint_type = 1
    elif build_hints_afdko_v2:
      ufo_lib.hint_type = 2
    else:
      ufo_lib.hint_type = 3

  ufo_lib.reserve(len(font.glyphs))
  ufo_lib.optimize = <bint>ufo.opts.glyphs_optimize
  ufo_lib.ufoz = ufoz

  prep_font(ufo, font)

  for i, m_glif in sorted(items(ufo.glifs)):
    glif_path = f'{instance_glifs_path}{path_sep}{m_glif.glif_name}'.encode('utf_8')
    glyph = font[i]
    width = max(glyph.width * ufo_scale, 0)
    len_contours = 0
    for node in glyph.nodes:
      if node.type == 17:
        postincrement(len_contours)
    len_points = len(glyph.Layer(0))

    glif = cpp_glif(m_glif.name, glif_path, m_glif.mark, width, i, len_points, m_glif.omit, m_glif.base)

    if m_glif.code_points:
      glif.code_points = m_glif.code_points

    if glyph.anchors:
      glif_anchors(glyph.anchors, glif.anchors)

    if glyph.components:
      glif_components(glyph.components, ufo, glif.components)

    if build_hints and (glyph.hhints or glyph.vhints or glyph.hlinks or glyph.vlinks):
      had_replace_table = bool(glyph.replace_table)
      prep_glyph_hints(glyph, vertical_hints_only, had_replace_table)
      if glyph.vhints:
        glif_hints(glyph.vhints, glif.vhints, 1)
      if glyph.hhints:
        glif_hints(glyph.hhints, glif.hhints)
      if had_replace_table:
        glif_hint_replacements(glyph.replace_table, glif.hint_replacements)

    if len_points and has_hints:
      glif_contours_hints(glyph, glif, ufo_lib, len_contours, len_points)
    elif len_points:
      glif_contours(glyph, glif, ufo_lib, len_contours, len_points)

    if ufo_scale:
      glif.scale(ufo_scale)

    ufo_lib.glifs.push_back(move(glif))

  if ufoz:
    ufo.archive = c_archive(instance_ufoz_path, <bint>ufo.opts.ufoz_compress)
    ufo.archive.reserve(ufo_lib.glifs.size() + 10)
    for glif in ufo_lib.glifs:
      ufo.archive[glif.path] = glif.repr(ufo_lib)
  else:
    write_glifs(ufo_lib)

def convert_links_to_hints(glyph):
  fl.TransformGlyph(glyph, 10, b'')

def rebuild_replace_table(glyph):
  fl.TransformGlyph(glyph, 8, b'')

def prep_glyph_hints(glyph, vertical_hints_only, had_replace_table):
  if vertical_hints_only:
    glyph.hlinks.clean()
    glyph.hhints.clean()
  if glyph.vlinks or glyph.hlinks:
    convert_links_to_hints(glyph)
  if had_replace_table:
    rebuild_replace_table(glyph)

def prep_font(ufo, font):

  decompose = ufo.opts.glyphs_decompose
  remove_overlaps = ufo.opts.glyphs_remove_overlaps
  optimize_code_points = ufo.code_points.optimize
  base_glyphs = ufo.glyph_sets.bases
  omit_glyphs = ufo.glyph_sets.omit
  optimized_glyphs = ufo.glyph_sets.optimized
  decompose_glyphs = ufo.glyph_sets.decompose
  remove_overlap_glyphs = ufo.glyph_sets.remove_overlap
  optimize_makeotf = ufo.opts.glyphs_optimize_makeotf
  glyphs_omit_names = ufo.opts.glyphs_omit_names
  glyphs_omit_suffixes = ufo.opts.glyphs_omit_suffixes
  vertical_hints_only = ufo.opts.glyphs_hints_vertical_only
  optimize = ufo.opts.glyphs_optimize

  if optimize_makeotf:
    for i in sorted(decompose_glyphs):
      font[i].Decompose()
    glyphs = remove_overlap_glyphs | base_glyphs
    for i in sorted(glyphs):
      font[i].RemoveOverlap()
    glyphs |= optimized_glyphs
    for i, glyph in enumerate(font.glyphs):
      if i not in glyphs:
        glyph.RemoveOverlap()

  elif decompose_glyphs or remove_overlap_glyphs:
    if decompose_glyphs:
      for i in sorted(decompose_glyphs):
        font[i].Decompose()
    if remove_overlap_glyphs:
      for i in sorted(remove_overlap_glyphs):
        font[i].RemoveOverlap()

  elif optimize and remove_overlaps:
    for i in sorted(base_glyphs):
      font[i].RemoveOverlap()
    for i, glyph in enumerate(font.glyphs):
      if glyph.unicode not in optimize_code_points and i not in optimized_glyphs:
        if glyph.components:
          glyph.Decompose()
        if i not in base_glyphs:
          glyph.RemoveOverlap()

  elif decompose and remove_overlaps:
    for i, glyph in enumerate(font.glyphs):
      if glyph.components:
        glyph.Decompose()
      if i not in base_glyphs:
        glyph.RemoveOverlap()

  elif decompose:
    for glyph in font.glyphs:
      if glyph.components:
        glyph.Decompose()

  elif remove_overlaps:
    for i, glyph in enumerate(font.glyphs):
      if i not in base_glyphs:
        glyph.RemoveOverlap()


cdef glif_anchors(glyph_anchors, vector[cpp_anchor] &anchors):

  cdef string name

  anchors.reserve(len(glyph_anchors))
  for anchor in glyph_anchors:
    name = anchor.name.decode('cp1252').encode('utf_8')
    anchors.emplace_back(name, <float>anchor.x, <float>anchor.y)


cdef glif_components(glyph_components, ufo, vector[cpp_component] &components):

  cdef:
    long offset_x = 0, offset_y = 0
    long scale_x = 0, scale_y = 0
    string base

  components.reserve(len(glyph_components))
  for component in glyph_components:
    offset_x, offset_y = component.delta.x, component.delta.y
    scale_x, scale_y = component.scale.x, component.scale.y
    i = component.index
    base = ufo.glyph_names[i].encode('utf_8')
    components.emplace_back(base, <size_t>i, offset_x, offset_y, scale_x, scale_y)


cdef glif_hints(glyph_hints, vector[cpp_hint] &hints, bint vertical=0):

  cdef:
    long hint_width
    bint ghost = 0

  hints.reserve(len(glyph_hints))
  for hint in glyph_hints:
    hint_width = hint.width
    ghost = bool(hint_width == -20 or hint_width == -21)
    hints.emplace_back(<long>hint.position, hint_width, vertical, ghost)


cdef glif_hint_replacements(glyph_replace_table, vector[cpp_hint_replacement] &hint_replacements):

  hint_replacements.reserve(len(glyph_replace_table))
  for replacement in glyph_replace_table:
    hint_replacements.emplace_back(<int>replacement.type, <size_t>replacement.index)


cdef glif_contours(glyph, cpp_glif &glif, cpp_ufo &ufo, size_t n_contours, size_t n_points):

  cdef:
    cpp_contour contour
    bint off = 0, cubic = 1
    int j = 0, k = 0
    long x0 = 0, x1 = 0, x2 = 0
    long y0 = 0, y1 = 0, y2 = 0
    int alignment = 0

  glif.contours.reserve(n_contours+1)
  contour.reserve(n_points+2)
  for node in glyph.nodes:

    if node.type == 17:
      start_node = node[0]
      if not contour.empty():
        glif.contours.push_back(contour)
        contour.clear()

    if node.count > 1:
      cubic = 1
      x0, y0 = node.points[1].x, node.points[1].y
      x1, y1 = node.points[2].x, node.points[2].y
      x2, y2 = node.x, node.y
      alignment = node.alignment
      contour.emplace_back(x0, y0)
      contour.emplace_back(x1, y1)
      if start_node == node[0]:
        contour[0] = cpp_contour_point(x2, y2, 1, alignment)
      else:
        contour.emplace_back(x2, y2, 1, alignment)
    else:
      x0, y0 = node.x, node.y
      if node.type == 65:
        off = 1
        cubic = 0
        glif.contours[j].emplace_back(x0, y0)
      elif cubic:
        alignment = node.alignment
        contour.emplace_back(x0, y0, 3, alignment)
      elif off:
        contour.emplace_back(x0, y0, 2)
        off = 0
      else:
        contour.emplace_back(x0, y0, 3)

  glif.contours.push_back(contour)
  ufo.contours[glif.index] = &glif.contours


cdef glif_contours_hints(glyph, cpp_glif &glif, cpp_ufo &ufo, size_t n_contours, size_t n_points):

  cdef:
    cpp_contour contour
    string name
    size_t j = 0, k = 0
    bint off = 0, cubic = 1
    long x0 = 0, x1 = 0, x2 = 0
    long y0 = 0, y1 = 0, y2 = 0
    int alignment = 0

  replacement_nodes = {0}
  if glyph.replace_table:
    for replacement in glyph.replace_table:
      if replacement.type == 255:
        replacement_nodes.add(replacement.index)

  glif.contours.reserve(n_contours+1)
  contour.reserve(n_points+2)
  for i, node in enumerate(glyph.nodes):

    if node.type == 17:
      start_node = node[0]
      if not contour.empty():
        glif.contours.push_back(contour)
        contour.clear()

    if node.count > 1:
      cubic = 1
      x0, y0 = node.points[1].x, node.points[1].y
      x1, y1 = node.points[2].x, node.points[2].y
      x2, y2 = node.x, node.y
      alignment = node.alignment
      contour.emplace_back(x0, y0)
      contour.emplace_back(x1, y1)
      if start_node == node[0]:
        if i in replacement_nodes:
          contour[0] = cpp_contour_point(x2, y2, 1, alignment, <int>i)
        else:
          contour[0] = cpp_contour_point(x2, y2, 1, alignment, contour[0].name)
      else:
        if i in replacement_nodes:
          contour.emplace_back(x2, y2, 1, alignment, <int>i)
        else:
          contour.emplace_back(x2, y2, 1, alignment)
    elif node.type == 65:
      off = 1
      cubic = 0
      x0, y0 = node.x, node.y
      contour.emplace_back(x0, y0)
    elif cubic:
      x0, y0 = node.x, node.y
      alignment = node.alignment
      if i in replacement_nodes:
        contour.emplace_back(x0, y0, 3, alignment, <int>i)
      else:
        contour.emplace_back(x0, y0, 3, alignment)
    elif off:
      x0, y0 = node.x, node.y
      contour.emplace_back(x0, y0, 2)
      off = 0
    else:
      x0, y0 = node.x, node.y
      if i in replacement_nodes:
        contour.emplace_back(x0, y0, 3, 0, <int>i)
      else:
        contour.emplace_back(x0, y0, 3)

  glif.contours.push_back(contour)
  ufo.contours[glif.index] = &glif.contours
