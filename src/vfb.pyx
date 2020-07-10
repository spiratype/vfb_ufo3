# coding: utf-8
# cython: wraparound=False
# cython: boundscheck=False
# cython: infer_types=True
# cython: cdivision=True
# cython: auto_pickle=False
# distutils: extra_compile_args=[-O3, -fno-strict-aliasing]
# distutils: extra_link_args=[-O3]
from __future__ import division, unicode_literals, print_function
include 'includes/future.pxi'
include 'includes/cp1252.pxi'

from collections import defaultdict
import os
import time

import FL
from FL import fl, Font, NameRecord, Rect

from . import fea, kern, user
from .fontinfo import fontinfo
from .user import print

include 'includes/thread.pxi'
include 'includes/io.pxi'
include 'includes/path.pxi'
include 'includes/defaults.pxi'
include 'includes/nameid.pxi'
include 'includes/glifname.pxi'
include 'includes/codepoints.pxi'
include 'includes/string.pxi'

def process_master_copy(ufo, master_copy):
	_process_master_copy(ufo, master_copy)

def add_instance(ufo, *instance):
	_add_instance(ufo, *instance)

def build_goadb(ufo, font):
	_build_goadb(ufo, font)

def font_names(ufo, font):
	_font_names(ufo, font)

def check_glyph_unicodes(font):
	_check_glyph_unicodes(font)

def _process_master_copy(ufo, master_copy):

	ufo.glifs = {}
	ufo.kern.firsts = set()
	ufo.kern.seconds = set()
	ufo.glyph_sets.bases = set()
	ufo.glyph_sets.omit = {-1}
	anchors = set()
	ufo.mark_classes = set()
	ufo.mark_bases = set()
	for i, glyph in enumerate(master_copy.glyphs):

		if glyph.kerning:
			ufo.kern.firsts.add(py_unicode(glyph.name))
			for kerning_pair in glyph.kerning:
				ufo.kern.seconds.add(py_unicode(master_copy[kerning_pair.key].name))

		if glyph.anchors:
			for anchor in glyph.anchors:
				if anchor.name:
					anchors.add(anchor.name)

		for component in glyph.components:
			ufo.glyph_sets.bases.add(component.index)

		if glyph.name in ufo.opts.glyphs_omit_names:
			ufo.glyph_sets.omit.add(i)

		if b'.' in glyph.name:
			for suffix in ufo.opts.glyphs_omit_suffixes:
				if glyph.name.endswith(suffix):
					ufo.glyph_sets.omit.add(i)
					break

	if anchors and ufo.opts.mark_feature_generate:
		if ufo.opts.mark_anchors_omit:
			anchors ^= ufo.opts.mark_anchors_omit
		elif ufo.opts.mark_anchors_include:
			anchors &= ufo.opts.mark_anchors_include
		for anchor in anchors:
			if anchor.startswith(b'_'):
				ufo.mark_classes.add(anchor[1:])
			else:
				ufo.mark_bases.add(anchor)
		ufo.mark_classes = {anchor for anchor in ufo.mark_classes
			if anchor in ufo.mark_bases}


	for i, glyph in enumerate(master_copy.glyphs):
		omit = i in ufo.glyph_sets.omit
		ufo.glifs[i] = Glif(glyph, ufo.opts.afdko_makeotf_release, omit)

	if not ufo.opts.glyphs_decompose:
		ufo.glyph_sets.omit = ufo.glyph_sets.omit - ufo.glyph_sets.bases

	if ufo.opts.glyphs_optimize or ufo.opts.glyphs_decompose:
		component_lib(ufo, master_copy)

	glyph_order(ufo, master_copy)


def master_instance(ufo, name, attributes, path):

	ufo.instance_times.total = time.clock()
	print('\nBuilding UFO ..\n')

	instance = fl[ufo.master_copy.ifont]
	ufo.instance.ifont = ufo.master_copy.ifont

	if ufo.master.ot_prefix or ufo.master.ot_features:
		fea.load_opentype(ufo, instance)

	user.load_encoding(ufo, instance)

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
			print('\nBuilding instance UFOs..\n')
		else:
			print('\nBuilding instance UFO..\n')
	if index + 1 == len(ufo.instance_values):
		ufo.last = 1

	if ufo.opts.ufoz:
		ufo.archive = {}

	ufo.instance_times.total = time.clock()
	master_copy = fl[ufo.master_copy.ifont]
	instance = Font(master_copy, value)
	fl.Add(instance)
	ufo.instance.ifont = fl.ifont
	fl.SetFontWindow(ufo.instance.ifont, Rect(0, 0, 0, 0), 1)
	fl.SetFontWindow(ufo.instance.ifont, Rect(0, 0, 0, 0), 1)

	instance = fl[ufo.instance.ifont]
	instance.modified = 0
	instance.full_name = py_bytes(f'{ufo.master.family_name} {name}')
	instance.family_name = py_bytes(ufo.master.family_name)

	ufo.instance.index = index

	if ufo.opts.vfb_save:
		if ufo.master.ot_prefix or ufo.master.ot_features:
			fea.load_opentype(ufo, instance)

	user.load_encoding(ufo, instance)

	fontinfo(ufo, instance, attributes)
	font_names(ufo, instance)

	kern.kerning(ufo, instance)

	if ufo.opts.afdko_parts:
		fea.tables(ufo, instance)

	build_instance_paths(ufo, attributes, path)


def build_instance_paths(ufo, attributes, path):

	ufo.paths.instance.ufoz = path.replace('.ufo', '.ufoz')
	bare_filename = os.path.basename(path).replace('.ufo', '')

	if not ufo.opts.vfb_close:
		ufo.paths.instance.vfb = unique_path(ufo.paths.instance.vfb, temp=1)
	else:
		ufo.paths.instance.vfb = path.replace('.ufo', '.vfb')
	if ufo.opts.vfb_save or not ufo.opts.vfb_close:
		ufo.paths.vfbs.append(file_str(ufo.paths.instance.vfb))

	if ufo.opts.ufoz:
		ufo.paths.instance.ufo = ufo_path = os.path.basename(path)
	else:
		ufo.paths.instance.ufo = ufo_path = path

	ufo.paths.instance.glyphs = glyphs = os.path.join(ufo_path, 'glyphs')
	ufo.paths.instance.features = os.path.join(ufo_path, 'features.fea')
	for plist, _ in UFO_PATHS_INSTANCE_PLISTS:
		if plist == 'glyphs_contents':
			ufo.paths.instance[plist] = os.path.join(glyphs, 'contents.plist')
		else:
			ufo.paths.instance[plist] = os.path.join(ufo_path, f'{plist}.plist')

	if not ufo.opts.ufoz:
		make_dir(glyphs)

	if ufo.opts.afdko_parts:
		exts = {
			'fontnamedb': '.FontMenuNameDB',
			'goadb': '.GlyphOrderAndAliasDB',
			'makeotf_cmd': '_makeotf.bat',
			}
		postscript_name = attributes.get('postscriptFontName', bare_filename)
		ufo.paths.instance.otf = os.path.join(ufo.paths.out, f'{postscript_name}.otf')
		for file, _ in UFO_PATHS_INSTANCE_AFDKO:
			path = os.path.join(ufo.paths.out, f'{bare_filename}{exts[file]}')
			ufo.paths.instance[file] = file_str(path)
		if os.path.isfile(ufo.paths.GOADB):
			ufo.paths.afdko.goadb = ufo.paths.GOADB

	if ufo.opts.psautohint_cmd:
		path = os.path.join(ufo.paths.out, f'{bare_filename}_psautohint.bat')
		ufo.paths.instance.psautohint_cmd = file_str(path)

	for key, path in items(ufo.paths.instance):
		if path is not None:
			ufo.paths.instance[key] = file_str(path)


def _build_goadb(ufo, font):

	if os.path.isfile(ufo.paths.GOADB):
		ufo.afdko.GOADB = [line.split()
			for line in user.read_file(ufo.paths.GOADB).splitlines()]
	else:
		goadb_from_encoding(ufo, font)


def goadb_from_encoding(ufo, font):

	def font_glyph_code_point(glyph_name):
		glyph = font[font.FindGlyph(glyph_name)]
		if glyph.unicode:
			return [py_unicode(glyph_name), uni_name(glyph.unicode)]
		return [py_unicode(glyph_name), None]

	first_256 = []
	first_256_names = []

	if ufo.opts.afdko_makeotf_GOADB_win1252:
		first_256 = WIN_1252
	elif ufo.opts.afdko_makeotf_GOADB_macos_roman:
		first_256 = MACOS_ROMAN

	if first_256:
		first_256_names = [py_unicode(font[font.FindGlyph(code_point)].name)
			for code_point in first_256 if font.has_key(code_point)]
	elif font.has_key(b'.notdef'):
		first_256_names = ['.notdef']
	goadb_names = [glyph for glyph in ufo.glyph_order
		if glyph not in set(first_256_names)]

	ufo.afdko.GOADB = [[glyph_name, None] for glyph_name in first_256_names]
	ufo.afdko.GOADB += [font_glyph_code_point(glyph) for glyph in goadb_names]


def glyph_order(ufo, font):

	encoding = user.read_file(ufo.paths.encoding).encode('cp1252').splitlines()

	encoding = [line.split()[0] for line in encoding[1:] if line]
	ufo.glyph_order = [glyph for glyph in encoding
		if font.has_key(glyph) and font.FindGlyph(glyph) not in ufo.glyph_sets.omit]


def _font_names(ufo, font):

	# Font full name
	font.full_name = py_bytes(f'{font.family_name} {font.style_name}')
	# PS font name
	font.font_name = py_bytes(f'{font.family_name}-{font.style_name).replace(" ", "")[:31]}')
	# Menu name
	font.menu_name = font.family_name
	# FOND name
	font.apple_name = font.full_name
	# TrueType Unique ID
	if font.source:
		font.tt_u_id = py_bytes(f'{font.source}: {font.full_name}: {font.year}')
	else:
		font.tt_u_id = py_bytes(f'{font.full_name}: {font.year}')
	# Font style name
	if font.font_style in {1, 33}:
		font.style_name = py_bytes(f'{font.weight} Italic')
	else:
		font.style_name = font.weight
	# OpenType family name
	font.pref_family_name = font.family_name
	# OpenType Mac name
	font.mac_compatible = font.apple_name
	# OpenType style name
	font.pref_style_name = font.style_name

	if ufo.opts.vfb_save:
		name_records(ufo, font)


def name_records(ufo, font):

	name_records = {platform_id: ms_mac_names(ufo, font, platform_id)
		for platform_id in {1, 3}}

	name_records = [
		NameRecord(nid, pid, ENC_IDS[pid], LANG_IDS[pid], py_bytes(name))
		for pid, names in sorted(items(name_records))
		for nid, name in names]

	font.fontnames.clean()
	for name_record in name_records:
		font.fontnames.append(name_record)


def ms_mac_names(ufo, font, platform_id):

	if not font.pref_family_name:
		font.pref_family_name = font.family_name

	if not font.pref_style_name:
		font.pref_style_name = font.style_name

	font.tt_version = py_bytes(f'Version {ufo.master.version}')

	names = (
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
		'', # 15
		font.pref_family_name, # 16
		font.pref_style_name, # 17
		)

	# mac_name # 18
	# sample_text # 19
	# postscript cid name # 20

	if platform_id == 1:
		names.append(font.mac_compatible)
	elif platform_id == 3:
		names[4] = font.font_name

	return [(nid, nameid_str(py_unicode(name), platform_id, 1))
		for nid, name in enumerate(names) if name]


def _check_glyph_unicodes(font):

	code_points = set()
	unicode_errors = defaultdict(list)
	for glyph in font.glyphs:
		for code_point in glyph.unicodes:
			if code_point not in code_points:
				code_points.add(code_point)
			else:
				glyph_name = py_unicode(glyph.name)
				unicode_errors[code_point].append(glyph_name)

	message = []
	if unicode_errors:
		for code_point, glyph_names in sorted(items(unicode_errors)):
			message.append(
				f"'{hex_code_point(code_point)}' is mapped to more than one glyph:"
				)
			for glyph_name in glyph_names:
				message.append(f'  {glyph_name}')

		raise GlyphUnicodeError('\n'.join(message))


def component_lib(ufo, font):

	'''
	build component library

	check font for glyphs with Unicode code points in the code point set
	if the glyph is in the set, check for components and build contours
	for each component
	'''

	# add all components to optimized glyph set if not removing overlaps
	if ufo.opts.glyphs_decompose and not ufo.opts.glyphs_remove_overlaps:
		ufo.glyph_sets.optimized = {i for i, glyph in enumerate(font.glyphs)
			if glyph.components}
		return

	names = []
	ufo.glyph_sets.optimized = set()
	# check glyphs in codepoint glyph set and user glyph name set
	for i, glyph in enumerate(font.glyphs):
		optimize = (
			glyph.unicode and
			glyph.unicode in ufo.code_points.optimize and
			glyph.components
			)
		if optimize:
			ufo.glyph_sets.optimized.add(i)
			names.append(py_unicode(glyph.name))
			continue
		if glyph.name in ufo.opts.glyphs_optimize_names:
			glyph_index = font.FindGlyph(glyph.name)
			if glyph_index > -1:
				glyph = font[glyph_index]
				ufo.glyph_sets.optimized.add(glyph_index)
				names.append(py_unicode(glyph.name))

	# check for small cap variants of glyphs found in codepoint glyph set
	for name in names:
		if not name.endswith(('.sc', '.smcp', '.c2sc')):
			for sc_name in [f'{name}.sc', f'{name}.smcp', f'{name}.c2sc']:
				glyph_index = font.FindGlyph(py_bytes(sc_name))
				if glyph_index > -1:
					glyph = font[glyph_index]
					if glyph.components:
						ufo.glyph_sets.optimized.add(glyph_index)


def Glif(glyph, release, omit):
	glyph_name = glyph.name
	glif_name = GLIFNAMES.get(glyph_name)
	if glif_name is None:
		glif_name = glifname(glyph_name, release, omit)
	return cp1252_utf8_bytes(glyph_name), glif_name, glyph.mark, list(glyph.unicodes), omit
