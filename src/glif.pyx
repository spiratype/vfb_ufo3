# coding: future_fstrings
# cython: wraparound=False, boundscheck=False
# cython: infer_types=True, cdivision=True
# cython: optimize.use_switch=True, optimize.unpack_method_calls=True
from __future__ import absolute_import, division, print_function, unicode_literals

from tools cimport hsv_srgb, int_float, uni_transform, element

import concurrent.futures
import hashlib
import time

from FL import fl

from vfb2ufo import tools
from vfb2ufo.constants import *
from vfb2ufo.future import *

'''
benchmarks
cython:
write 3000 text plain text files writing an integer as a string ~.6 sec
threading:
	write UFO with 3200 glif files ~3 sec (no glyph operations)
	write 2900 glif files ~10 sec (glyph decomposition and remove overlaps)
non-threading:
	write UFO with 3200 glif files ~13 sec (no glyph operations)
	write 2900 glif files ~18 sec (glyph decomposition and remove overlaps)
'''

cdef unicode glif_advance(width):

	'''
	glif advance element
	'''

	return element('advance', attrs=f'width="{width}"', text=None, elems=None)


cdef unicode glif_unicode(unicode _unicode):

	'''
	glif unicode element
	'''

	return element('unicode', attrs=f'hex="{_unicode}"', text=None, elems=None)


cdef glif_anchor(object anchor, double scale, int glif_version):

	'''
	glif anchor element
	'''

	if scale:
		x, y = anchor.x * scale, anchor.y * scale
	else:
		x, y = anchor.x, anchor.y

	if glif_version == 2:
		attributes = f'name="{anchor.name}" x="{int_float(x)}" y="{int_float(y)}"'
		return element('anchor', attrs=attributes, text=None, elems=None)

	elif glif_version == 1:
		attributes = (f'name="{anchor.name}" x="{int_float(x)}" y="{int_float(y)}"'
			' type="move"')
		sub_elements = [element('point', attrs=attributes, text=None, elems=None)]
		return glif_contour(sub_elements)


cdef unicode glif_component(object component, double scale, object font):

	'''
	glif component element
	'''

	if scale:
		xOffset, yOffset = component.delta.x * scale, component.delta.y * scale
	else:
		xOffset, yOffset = component.delta.x, component.delta.y

	attributes = (f'base="{font[component.index].name}" '
		f'xOffset="{int_float(xOffset)}" '
		f'yOffset="{int_float(yOffset)}" '
		f'xScale="{component.scale.x}" yScale="{component.scale.y}"')

	return element('component', attrs=attributes, text=None, elems=None)


cdef unicode glif_point(object point, bint off=0, unicode node_type='', bint smooth=0, unicode name=''):

	'''
	glif point element
	'''

	cdef:
		unicode attributes

	if off:
		attributes = f'x="{int_float(point.x)}" y="{int_float(point.y)}"'
		return element('point', attrs=attributes, text=None, elems=None)

	if smooth and name:
		attributes = (f'x="{int_float(point.x)}" y="{int_float(point.y)}"'
			f' type="{node_type}" smooth="yes" name="{name}"')
	elif name:
		attributes = (f'x="{int_float(point.x)}" y="{int_float(point.y)}"'
			f' type="{node_type}" name="{name}"')
	elif smooth:
		attributes = (f'x="{int_float(point.x)}" y="{int_float(point.y)}"'
			f' type="{node_type}" smooth="yes"')
	else:
		attributes = (f'x="{int_float(point.x)}" y="{int_float(point.y)}"'
			f' type="{node_type}"')

	return element('point', attrs=attributes, text=None, elems=None)


cdef list glif_contour(list points):

	'''
	glif contour element
	'''

	return element('contour', attrs=None, text=None, elems=points)


cdef list glif_outline(list outline):

	'''
	glif outline element
	'''

	return element('outline', attrs=None, text=None, elems=outline)


cdef list glif_mark(int fl_color, int glif_version):

	'''
	lib mark element
	'''

	cdef:
		unicode key

	r, g, b, a = hsv_srgb(fl_color)
	if glif_version == 2:
		key = 'public.markColor'
		mark_element = [element('key', attrs=None, text=key, elems=None),
			element('string', attrs=None, text=f'{r},{g},{b},{a}', elems=None)]
		return mark_element

	else:
		key = 'com.typemytype.robofont.mark'
		sub_elements = [element('integer', attrs=None, text=str(i), elems=None)
			if isinstance(i, int) else element('real', attrs=None, text=str(i), elems=None)
			for i in [r, g, b, a]]
		mark_element = element('key', attrs=None, text=key, elems=None)

		return [mark_element] + element('array', attrs=None, text=None, elems=sub_elements)


cdef unicode glif_hint_stem(pos, width, double scale, bint vertical, bint horizontal):

	'''
	glif hint stem element
	'''

	cdef:
		unicode hint_orientation

	if scale:
		if width in (-21, 20):
			pos = int(round(pos * scale)) - width + int(round(width * scale))
		else:
			pos, width = int(round(pos * scale)), int(round(width * scale))

	if vertical:
		return element('string', attrs=None, text=f'vstem {pos} {width}', elems=None)
	if horizontal:
		return element('string', attrs=None, text=f'hstem {pos} {width}', elems=None)


cdef list glif_hintset(int tag, list stems):

	'''
	glif hintset element
	'''

	cdef:
		list hintset

	hintset = [
		element('key', attrs=None, text='pointTag', elems=None),
		element('string', attrs=None, text=f'hintSet{tag:04}', elems=None),
		element('key', attrs=None, text='stems', elems=None),
		] + element('array', attrs=None, text=None, elems=stems)

	return element('dict', attrs=None, text=None, elems=hintset)


cdef list glif_hints(list hints, list hintset_hash, bint afdko):

	'''
	glif hints element
	'''

	cdef:
		unicode hints_id = ''.join(hintset_hash)
		unicode key

	if afdko:
		hints_id = ''.join(hints_id.split()).replace(',', '')

	if len(hints_id) > 128:
		hints_id = str(hashlib.sha512(hints_id).hexdigest())

	hints = element('array', attrs=None, text=None, elems=hints)

	if afdko:
		key = 'com.adobe.type.autohint.v2'
		hints = [
			element('key', attrs=None, text='id', elems=None),
			element('string', attrs=None, text=hints_id, elems=None),
			element('key', attrs=None, text='hintSetList', elems=None)
			] + hints
		hints = [
			element('key', attrs=None, text=key, elems=None)
			] + element('dict', attrs=None, text=None, elems=hints)
	else:
		key = 'public.postscript.hints'
		hints = [
			element('key', attrs=None, text='formatVersion', elems=None),
			element('string', attrs=None, text='1', elems=None),
			element('key', attrs=None, text='id', elems=None),
			element('string', attrs=None, text=hints_id, elems=None),
			element('key', attrs=None, text='hintSetList', elems=None)
			] + hints
		hints = [
			element('key', attrs=None, text=key, elems=None),
			] + element('dict', attrs=None, text=None, elems=hints)

	return hints


cdef list glif_lib(list lib_objects):

	'''
	glif lib element
	'''

	cdef:
		list sub_elements

	sub_elements = element('dict', attrs=None, text=None, elems=lib_objects)

	return element('lib', attrs=None, text=None, elems=sub_elements)


cdef unicode glif_glyph(list glif, unicode name, int glif_version):

	'''
	glif element
	'''

	cdef:
		unicode attributes = f'name="{name}" format="{glif_version}"'

	return '\n'.join(element('glyph', attrs=attributes, text=None, elems=glif))


cdef list _starts(object glyph):

	'''
	build contour node start list
	'''

	cdef:
		Py_ssize_t i
		list starts = [0] * glyph.nodes_number

	start_indices = [glyph.GetContourBegin(i)
		for i in range(glyph.GetContoursNumber())]

	for i in start_indices:
		starts[i] = 1

	return starts


cdef tuple glif_contours(
	object glyph,
	object ufo,
	double scale,
	bint build_hints,
	dict hintsets,):

	'''
	build glif contours
	'''

	cdef:
		Py_ssize_t i
		Py_ssize_t j = 0
		list contours = []
		list contour = []
		list hintset_hashes = []
		list hintset_hash = []
		list starts = _starts(glyph)
		int skips = 0
		bint off = 0
		bint start
		bint smooth
		bint cubic
		object node

	for i, (node, start) in enumerate(zip(glyph.nodes, starts)):
		smooth, name = 0, None
		if i in hintsets:
			name = f'hintSet{i:04}'
		if node.alignment:
			smooth = 1

		if start:
			start_node = node[0]
			start_node_name = name
			cubic = 1
			if contour:
				contours.extend(glif_contour(contour))
				hintset_hashes.extend(hintset_hash)
				contour, j, hintset_hash = [], 0, []

		if scale:
			points = [point * scale for point in node.points]
		else:
			points = [point for point in node.points]

		if node.count > 1:
			cubic = 1
			contour.extend([
				glif_point(points[1], 1, None, 0),
				glif_point(points[2], 1, None, 0)
				])
			if build_hints:
				hintset_hash.extend([
					f' {int_float(points[1].x)},{int_float(points[1].y)}'
					f' {int_float(points[2].x)},{int_float(points[2].y)}'
					])
			if start_node == glyph.nodes[i][0]:
				contour[0] = glif_point(points[0], 0, 'curve', smooth, start_node_name)
				if build_hints:
					hintset_hash[0] = f'c{int_float(points[0].x)},{int_float(points[0].y)}'
					if i in hintsets:
						k = i - 1 - skips
						hintsets[k] = hintsets[i]
						del hintsets[i]
						contour[j-1] = contour[j-1].replace('/>', f' name="hintSet{k:04}"/>')
						skips += 1
			else:
				contour.append(glif_point(points[0], 0, 'curve', smooth, name))
				if build_hints:
					hintset_hash.append(f'c{int_float(points[0].x)},{int_float(points[0].y)}')
					j += 3
		else:
			if cubic:
				contour.append(glif_point(points[0], 0, 'line', smooth, name))
				if build_hints:
					hintset_hash.append(f'l{int_float(points[0].x)},{int_float(points[0].y)}')
					prev_i = i
					j += 1
			else:
				if node.type == 65:
					off = 1
					cubic = 0
					contour.append(glif_point(points[0], 1, None, 0))
				else:
					if off:
						off = 0
						contour.append(glif_point(points[0], 0, 'qcurve', 0))
					else:
						contour.append(glif_point(points[0], 0, 'line', 0))

	if build_hints:
		if scale:
			# UFO spec is int/float, psautohint v1.7.0 requires int
			hintset_hash = [f'w{int(round(glyph.width * scale))}'] + hintset_hashes + hintset_hash
		else:
			hintset_hash = [f'w{glyph.width}'] + hintset_hashes + hintset_hash

	return contours + glif_contour(contour), hintset_hash, hintsets


cdef build_glif(object glyph, object ufo, object font):

	'''
	build glif file
	'''

	cdef:
		double scale = ufo.scale.factor
		unicode glyph_name = str(glyph.name)
		unicode glif_path
		int glif_version = ufo.glif_version
		bint build_hints = ufo.hints.build
		list unicodes = []
		list outline = []
		list anchors = []
		list components = []
		list vhints = []
		list hhints = []
		list hints = []
		dict hintsets = {}
		list hintset_hash = []
		list contours = []
		list contour = []
		list lib = []
		list mark = []
		list glyph_nodes

	# advance width
	if scale:
		# UFO spec is int/float, psautohint v1.7.0 requires int
		width = int(glyph.width * scale)
	else:
		width = glyph.width

	advance = [glif_advance(width)]

	# unicodes
	if glyph.unicodes:
		unicodes = [glif_unicode(uni_transform(glyph_unicode))
			for glyph_unicode in glyph.unicodes if glyph_unicode]

	# anchors
	if glyph.anchors:
		anchors = [glif_anchor(glyph_anchor, scale, glif_version)
			for glyph_anchor in glyph.anchors]

	# components
	if glyph.components:
		components = [glif_component(glyph_component, scale, font)
			for glyph_component in glyph.components]

	# hints
	if glyph.hhints or glyph.vhints:
		if glyph.hhints:
			for hint in glyph.hhints:
				if hint.width < 0:
					if hint.width != -21:
						hint.position, hint.width =	hint.position + hint.width, -hint.width
				hhints.append(glif_hint_stem(hint.position, hint.width, scale, 0, 1))

		if glyph.vhints:
			for hint in glyph.vhints:
				if hint.width < 0:
					hint.position, hint.width =	hint.position + hint.width, -hint.width
				vhints.append(glif_hint_stem(hint.position, hint.width, scale, 1, 0))

		if glyph.replace_table:
			hintset = 0
			for replace in glyph.replace_table:
				if hintset not in hintsets:
					hintsets[hintset] = []
				if replace.type == 2:
					hintsets[hintset].append(vhints[replace.index])
				elif replace.type == 1:
					hintsets[hintset].append(hhints[replace.index])
				elif replace.type == 255:
					hintset = replace.index
		else:
			hintsets[0] = hhints + vhints

	# contours
	if glyph.nodes:
		contours, hintset_hash, hintsets = glif_contours(glyph, ufo, scale, build_hints, hintsets)

	if build_hints:
		if hintsets:
			for hintset_tag, stems in sorted(items(hintsets)):
				hints.extend(glif_hintset(hintset_tag, stems))

			hints = glif_hints(hints, hintset_hash, ufo.hints.afdko)

	if glif_version == 1:
		if anchors:
			for anchor in anchors:
				contours.extend(anchor)

	# outline
	outline = components + contours
	if outline:
		outline = glif_outline(outline)

	# glyph mark color
	if glyph.mark:
		mark = glif_mark(glyph.mark, glif_version)

	# compose glif lib
	if glyph.mark or hints:
		lib = glif_lib(mark + hints)

	# compose glif glyph
	if glif_version == 1:
		glif = advance + unicodes + outline + lib
	elif glif_version == 2:
		glif = advance + unicodes + anchors + outline + lib

	# build glif string
	glif = glif_glyph(glif, glyph_name, glif_version)

	if ufo.ufoz.ufoz:
		glif_path = f'glyphs\\{ufo.glifs[glyph_name]}'
		ufo.archive.update({glif_path: XML_DECLARATION + glif + '\n'})
	else:
		glif_path = f'{ufo.instance_paths.glyphs}\\{ufo.glifs[glyph_name]}'
		with open(glif_path, 'wb') as f:
			f.write(XML_DECLARATION + glif + '\n')


def glifs(ufo):

	'''
	prepare glyphs for conversion to glif file
	'''

	font = fl[ufo.ifont]

	# convert links/remove vertical hints/autoreplace
	if ufo.hints.ignore:
		for glyph in font.glyphs:
			glyph.RemoveHints(3)
	else:
		if ufo.hints.ignore_vertical:
			for glyph in font.glyphs:
				glyph.RemoveHints(2)
				if glyph.vlinks or glyph.hlinks:
					fl.TransformGlyph(glyph, 10, b'')
				if ufo.hints.autoreplace:
					fl.TransformGlyph(glyph, 8, b'')
				if glyph.replace_table:
					if ufo.hints.ignore_replacements:
						glyph.replace_table.clean()
		else:
			for glyph in font.glyphs:
				if glyph.vlinks or glyph.hlinks:
					fl.TransformGlyph(glyph, 10, b'')
				if ufo.hints.autoreplace:
					fl.TransformGlyph(glyph, 8, b'')
				if glyph.replace_table:
					if ufo.hints.ignore_replacements:
						glyph.replace_table.clean()

	# decompose/remove glyph overlaps
	if ufo.glyph.decompose and ufo.glyph.remove_overlaps:
		for glyph in font.glyphs:
			if glyph.components:
				glyph.Decompose()
			glyph.RemoveOverlap()
	elif ufo.glyph.decompose:
		for glyph in font.glyphs:
			if glyph.components:
				glyph.Decompose()
	elif ufo.glyph.remove_overlaps:
		for glyph in font.glyphs:
			glyph.RemoveOverlap()

	# prepare glyph generator
	glyphs = (glyph for glyph in font.glyphs
		if str(glyph.name) in ufo.glyphs)

	# build and write glif files
	with concurrent.futures.ThreadPoolExecutor() as executor:
		for glyph in glyphs:
			executor.submit(build_glif, glyph, ufo, font)

	# for glyph in glyphs:
	# 	build_glif(glyph, ufo)
