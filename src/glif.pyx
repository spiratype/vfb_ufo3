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
from cython.operator cimport postincrement
from vector cimport vector
from libcpp.string cimport string
from libcpp.unordered_set cimport unordered_set
from libcpp.utility cimport move

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

	decompose = ufo.opts.glyphs_decompose
	remove_overlaps = ufo.opts.glyphs_remove_overlaps
	optimize_code_points = ufo.code_points.optimize
	base_glyphs = ufo.glyph_sets.bases
	optimized_glyphs = ufo.glyph_sets.optimized
	omit_glyphs = ufo.glyph_sets.omit

	font = fl[ufo.instance.ifont]

	instance_glifs_path = ufo.paths.instance.glyphs
	path_sep = '/' if ufo.opts.ufoz else '\\'

	cdef:
		size_t i = 0
		size_t len_points = 0
		size_t len_anchors = 0
		size_t len_components = 0
		size_t len_vhints = 0
		size_t len_hhints = 0
		size_t len_hint_replacements = 0
		cpp_ufo ufo_lib
		cpp_code_points* code_points
		cpp_anchors* anchors
		cpp_components* components
		cpp_contours* contours
		cpp_hints* vhints
		cpp_hints* hhints
		cpp_hint_replacements* hint_replacements
		string instance_ufoz_path = ufo.paths.instance.ufoz.encode('utf_8')
		float ufo_scale = ufo.scale if ufo.scale is not None else 0.0
		bytes name
		string glif_path
		long code_point = 0
		int mark = 0
		int width = 0
		bint base = 0
		bint omit = 0
		bint ufoz = ufo.opts.ufoz
		bint ufoz_compress = ufo.opts.ufoz_compress
		bint optimize = ufo.opts.glyphs_optimize
		bint build_hints = ufo.opts.glyphs_hints
		bint build_hints_afdko_v1 = ufo.opts.glyphs_hints_afdko_v1
		bint build_hints_afdko_v2 = ufo.opts.glyphs_hints_afdko_v2
		bint vertical_hints_only = ufo.opts.glyphs_hints_vertical_only

	fenv.set_nearest()

	if build_hints or build_hints_afdko_v1 or build_hints_afdko_v2:
		if build_hints_afdko_v1:
			ufo_lib.hint_type = 1
		elif build_hints_afdko_v2:
			ufo_lib.hint_type = 2
		else:
			ufo_lib.hint_type = 3
		build_hints = 1

	ufo_lib.reserve(len(font.glyphs), ufo.len_code_points, ufo.len_anchors, ufo.len_components, ufo.len_contours)
	if build_hints:
		ufo_lib.hints_reserve(ufo.len_vhints, ufo.len_hhints, ufo.len_hint_replacements)

	if optimize and remove_overlaps:
		for i, glyph in enumerate(font.glyphs):
			if i in base_glyphs:
				glyph.RemoveOverlap()
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

	for i, (name, glif_name, mark, glyph_code_points, omit) in items(ufo.glifs):
		base = i in base_glyphs
		omit = i in omit_glyphs
		glif_path = f'{instance_glifs_path}{path_sep}{glif_name}'.encode('utf_8')
		glyph = font[i]
		width = glyph.width * ufo_scale
		len_code_points = len(glyph_code_points)
		len_anchors = len(glyph.anchors)
		len_components = len(glyph.components)
		len_points = len(glyph.Layer(0))
		len_vhints = 0
		len_hhints = 0
		len_hint_replacements = 0
		code_points = NULL
		anchors = NULL
		components = NULL
		contours = NULL
		vhints = NULL
		hhints = NULL
		hint_replacements = NULL

		if len_code_points:
			ufo_lib.code_points[i] = glif_code_points(glyph_code_points)
			code_points = &ufo_lib.code_points[i]
		if len_anchors:
			ufo_lib.anchors[i] = glif_anchors(glyph.anchors)
			anchors = &ufo_lib.anchors[i]
		if len_components:
			ufo_lib.components[i] = glif_components(glyph.components, ufo)
			components = &ufo_lib.components[i]
		if len_points and not build_hints:
			ufo_lib.contours[i] = glif_contours(glyph.nodes)
			contours = &ufo_lib.contours[i]
		if build_hints:
			len_hint_replacements = 0
			had_replace_table = bool(glyph.replace_table)
			if vertical_hints_only:
				glyph.hlinks.clean()
				glyph.hhints.clean()
			if glyph.vlinks or glyph.hlinks:
				convert_links_to_hints(glyph)
			len_vhints = len(glyph.vhints)
			len_hhints = len(glyph.hhints)
			if len_vhints:
				ufo_lib.vhints[i] = glif_hints(glyph.vhints, 1)
				vhints = &ufo_lib.vhints[i]
			if len_hhints:
				ufo_lib.hhints[i] = glif_hints(glyph.hhints)
				hhints = &ufo_lib.hhints[i]
			if had_replace_table:
				rebuild_replace_table(glyph)
				len_hint_replacements = len(glyph.replace_table)
				ufo_lib.hint_replacements[i] = glif_hint_replacements(glyph.replace_table)
				hint_replacements = &ufo_lib.hint_replacements[i]
			ufo_lib.contours[i] = glif_contours_hints(glyph.nodes, glyph.replace_table)
			contours = &ufo_lib.contours[i]

		ufo_lib.glifs.emplace_back(
			name,
			glif_path,
			code_points,
			anchors,
			components,
			contours,
			vhints,
			hhints,
			hint_replacements,
			mark,
			width,
			i,
			len_code_points,
			len_anchors,
			len_components,
			len_points,
			len_vhints,
			len_hhints,
			len_hint_replacements,
			omit,
			base,
			)

	if ufo_scale:
		for glif in ufo_lib.glifs:
			glif.scale(ufo_scale)

	if ufoz:
		ufo.archive = c_archive(instance_ufoz_path, ufoz_compress)
		ufo.archive.reserve(ufo_lib.glifs.size() + 7)
		for glif in ufo_lib.glifs:
			ufo.archive[glif.path] = glif.build(ufo_lib, optimize, 1)
	else:
		write_glifs(ufo_lib, optimize)

def convert_links_to_hints(glyph):
	fl.TransformGlyph(glyph, 10, b'')

def rebuild_replace_table(glyph):
	fl.TransformGlyph(glyph, 8, b'')

cdef cpp_code_points glif_code_points(glyph_code_points):

	cdef cpp_code_points code_points

	code_points.reserve(len(glyph_code_points))
	for code_point in glyph_code_points:
		code_points.push_back(code_point)
	return code_points

cdef cpp_hints glif_hints(glyph_hints, bint vertical=0):

	cdef:
		cpp_hints hints
		long position = 0, width = 0

	hints.reserve(len(glyph_hints))
	for hint in glyph_hints:
		position, width = hint.position, hint.width
		hints.emplace_back(position, width, vertical)
	return hints

cdef cpp_hint_replacements glif_hint_replacements(glyph_replace_table):

	cdef:
		cpp_hint_replacements hint_replacements
		int replacement_type = 0
		size_t replacement_index = 0

	hint_replacements.reserve(len(glyph_replace_table))
	for replacement in glyph_replace_table:
		replacement_type, replacement_index = replacement.type, replacement.index
		hint_replacements.emplace_back(replacement_type, replacement_index)
	return hint_replacements

cdef cpp_anchors glif_anchors(glyph_anchors):

	cdef:
		cpp_anchors anchors
		string name
		long x = 0, y = 0

	anchors.reserve(len(glyph_anchors))
	for anchor in glyph_anchors:
		name = anchor.name.decode('cp1252').encode('utf_8')
		x, y = anchor.x, anchor.y
		anchors.emplace_back(name, x, y)
	return anchors

cdef cpp_components glif_components(glyph_components, ufo):

	cdef:
		cpp_components components
		size_t i = 0
		long offset_x = 0, offset_y = 0
		long scale_x = 0, scale_y = 0
		string base

	components.reserve(len(glyph_components))
	for component in glyph_components:
		offset_x, offset_y = component.delta.x, component.delta.y
		scale_x, scale_y = component.scale.x, component.scale.y
		i = component.index
		base = ufo.glyph_names[i].encode('utf_8')
		components.emplace_back(base, i, offset_x, offset_y, scale_x, scale_y)
	return components

cdef cpp_contours glif_contours(glyph_nodes):

	cdef:
		cpp_contours contours
		cpp_contour contour
		bint off = 0
		bint cubic = 1
		size_t n_nodes = len(glyph_nodes)
		long x0 = 0, x1 = 0, x2 = 0
		long y0 = 0, y1 = 0, y2 = 0
		int alignment = 0

	contours.reserve(n_nodes // 2)
	contour.reserve(n_nodes)
	for node in glyph_nodes:

		if node.type == 17:
			start_node = node[0]
			if not contour.empty():
				contours.push_back(contour)
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
		elif node.type == 65:
			off = 1
			cubic = 0
			x0, y0 = node.x, node.y
			contour.emplace_back(x0, y0)
		elif cubic:
			x0, y0 = node.x, node.y
			alignment = node.alignment
			contour.emplace_back(x0, y0, 3, alignment)
		elif off:
			x0, y0 = node.x, node.y
			contour.emplace_back(x0, y0, 2)
			off = 0
		else:
			x0, y0 = node.x, node.y
			contour.emplace_back(x0, y0, 3)

	contours.push_back(contour)
	contours.shrink_to_fit()
	return contours

cdef cpp_contours glif_contours_hints(glyph_nodes, glyph_hint_replacements):

	cdef:
		cpp_contours contours
		cpp_contour contour
		cpp_contour_point point
		string name
		bint off = 0
		bint cubic = 1
		size_t n_nodes = len(glyph_nodes)
		long x0 = 0, x1 = 0, x2 = 0
		long y0 = 0, y1 = 0, y2 = 0
		int alignment = 0

	replacement_nodes = {0}
	if glyph_hint_replacements:
		for replacement in glyph_hint_replacements:
			if replacement.type == 255:
				replacement_nodes.add(replacement.index)

	contours.reserve(n_nodes // 2)
	contour.reserve(n_nodes)
	for i, node in enumerate(glyph_nodes):

		if node.type == 17:
			start_node = node[0]
			if not contour.empty():
				contours.push_back(contour)
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
				contour[0] = move(cpp_contour_point(x2, y2, 1, alignment, contour[0].name))
			else:
				if i in replacement_nodes:
					name = f'hintSet{i:04}'
					contour.emplace_back(x2, y2, 1, alignment, name)
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
				name = f'hintSet{i:04}'
				contour.emplace_back(x0, y0, 3, alignment, name)
			else:
				contour.emplace_back(x0, y0, 3, alignment)
		elif off:
			x0, y0 = node.x, node.y
			contour.emplace_back(x0, y0, 2)
			off = 0
		else:
			x0, y0 = node.x, node.y
			if i in replacement_nodes:
				name = f'hintSet{i:04}'
				contour.emplace_back(x0, y0, 3, name)
			else:
				contour.emplace_back(x0, y0, 3)

	contours.push_back(contour)
	contours.shrink_to_fit()
	return contours
