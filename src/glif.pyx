# coding: utf-8
# cython: wraparound=False
# cython: boundscheck=False
# cython: infer_types=True
# cython: cdivision=True
# cython: auto_pickle=False
# cython: c_string_type=unicode, c_string_encoding=utf_8
# distutils: language=c++
# distutils: extra_compile_args=[-O3, -fopenmp, -fconcepts, -Wno-register, -fno-strict-aliasing, -std=c++17]
# distutils: extra_link_args=[-fopenmp, -lz]
from __future__ import division, unicode_literals
include 'includes/future.pxi'

cimport cython
cimport fenv

from libcpp cimport bool as bint
from libcpp.string cimport string
from libcpp.vector cimport vector
from libcpp.unordered_map cimport unordered_map

include 'includes/glif.pxi'
include 'includes/archive.pxi'

import time

from FL import fl

cdef double SCALE = 1.0

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

	if ufo.scale is not None:
		global SCALE
		SCALE = ufo.scale

	optimize = ufo.opts.glyphs_optimize
	decompose = ufo.opts.glyphs_decompose
	remove_overlaps = ufo.opts.glyphs_remove_overlaps
	code_points = ufo.code_points.optimize
	bases = ufo.glyph_sets.bases
	optimized_glyphs = ufo.glyph_sets.optimized
	omit_glyphs = ufo.glyph_sets.omit

	cdef:
		object font = fl[ufo.instance.ifont]
		size_t n = len(font.glyphs)
		cpp_glif glif
		cpp_glifs glifs
		cpp_contour contour
		cpp_contours contours
		cpp_anchor_lib anchor_lib
		cpp_component_lib component_lib
		cpp_contour_lib contour_lib
		cpp_completed_contour_lib completed_contour_lib
		vector[long] unicodes
		cpp_anchors anchors
		cpp_components components
		bytes instance_glifs_path = ufo.paths.instance.glyphs.encode('utf_8')
		bytes instance_ufoz_path = ufo.paths.instance.ufoz.encode('utf_8')
		bytes name = b''
		bytes path_sep = b'/' if ufo.opts.ufoz else b'\\'
		long code_point = 0
		int mark = 0
		bint omit = 0
		bint ufoz = ufo.opts.ufoz
		bint ufoz_compress = ufo.opts.ufoz_compress

	fenv.set_nearest()

	anchor_lib.reserve(n)
	component_lib.reserve(n)
	contour_lib.reserve(n)
	completed_contour_lib.reserve(n)
	glifs.reserve(n)
	unicodes.reserve(20)

	if optimize and remove_overlaps:
		for i, glyph in enumerate(font.glyphs):
			if i in bases:
				glyph.RemoveOverlap()
			if glyph.unicode not in code_points and i not in optimized_glyphs:
				if glyph.components:
					glyph.Decompose()
				if i not in bases:
					glyph.RemoveOverlap()

	elif decompose and remove_overlaps:
		for i, glyph in enumerate(font.glyphs):
			if glyph.components:
				glyph.Decompose()
			if i not in bases:
				glyph.RemoveOverlap()

	elif decompose:
		for glyph in font.glyphs:
			if glyph.components:
				glyph.Decompose()

	elif remove_overlaps:
		for i, glyph in enumerate(font.glyphs):
			if i not in bases:
				glyph.RemoveOverlap()

	for i, (name, glif_name, mark, glyph_code_points, omit) in items(ufo.glifs):
		unicodes.clear()
		for code_point in glyph_code_points:
			unicodes.push_back(code_point)
		glyph = font[i]
		add_glif(
			glifs,
			name,
			b'%s%s%s' % (instance_glifs_path, path_sep, glif_name),
			unicodes,
			mark,
			glyph.width * SCALE,
			i,
			len(glyph.Layer(0)),
			len(glyph.anchors),
			len(glyph.components),
			bool(glyph.components and optimize),
			omit,
			i in bases,
			)

		if glyph.anchors:
			anchor_lib[i] = glif_anchors(glyph.anchors)
		if glyph.components:
			component_lib[i] = glif_components(glyph.components, font)
		if glyph.nodes:
			contour_lib[i] = glif_contours(glyph.nodes)

	if ufoz:
		ufo.archive = c_archive(instance_ufoz_path, ufoz_compress)
		ufo.archive.reserve(glifs.size())
		for glif in glifs:
			ufo.archive[glif.path] = build_glif(glif, anchor_lib, component_lib, contour_lib, completed_contour_lib, 1)
	else:
		write_glif_files(glifs, anchor_lib, component_lib, contour_lib, completed_contour_lib)


cdef cpp_anchors glif_anchors(glyph_anchors):

	cdef cpp_anchors anchors

	anchors.reserve(len(glyph_anchors))
	for anchor in glyph_anchors:
		add_anchor(anchors, anchor.name.decode('cp1252'), anchor.x * SCALE, anchor.y * SCALE)
	return anchors

cdef cpp_components glif_components(glyph_components, font):

	cdef:
		cpp_components components
		size_t i = 0

	components.reserve(len(glyph_components))
	for component in glyph_components:
		offset_x, offset_y = component.delta.x * SCALE, component.delta.y * SCALE
		scale, i = component.scale, component.index
		base = font[i].name.decode('cp1252')
		add_component(components, base, i, offset_x, offset_y, scale.x, scale.y)
	return components

cdef cpp_contours glif_contours(glyph_nodes):

	cdef:
		cpp_contours contours
		cpp_contour contour
		bint off = 0
		bint cubic = 1
		size_t n = len(glyph_nodes)

	contours.reserve(n // 2)
	contour.reserve(n)
	for node in glyph_nodes:

		if node.type == 17:
			start_node = node[0]
			if not contour.empty():
				contours.push_back(contour)
				contour.clear()

		if node.count > 1:
			cubic = 1
			if start_node == node[0]:
				add_contour_point(contour, node.points[1].x * SCALE, node.points[1].y * SCALE, 4)
				add_contour_point(contour, node.points[2].x * SCALE, node.points[2].y * SCALE, 4)
				contour[0] = cpp_contour_point(node.x * SCALE, node.y * SCALE, 1, node.alignment)
			else:
				add_contour_point(contour, node.points[1].x * SCALE, node.points[1].y * SCALE, 4)
				add_contour_point(contour, node.points[2].x * SCALE, node.points[2].y * SCALE, 4)
				add_contour_point(contour, node.x * SCALE, node.y * SCALE, 1, node.alignment)
			continue

		if node.type == 65:
			off = 1
			cubic = 0
			add_contour_point(contour, node.x * SCALE, node.y * SCALE, 4)
			continue

		if cubic:
			add_contour_point(contour, node.x * SCALE, node.y * SCALE, 3)
			continue

		if off:
			add_contour_point(contour, node.x * SCALE, node.y * SCALE, 2, node.alignment)
			off = 0
		else:
			add_contour_point(contour, node.x * SCALE, node.y * SCALE, 3)

	contour.shrink_to_fit()
	contours.push_back(contour)
	contours.shrink_to_fit()
	return contours
