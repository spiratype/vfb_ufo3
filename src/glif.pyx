# coding: utf-8
# cython: wraparound=False
# cython: boundscheck=False
# cython: infer_types=True
# cython: cdivision=True
# cython: auto_pickle=False
# distutils: language=c++
# distutils: extra_compile_args=[-fopenmp, -fconcepts, -O3, -Wno-register, -fno-strict-aliasing, -std=c++17]
# distutils: extra_link_args=[-fopenmp, -fconcepts, -O3, -Wno-register, -fno-strict-aliasing, -std=c++17]
from __future__ import absolute_import, division, unicode_literals
include 'includes/future.pxi'
include 'includes/cp1252.pxi'

import time

import FL
from FL import fl

include 'includes/ignored.pxi'
include 'includes/string.pxi'
include 'includes/glif.pxi'

def glifs(ufo):
	start = time.clock()
	_glifs(ufo)
	ufo.instance_times.glifs = time.clock() - start

def _glifs(ufo):

	'''
	build and write .glif file

	for glyph decomposition and overlap removal, UFO creation times can be
	reduced considerably by checking the font for glyphs normally consisting of
	components which do not overlap and build the contours for these components

	prior to building the contours for the selected components, the overlaps are
	removed

	the glyphs are selected based on Unicode code point and a user supplied glyph
	name list; the default list of these code points is located in 'ufo.pxi' as
	'OPTIMIZE_CODE_POINTS'

	during the build process, the components will remain in component-form
	and the cached contour will be substituted in its place in the outline
	element of the .glif file, and shifted and/or scaled (if necessary) to match
	the component being replaced
	'''

	if ufo.scale is not None:
		global SCALE
		SCALE = <double>ufo.scale

	font = fl[ufo.instance.ifont]
	optimize = ufo.opts.glyphs_optimize
	decompose = ufo.opts.glyphs_decompose
	remove_overlaps = ufo.opts.glyphs_remove_overlaps
	code_points = ufo.code_points.optimize
	bases = ufo.glyph_sets.bases
	optimized_glyphs = ufo.glyph_sets.optimized
	omit_glyphs = ufo.glyph_sets.omit

	cdef:
		cpp_glif glif
		cpp_glifs glifs
		cpp_anchors anchors
		cpp_components components
		cpp_contour contour
		cpp_contours contours
		cpp_anchor_lib anchor_lib
		cpp_component_lib component_lib
		cpp_contour_lib contour_lib
		vector[string] unicodes
		string path
		string text
		bytes name
		bytes code_point
		int mark
		bint omit
		size_t base
		size_t n = len(font.glyphs)

	anchor_lib.reserve(n)
	component_lib.reserve(n)
	contour_lib.reserve(n)
	glifs.reserve(n)

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


	for i, (name, glif_name, mark, code_points, omit) in sorted(items(ufo.glifs)):
		path.clear()
		unicodes.clear()
		unicodes.reserve(len(code_points))
		for code_point in code_points:
			unicodes.push_back(code_point)
		path = os.path.join(ufo.paths.instance.glyphs, glif_name).encode('utf_8')
		glyph = font[i]
		glif = cpp_glif(
			name,
			path,
			unicodes,
			mark,
			glyph.width * SCALE,
			i,
			omit,
			i in bases,
			bool(glyph.anchors),
			bool(glyph.components),
			bool(glyph.nodes),
			bool(glyph.components and optimize),
			)
		glifs.push_back(glif)

	for glif in glifs:
		glyph = font[glif.index]
		if glyph.anchors:
			anchor_lib[glif.index] = glif_anchors(glyph.anchors)
		if glyph.components:
			component_lib[glif.index] = glif_components(glyph.components, font)
		if glyph.nodes:
			contour_lib[glif.index] = glif_contours(glyph.nodes)

	if ufo.opts.ufoz:
		for glif in glifs:
			text = build_glif(glif, anchor_lib, component_lib, contour_lib, True)
			ufo.archive[glif.path] = text
	else:
		write_glif_files(glifs, anchor_lib, component_lib, contour_lib, False)


cdef cpp_anchors glif_anchors(object glyph_anchors):

	cdef:
		cpp_anchors anchors
		cpp_anchor anchor
		bytes name

	anchors.reserve(len(glyph_anchors))
	for glyph_anchor in glyph_anchors:
		name = cp1252_utf8_bytes(glyph_anchor.name)
		anchors.push_back(cpp_anchor(name, glyph_anchor.x * SCALE, glyph_anchor.y * SCALE))

	return anchors

cdef cpp_components glif_components(object glyph_components, object font):

	cdef:
		cpp_components components
		cpp_component component
		bytes name
		object offset, scale
		size_t i

	components.reserve(len(glyph_components))
	for glyph_component in glyph_components:
		offset, scale, i = glyph_component.delta, glyph_component.scale, glyph_component.index
		name = cp1252_utf8_bytes(font[i].name)
		components.push_back(cpp_component(name, i, offset.x * SCALE, offset.y * SCALE, scale.x, scale.y))

	return components

cdef cpp_contours glif_contours(object glyph_nodes):

	cdef:
		cpp_contours contours
		cpp_contour contour
		bint off = 0
		bint cubic = 1
		int point_type = 0
		size_t n = len(glyph_nodes)

	contour.reserve(n / 2)
	for i, node in enumerate(glyph_nodes):

		if node.type == 17:
			start_node = node[0]
			if not contour.empty():
				contour.shrink_to_fit()
				contours.push_back(contour)
				contour.clear()
				contour.reserve(n - i + 1)

		if node.count > 1:
			cubic = 1
			if start_node == node[0]:
				contour.push_back(cpp_contour_point(node.points[1].x * SCALE, node.points[1].y * SCALE, 4, 0))
				contour.push_back(cpp_contour_point(node.points[2].x * SCALE, node.points[2].y * SCALE, 4, 0))
				contour[0] = cpp_contour_point(node.x * SCALE, node.y * SCALE, 1, node.alignment)
			else:
				contour.push_back(cpp_contour_point(node.points[1].x * SCALE, node.points[1].y * SCALE, 4, 0))
				contour.push_back(cpp_contour_point(node.points[2].x * SCALE, node.points[2].y * SCALE, 4, 0))
				contour.push_back(cpp_contour_point(node.x * SCALE, node.y * SCALE, 1, node.alignment))
		else:
			if cubic:
				point_type = 3
			else:
				if node.type == 65:
					point_type = 4
					off = 1
					cubic = 0
				else:
					if off:
						point_type = 2
						off = 0
					else:
						point_type = 3

			contour.push_back(cpp_contour_point(node.x * SCALE, node.y * SCALE, point_type, 0))

	contour.shrink_to_fit()
	contours.push_back(contour)
	return contours
