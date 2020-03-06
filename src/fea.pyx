# coding: utf-8
# cython: wraparound=False
# cython: boundscheck=False
# cython: cdivision=True
# cython: auto_pickle=False
# distutils: extra_compile_args=[-fconcepts, -O3, -fno-strict-aliasing, -Wno-register]
# distutils: extra_link_args=[-fconcepts, -O3, -fno-strict-aliasing, -Wno-register]
from __future__ import absolute_import, division, unicode_literals
include 'includes/future.pxi'
include 'includes/cp1252.pxi'

import time

from FL import fl, Feature, TrueTypeTable

from . import kern, mark, user

include 'includes/string.pxi'
include 'includes/thread.pxi'
include 'includes/io.pxi'
include 'includes/objects.pxi'
include 'includes/fea.pxi'
include 'includes/opentype.pxi'

def copy_opentype(ufo, font):
	_copy_opentype(ufo, font)

def load_opentype(ufo, font, master=0):
	_load_opentype(ufo, font, master)

def tables(ufo, font):
	_tables(ufo, font)

def features(ufo):
	if ufo.master.ot_prefix or ufo.master.ot_features:
		start = time.clock()
		_features(ufo)
		ufo.instance_times.features = time.clock() - start

def _features(ufo):

	kern_file = ufo.opts.kern_feature_file_path

	groups = ''
	if ufo.opts.features_import_groups:
		if ufo.opts.kern_feature_passthrough:
			ufo_groups = ufo.groups.all
		else:
			ufo_groups = ufo.groups.opentype
		groups = [fea_group(*group) for group in sorted(items(ufo_groups))]
		groups = '# OpenType groups\n' + '\n'.join(groups)

	ot_features = []
	if ufo.master.ot_features:
		ot_features = list(ufo.master.ot_features.values())
	features = [groups, ufo.master.ot_prefix] + ot_features

	if ufo.opts.kern_feature_generate:
		if ufo.instance.kerning:
			features.append(kern.kern_feature(ufo))

	if ufo.opts.mark_feature_generate:
		features.append(mark.mark_feature(ufo))

	tables = []
	if ufo.opts.afdko_parts:
		tables = ufo.instance.tables.values()

	feature_file = features + tables

	if feature_file:
		feature_file = file_str('\n\n'.join(feature_file) + '\n')
		if ufo.opts.ufoz:
			ufo.archive[ufo.paths.instance.features] = feature_file
		else:
			write_file(ufo.paths.instance.features, feature_file)


def _copy_opentype(ufo, master):

	# copy opentype features
	if master.features:
		ufo.master.ot_features = features = ordered_dict()
		if ufo.opts.kern_feature_passthrough:
			for feature in master.features:
				features[py_unicode(feature.tag)] = py_unicode(feature.value).strip()
		else:
			for feature in master.features:
				if feature.tag != b'kern':
					features[py_unicode(feature.tag)] = py_unicode(feature.value).strip()

	# copy opentype prefix
	if master.ot_classes:
		ot_prefix = py_unicode(master.ot_classes).strip()
		if ot_prefix:
			ufo.master.ot_prefix = '\n'.join(ot_prefix.splitlines())


def _load_opentype(ufo, font, master=0):

	if master:
		if ufo.master.ot_prefix:
			font.ot_classes = py_bytes(ufo.master.ot_prefix)
		if ufo.master.ot_features:
			font.features.clean()
			for tag, value in items(ufo.master.ot_features):
				font.features.append(Feature(py_bytes(tag), py_bytes(value)))
		return

	master_copy = fl[ufo.master_copy.ifont]
	if master_copy.ot_classes:
		font.ot_classes = master_copy.ot_classes
	if master_copy.features:
		font.features.clean()
		for feature in master_copy.features:
			if feature.tag == b'kern':
				if ufo.opts.kern_omit_kern_feature:
					continue
			font.features.append(Feature(feature.tag, feature.value))


def _tables(ufo, font):

	tables = {}

	tables['OS/2'] = [
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
		('Panose', (' '.join([str(i) for i in font.panose])
			if any(font.panose) else None)),
		('Vendor', (f'"{font.vendor[:4]}"'
			if font.vendor or font.vendor.lower() != b'pyrs' else None)),
		]

	code_pages = [CODE_PAGES.get(code_page)
		for code_page in sorted(font.codepages)]
	code_pages = [str(code_page) for code_page in code_pages
		if code_page is not None]
	if code_pages:
		tables['OS/2'].append(('CodePageRange', ' '.join(code_pages)))

	unicode_ranges = [str(unicode_range)
		for unicode_range in sorted(font.unicoderanges)]
	if unicode_ranges:
		tables['OS/2'].append(('UnicodeRange', ' '.join(unicode_ranges)))

	attributes, instance = ufo.instance_attributes, ufo.instance.completed
	tables['hhea'] = (
		('CaretOffset', attributes[instance].get('openTypeHheaCaretOffset')),
		('Ascender', font.ttinfo.hhea_ascender),
		('Descender', font.ttinfo.hhea_descender),
		('LineGap', font.ttinfo.hhea_line_gap),
		)

	tables['head'] = (
		('FontRevision', ufo.master.version),
		)

	tables['name'] = []
	for name_record in ufo.instance.fontinfo['openTypeNameRecords']:
		nid = name_record['nameID']
		if nid not in OMIT_NIDS:
			pid = name_record['platformID']
			eid = name_record['encodingID']
			lid = name_record['languageID']
			string = name_record['string']
			ids = ' '.join([str(i) for i in [pid, eid, lid] if i])
			tables['name'].append((nid, ('nameid', f'{nid} {ids} "{string}"')))

	tables['name'] = [line for nid, line in sorted(tables['name'])]

	def scaled_table(table):
		return [(key, int(round(value * ufo.scale)))
			if key in SCALABLE_TABLE_KEYS and value else (key, value)
			for (key, value) in table]

	if ufo.scale:
		tables['OS/2'] = scaled_table(tables['OS/2'])
		tables['hhea'] = scaled_table(tables['hhea'])

	ufo.instance.tables = {tag: fea_table(tag, table)
		for tag, table in items(tables)}

	if ufo.opts.vfb_save:
		font.truetypetables.clean()
		for tag, table in items(ufo.instance.tables):
			font.truetypetables.append(TrueTypeTable(py_bytes(tag), py_bytes(table)))
