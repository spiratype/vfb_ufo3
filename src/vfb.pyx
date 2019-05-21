# coding: future_fstrings
# cython: wraparound=False, boundscheck=False
# cython: infer_types=True, cdivision=True
# cython: optimize.use_switch=True, optimize.unpack_method_calls=True
from __future__ import absolute_import, division, print_function, unicode_literals

from tools cimport fea_string

import os

from vfb2ufo.constants import *
from vfb2ufo.future import *

from FL import fl, NameRecord, TrueTypeTable

def kerning_scale(ufo, font):

	'''
	scale font kerning pair values
	'''

	for glyph in font.glyphs:
		if glyph.kerning:
			for kern in glyph.kerning:
				if kern.value:
					kern.value = int(kern.value * ufo.scale.factor)

	fl.UpdateFont(ufo.ifont)
	ufo.kern.kerning_scaled = 1


def kerning_unscale(ufo, font):

	'''
	un-scale font kerning pair values
	'''

	for glyph in font.glyphs:
		if glyph.kerning:
			for kern in glyph.kerning:
				if kern.value:
					kern.value = kern.value // ufo.scale.factor

	fl.UpdateFont(ufo.ifont)
	ufo.kern.kerning_scaled = 0


cdef _update_font_names(object font):

	'''
	update font names
	'''

	# Font full name
	font.full_name = bytes(f'{font.family_name} {font.style_name}')

	# PS font name
	font.font_name = bytes(f'{font.family_name}-{font.style_name}'.replace(' ', ''))[:31]

	# Menu
	font.menu_name = font.family_name

	# FOND name
	font.apple_name = font.full_name

	# OpenType family name
	font.pref_family_name = font.family_name

	# OpenType style name
	font.pref_style_name = font.style_name

	# OpenType Mac name
	font.mac_compatible = font.apple_name

	# TrueType Unique ID
	if font.source:
		font.tt_u_id = bytes(f'{font.source}: {font.full_name}: {font.year}')
	else:
		font.tt_u_id = bytes(f'{font.full_name}: {font.year}')

	# Font style name
	if font.font_style in (1, 33):
		font.style_name = bytes(f'{font.weight} Italic')
	else:
		font.style_name = font.weight


cdef list _ms_mac_names(object font, int platform):

	'''
	build ms and mac names for name records
	'''

	cdef:
		unicode version = f'Version {font.version_major}.{font.version_minor:03}'
		list names

	if not font.pref_family_name:
		font.pref_family_name = font.family_name

	if not font.pref_style_name:
		font.pref_style_name = font.style_name

	font.tt_version = bytes(version)

	names = [
		font.copyright, # 0
		font.family_name, # 1
		font.style_name, # 2
		font.tt_u_id, # 3
		font.full_name, # 4
		font.tt_version, # 5
		font.font_name, # 6
		font.trademark, # 7
		font.source, # 8
		font.designer, # 9
		font.notice, # 10
		font.vendor_url, # 11
		font.designer_url, # 12
		font.license, # 13
		font.license_url, # 14
		b'', # 15
		font.pref_family_name, # 16
		font.pref_style_name, # 17
		]

	# mac_name # 18
	# sample_text # 19
	# postscript cid name # 20

	if platform == 1:
		names.append(font.mac_compatible)
	elif platform == 3:
		names[4] = font.font_name

	names = [(i, name.decode('cp1252')) for i, name in enumerate(names)
		if name and isinstance(name, bytes)]

	return names


cdef _update_font_name_records(object font):

	'''
	update font name records
	'''

	cdef:
		list feature_value, ms_names, mac_names
		Py_ssize_t i

	ms_names = _ms_mac_names(font, 3)
	mac_names = _ms_mac_names(font, 1)

	fontnames = [NameRecord(name_id, 3, 1, 1033, bytes(fea_string(name, 3)))
		for name_id, name in ms_names if name]

	fontnames.extend([NameRecord(name_id, 1, 1, 0, bytes(fea_string(name, 1)))
		for name_id, name in mac_names if name])

	for name_record in fontnames:
		font.fontnames.append(name_record)


cdef _update_font_tables(object font, object ufo):

	'''
	update font tables
	'''

	cdef:
		double scale = ufo.scale.factor
		list os2_table, hhea_table, head_table, name_table, codepages
		int i

	os2_table = [
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
		('Panose', ' '.join([str(i) for i in font.panose])),
		('Vendor', f'"{font.vendor[:4]}"'),
		]

	codepages = [str(CODEPAGES[i]) for i in font.codepages if i in CODEPAGES]
	if codepages:
		os2_table.append(('CodePageRange',  ' '.join(codepages)))

	unicode_ranges = [str(i) for i in font.unicoderanges]
	if unicode_ranges:
		os2_table.append(('UnicodeRange', ' '.join(unicode_ranges)))

	hhea_table = [
		('CaretOffset', ufo.ttinfo.hhea_caret_offset),
		('Ascender', font.ttinfo.hhea_ascender),
		('Descender', font.ttinfo.hhea_descender),
		('LineGap', font.ttinfo.hhea_line_gap),
		]

	head_table = [
		f'FontRevision {font.version};',
		]

	name_table = []
	for name_record in font.fontnames:
		if name_record.nid in range(7, 255) or name_record.nid == 0:
			name = fea_string(name_record.name.decode('cp1252'), name_record.pid)
			if name_record.pid == 3:
				name_table.append(f'nameid {name_record.nid} 3 1 1033 "{name}";')
			else:
				name_table.append(f'nameid {name_record.nid} 1 "{name}";')

	scalable_keys = (
		'TypoAscender',
		'TypoDescender',
		'TypoLineGap',
		'winAscent',
		'winDescent',
		'XHeight',
		'CapHeight',
		'CaretOffset',
		'Ascender',
		'Descender',
		'LineGap',
		)

	if scale:
		os2_table = [f'{key} {int(round(value * scale))};'
			if key in scalable_keys else f'{key} {value};'
			for key, value in os2_table]

		hhea_table = [f'{key} {int(round(value * scale))};'
			if key in scalable_keys else f'{key} {value};'
			for key, value in hhea_table]

	else:
		os2_table = [f'{key} {value};' for key, value in os2_table]
		hhea_table = [f'{key} {value};' for key, value in hhea_table]

	font.truetypetables.append(TrueTypeTable(b'OS/2', bytes('\n'.join(os2_table))))
	font.truetypetables.append(TrueTypeTable(b'hhea', bytes('\n'.join(hhea_table))))
	font.truetypetables.append(TrueTypeTable(b'head', bytes('\n'.join(head_table))))
	font.truetypetables.append(TrueTypeTable(b'name', bytes('\n'.join(name_table))))


def update(ufo, font):
	_update_font_names(font)
	_update_font_name_records(font)
	_update_font_tables(font, ufo)
