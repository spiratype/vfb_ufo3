# coding: utf-8
# cython: wraparound=False
# cython: boundscheck=False
# cython: infer_types=True
# cython: cdivision=True
# cython: auto_pickle=False
from __future__ import absolute_import, division, unicode_literals
include 'includes/future.pxi'
include 'includes/cp1252.pxi'

import time

import FL
from FL import fl

include 'includes/ignored.pxi'
include 'includes/thread.pxi'
include 'includes/io.pxi'
include 'includes/string.pxi'
include 'includes/glif.pxi'
include 'includes/xml.pxi'

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
		global UFO_SCALE
		UFO_SCALE = <double>ufo.scale

	font = fl[ufo.instance.ifont]
	optimize = ufo.opts.glyphs_optimize
	decompose = ufo.opts.glyphs_decompose
	remove_overlaps = ufo.opts.glyphs_remove_overlaps
	code_points = ufo.code_points.optimize
	bases = ufo.glyph_sets.bases
	optimized_glyphs = ufo.glyph_sets.optimized
	omit_glyphs = ufo.glyph_sets.omit

	base_contours = {}

	glifs = {i: Glif(*glif, i, ufo) for i, glif in items(ufo.glifs)}

	# build library of contours mapped to a base glyph
	if optimize:
		for base in bases:
			glyph = font[base]
			if remove_overlaps:
				glyph.RemoveOverlap()
			base_contours[base] = glif_base_contours(glyph.nodes)

		# decompose only glyphs which do not have contours built
		if remove_overlaps:
			for i, glyph in enumerate(font.glyphs):
				if glyph.unicode not in code_points and i not in optimized_glyphs:
					if glyph.components:
						glyph.Decompose()
					if i not in bases:
						glyph.RemoveOverlap()

	# decompose/remove glyph overlaps
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

	# fully build base glifs
	for base in bases:
		glyph = font[base]
		glif_glif(glifs, glyph, base, font, base_contours)

	# build non-base glyphs
	for i, glyph in enumerate(font.glyphs):
		if i not in bases:
			glif_glif(glifs, glyph, i, font, base_contours)

	for glif in values(glifs):
		if not glif.base and not glif.omit:
			glif_build(glif)

	while threading.active_count() != 1:
		time.sleep(.02)
	del glifs

def glif_glif(glifs, glyph, glyph_index, font, base_contours):

	glif = glifs[glyph_index]
	glif.width = glyph.width

	if glyph.anchors:
		glif.anchors = [Anchor(anchor.x, anchor.y, anchor.name)
			for anchor in glyph.anchors]

	if glyph.components:
		for component in glyph.components:
			offset, scale, index = component.delta, component.scale, component.index
			if index in base_contours:
				if offset == NO_OFFSET and scale == NO_SCALE:
					glif.component_contours += glifs[index].contours
					continue
				base_contour = base_contours[index]
				glif.contours += glif_component_contours(base_contour, offset, scale)
			else:
				glif.components.append(Component(offset, scale, font[index].name))

	if glyph.nodes:
		if glyph_index in base_contours:
			glif.contours = [[Point(*point) for point in contour]
				for contour in base_contours[glyph_index]]
		else:
			glif.contours = glif_contours(glyph.nodes)

	if glif.base:
		glif_build(glif)

def glif_build(glif):

	unicodes = []
	anchors = []
	components = []
	contours = []
	component_contours = []
	lib = []

	if glif.unicodes:
		unicodes = [glif_unicode(code_point) for code_point in glif.unicodes]

	if glif.anchors:
		anchors = [glif_anchor(anchor) for anchor in glif.anchors]

	if glif.components:
		components = [glif_component(component) for component in glif.components]

	if glif.component_contours:
		contours = glif.component_contours

	if glif.contours:
		if glif.base:
			for contour in glif.contours:
				contours += glif_contour(contour)
			glif.contours = contours[:]
		else:
			for contour in glif.contours:
				contours += glif_contour(contour)

	if glif.mark_color:
		lib = glif.lib

	outline = glif_outline(components + contours)

	elems = unicodes + anchors + outline + lib

	text = '\n'.join((
		f'{XML_PROLOG}\n<glyph name="{glif.name}" format="2">\n'
		f'\t<advance width="{glif.advance}"/>',
		*elems,
		'</glyph>\n'
		))

	glif.text = file_str(text)

	if glif.ufoz:
		glif.archive()
	else:
		glif.write()

def glif_contours(nodes):

	off, cubic = 0, 1
	contours, contour = [], []
	for i, node in enumerate(nodes):

		if node.type == 17:
			start_node = node[0]
			if contour:
				contours.append(contour)
				contour = []

		if node.count > 1:
			cubic = 1
			if start_node == node[0]:
				contour[0] = Point(node.x, node.y, 1, node.alignment)
				contour += [
					Point(node.points[1].x, node.points[1].y, 4, 0),
					Point(node.points[2].x, node.points[2].y, 4, 0),
					]
			else:
				contour += [
					Point(node.points[1].x, node.points[1].y, 4, 0),
					Point(node.points[2].x, node.points[2].y, 4, 0),
					Point(node.x, node.y, 1, node.alignment),
					]
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

			contour.append(Point(node.x, node.y, point_type, 0))

	contours.append(contour)
	return contours

def glif_base_contours(nodes):

	off, cubic = 0, 1
	contours, contour = [], []
	for i, node in enumerate(nodes):

		if node.type == 17:
			start_node = node[0]
			if contour:
				contours.append(contour)
				contour = []

		if node.count > 1:
			cubic = 1
			if start_node == node[0]:
				contour[0] = (node.x, node.y, 1, node.alignment)
				contour += [
					(node.points[1].x, node.points[1].y, 4, 0),
					(node.points[2].x, node.points[2].y, 4, 0),
					]
			else:
				contour += [
					(node.points[1].x, node.points[1].y, 4, 0),
					(node.points[2].x, node.points[2].y, 4, 0),
					(node.x, node.y, 1, node.alignment),
					]
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

			contour.append((node.x, node.y, point_type, 0))

	contours.append(contour)
	return contours

def glif_component_contours(contours, offset, scale):

	if offset == NO_OFFSET:
		return [[scaled_point(*point, scale) for point in contour]
			for contour in contours]

	if scale == NO_SCALE:
		return [[offset_point(*point, offset) for point in contour]
			for contour in contours]

	return [[offset_scaled_point(*point, offset, scale)
		for point in contour] for contour in contours]

def scaled_point(x, y, point_type, smooth, scale):
	return Point(x * scale.x, y * scale.y, point_type, smooth)

def offset_point(x, y, point_type, smooth, offset):
	return Point(x + offset.x, y + offset.y, point_type, smooth)

def offset_scaled_point(x, y, point_type, smooth, offset, scale):
	return Point((x + offset.x) * scale.x, (y + offset.y) * scale.y,
		point_type, smooth)
