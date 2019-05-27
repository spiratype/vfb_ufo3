# coding: future_fstrings
# cython: wraparound=False, boundscheck=False
# cython: infer_types=True, cdivision=True
# cython: optimize.use_switch=True, optimize.unpack_method_calls=True
from __future__ import absolute_import, division, print_function, unicode_literals
from vfb2ufo3.future import open, range, str, zip, items

from tools cimport element

import itertools
import operator
import os
import shutil
import time

from FL import fl

from vfb2ufo3 import fontinfo, tools, vfb
from vfb2ufo3.constants import XML_DECLARATION, PLIST_DOCTYPE

def plists(ufo):

	'''
	write plists
	'''

	start = time.clock()

	metainfo_plist(ufo)
	fontinfo_plist(ufo)
	groups_plist(ufo)
	kerning_plist(ufo)
	lib_plist(ufo)
	glyphs_contents_plist(ufo)
	if ufo.version == 3:
		layercontents_plist(ufo)

	ufo.instance_times.plist = time.clock() - start


def write_plist(ufo, plist, plist_path):

	plist = f'<plist version="1.0">\n{chr(10).join(plist)}\n</plist>'

	if ufo.ufoz.write:
		ufo.archive.update({plist_path: XML_DECLARATION + PLIST_DOCTYPE + plist})
	else:
		tools.write_file(plist_path, XML_DECLARATION + PLIST_DOCTYPE + plist)


cdef glyphs_contents_plist(object ufo):

	'''
	build glyphs directory contents plist
	'''

	cdef:
		list glyphs_contents_dict = []

	if ufo.instance_paths.plists_prev.glyphs_contents:
		shutil.copy(ufo.plist_prev.glyphs_contents, ufo.instance_paths.plists.glyphs_contents)

	else:
		for glyph_name in ufo.glyph_order:
			if glyph_name in ufo.glyphs:
				glyphs_contents_dict.extend([
					element('key', attrs=None, text=glyph_name, elems=None),
					element('string', attrs=None, text=ufo.glifs[glyph_name], elems=None),
					])

		if ufo.ufoz.write:
			plist_path = os.path.join('glyphs', 'contents.plist')
		else:
			plist_path = ufo.instance_paths.plists.glyphs_contents
			ufo.instance_paths.plists_prev.glyphs_contents = plist_path

		glyphs_contents_dict = element('dict', attrs=None, text=None, elems=glyphs_contents_dict)
		write_plist(ufo, glyphs_contents_dict, plist_path)


cdef layercontents_plist(object ufo):

	'''
	build layer contents plist
	'''

	if ufo.instance_paths.plists_prev.layercontents:
		shutil.copy(ufo.plist_prev.fontinfo, ufo.instance_paths.plists.layercontents)

	else:
		layercontents_array = [
			element('string', attrs=None, text='public.default', elems=None),
			element('string', attrs=None, text='glyphs', elems=None),
			]
		layercontents_array = element('array', attrs=None, text=None, elems=layercontents_array)

		if ufo.ufoz.write:
			plist_path = 'layercontents.plist'
		else:
			plist_path = ufo.instance_paths.plists.layercontents
			ufo.instance_paths.plists_prev.layercontents = plist_path

		layercontents_array = element('array', attrs=None, text=None, elems=layercontents_array)
		write_plist(ufo, layercontents_array, plist_path)


cdef fontinfo_plist(object ufo):

	'''
	build fontinfo plist
	'''

	info = fontinfo.fontinfo(ufo)
	fontinfo_dict = [lib.element
		for lib in sorted(info, key=operator.attrgetter('key'))
		if lib.element is not None]
	fontinfo_dict = list(itertools.chain.from_iterable(fontinfo_dict))

	if ufo.ufoz.write:
		plist_path = 'fontinfo.plist'
	else:
		plist_path = ufo.instance_paths.plists.fontinfo
		ufo.instance_paths.plists_prev.fontinfo = plist_path

	fontinfo_dict = element('dict', attrs=None, text=None, elems=fontinfo_dict)
	write_plist(ufo, fontinfo_dict, plist_path)


cdef groups_plist(object ufo):

	'''
	build groups plist
	'''

	cdef:
		list groups_dict = []
		unicode group_name, key_glyph, group_glyphs
		bytes font_class

	if ufo.instance_paths.plists_prev.groups:
		shutil.copy(ufo.plist_prev.groups, ufo.instance_paths.plists.groups)

	else:
		for group_name, group_glyphs in sorted(items(ufo.ot_groups)):
			sub_elements = [element('string', attrs=None, text=glyph, elems=None)
				for glyph in sorted(group_glyphs.replace("'", '').split())]
			groups_dict.append(element('key', attrs=None, text=group_name, elems=None))
			groups_dict.extend(element('array', attrs=None, text=None, elems=sub_elements))
		for group_name, group_glyphs in sorted(items(ufo.kern_groups)):
			sub_elements = [element('string', attrs=None, text=glyph, elems=None)
				for glyph in sorted(group_glyphs.replace("'", '').split())]
			groups_dict.append(element('key', attrs=None, text=group_name, elems=None))
			groups_dict.extend(element('array', attrs=None, text=None, elems=sub_elements))

		if ufo.ufoz.write:
			plist_path = 'groups.plist'
		else:
			plist_path = ufo.instance_paths.plists.groups
			ufo.instance_paths.plists_prev.groups = plist_path

		groups_dict = element('dict', attrs=None, text=None, elems=groups_dict)
		write_plist(ufo, groups_dict, plist_path)


cdef kerning_plist(object ufo):

	'''
	build kerning plist
	'''

	cdef:
		double scale = ufo.scale.factor
		object font = fl[ufo.ifont]
		dict kerning = {}
		list kerning_dict = []

	if ufo.scale.factor and not ufo.kern.kerning_scaled:
		vfb.kerning_scale(ufo, font)

	for glyph in font.glyphs:
		if glyph.kerning:
			kern_first = str(glyph.name)
			for kern in glyph.kerning:
				kern_second = str(font[kern.key].name)
				if kern_first not in kerning:
					kerning[kern_first] = []
				kerning[kern_first].append((kern_second, kern.value))

	for first, kerning_pairs in sorted(items(kerning)):
		if first in ufo.kern_firsts_by_key_glyph:
			first = ufo.kern_firsts_by_key_glyph[first]
		kerning_dict.append(
			element('key', attrs=None, text=first, elems=None)
			)
		kerns = []
		for second, value in sorted(kerning_pairs):
			if second in ufo.kern_seconds_by_key_glyph:
				second = ufo.kern_seconds_by_key_glyph[second]
			kerns.extend([
				element('key', attrs=None, text=second, elems=None),
				element('integer', attrs=None, text=str(value), elems=None),
				])
		kerning_dict.extend(element('dict', attrs=None, text=None, elems=kerns))

	if ufo.ufoz.write:
		plist_path = 'kerning.plist'
	else:
		plist_path = ufo.instance_paths.plists.kerning

	if ufo.vfb.save and ufo.kern.kerning_scaled:
		vfb.kerning_unscale(ufo, font)

	kerning_dict = element('dict', attrs=None, text=None, elems=kerning_dict)
	write_plist(ufo, kerning_dict, plist_path)


cdef lib_plist(object ufo):

	'''
	build glyph lib plist
	'''

	cdef:
		object font = fl[ufo.ifont]
		list sub_elements = [element('string', attrs=None, text=glyph, elems=None)
			for glyph in ufo.glyph_order
			if glyph in ufo.glyphs]
		list lib_dict

	if ufo.instance_paths.plists_prev.lib:
		shutil.copy(ufo.plist_prev.lib, ufo.instance_paths.plists.lib)

	else:
		lib_dict = [element('key', attrs=None, text='public.glyphOrder', elems=None)]
		lib_dict.extend(element('array', attrs=None, text=None, elems=sub_elements))
		lib_dict.extend([
			element('key', attrs=None, text='com.schriftgestaltung.disablesAutomaticAlignment', elems=None),
			element('true', attrs=None, text=None, elems=None),
			element('key', attrs=None, text='com.schriftgestaltung.disablesLastChange', elems=None),
			element('true', attrs=None, text=None, elems=None),
			element('key', attrs=None, text='com.schriftgestaltung.useNiceNames', elems=None),
			element('false', attrs=None, text=None, elems=None),
			])
		if ufo.ufoz.write:
			plist_path = 'lib.plist'
		else:
			plist_path = ufo.instance_paths.plists.lib
			ufo.instance_paths.plists_prev.lib = plist_path

		lib_dict = element('dict', attrs=None, text=None, elems=lib_dict)
		write_plist(ufo, lib_dict, plist_path)


cdef metainfo_plist(object ufo):

	'''
	build metainfo plist
	'''

	cdef:
		list metainfo_dict

	if ufo.instance_paths.plists_prev.metainfo:
		shutil.copy(ufo.plist_prev.metainfo, ufo.instance_paths.plists.metainfo)

	else:
		metainfo_dict = [
			element('key', attrs=None, text='creator', elems=None),
			element('string', attrs=None, text=ufo.creator, elems=None),
			element('key', attrs=None, text='formatVersion', elems=None),
			element('integer', attrs=None, text=str(ufo.version), elems=None),
			]

		if ufo.ufoz.write:
			plist_path = 'metainfo.plist'
		else:
			plist_path = ufo.instance_paths.plists.metainfo
			ufo.instance_paths.plists_prev.metainfo = plist_path

		metainfo_dict = element('dict', attrs=None, text=None, elems=metainfo_dict)
		write_plist(ufo, metainfo_dict, plist_path)
