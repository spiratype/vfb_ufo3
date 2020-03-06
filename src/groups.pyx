# coding: utf-8
# cython: wraparound=False
# cython: boundscheck=False
# cython: cdivision=True
# cython: auto_pickle=False
# distutils: extra_compile_args=[-fconcepts, -O3, -fno-strict-aliasing, -Wno-register]
# distutils: extra_link_args=[-fconcepts, -O3, -fno-strict-aliasing, -Wno-register]
from __future__ import absolute_import, division, unicode_literals, print_function
include 'includes/future.pxi'
include 'includes/cp1252.pxi'

import os
import time

from FL import fl

from . import user
from .user import print

include 'includes/ignored.pxi'
include 'includes/string.pxi'
include 'includes/thread.pxi'
include 'includes/path.pxi'
include 'includes/io.pxi'
include 'includes/objects.pxi'
include 'includes/groups.pxi'
include 'includes/flc.pxi'
include 'includes/plist.pxi'

def groups(ufo):
	start = time.clock()
	_groups(ufo)
	ufo.total_times.groups = time.clock() - start

def _groups(ufo):

	ufo.groups.opentype = {}
	ufo.groups.kerning = {}
	ufo.kern.firsts_by_key_glyph = {}
	ufo.kern.seconds_by_key_glyph = {}
	ufo.kern.key_glyph_from_group = {}
	ufo.kern.glyphs_len = {}

	if ufo.opts.groups_flc_path is not None:
		import_flc(ufo)
	elif ufo.opts.groups_plist_path is not None:
		import_groups_plist(ufo)
	else:
		rename_groups(ufo)

	finish_groups(ufo)

	if ufo.opts.groups_export_flc:
		write_flc(ufo)

def finish_groups(ufo):

	if ufo.groups.opentype or ufo.groups.kerning:
		ufo.groups.all = ordered_dict()

	if ufo.groups.opentype:
		for name, glyphs in sorted(items(ufo.groups.opentype)):
			ufo.groups.all[name] = glyphs

	if ufo.groups.kerning:
		for name, (second, glyphs) in sorted(items(ufo.groups.kerning)):
			ufo.groups.all[name] = glyphs
			if second:
				ufo.kern.seconds.update(glyphs)
				ufo.kern.glyphs_len[name] = len(glyphs)
			else:
				ufo.kern.firsts.update(glyphs)
				ufo.kern.glyphs_len[name] = len(glyphs)

	if ufo.opts.vfb_save:
		update_groups(ufo)


def rename_groups(ufo):

	print(f' Processing font groups..')

	font = fl[ufo.master_copy.ifont]

	font_groups, firsts, seconds = groups_from_kern_feature(font)
	firsts_seconds = firsts | seconds

	no_kerning = {}
	for i, (name, glyphs) in items(font_groups):
		if '_' not in name[0]:
			ufo.groups.opentype[name] = glyphs.split()
			continue
		name = name[1:]
		key_glyph, no_key_glyph = group_key_glyph(glyphs, ("'" in glyphs))
		if no_key_glyph:
			KeyGlyphWarning(name, key_glyph)
		glyphs = glyphs.replace("'", '').split()
		if name in firsts_seconds:
			if name in firsts:
				name = PREFIX_1 + key_glyph
				ufo.groups.kerning[name] = (0, glyphs)
				ufo.kern.firsts_by_key_glyph[key_glyph] = name
				ufo.kern.key_glyph_from_group[name] = key_glyph
			if name in seconds:
				name = PREFIX_2 + key_glyph
				ufo.groups.kerning[name] = (1, glyphs)
				ufo.kern.seconds_by_key_glyph[key_glyph] = name
				ufo.kern.key_glyph_from_group[name] = key_glyph
		else:
			if not ufo.opts.groups_ignore_no_kerning:
				no_kerning[i] = key_glyph
				font_groups[i] = (name, glyphs)

		if no_kerning:
			ufo.groups.no_kerning = set(no_kerning.keys())
			for i, key_glyph in items(no_kerning):
				name, glyphs = font_groups[i]
				lc_name = name.lower()
				first = (
					PREFIX_1 in lc_name or 'mmk_l' in lc_name or lc_name.endswith('_l')
					)
				second = (
					PREFIX_2 in lc_name or 'mmk_r' in lc_name or lc_name.endswith('_r')
					)
				if not first and not second:
					first, second = font.GetClassLeft(i), font.GetClassRight(i)
				if first:
					name = PREFIX_1 + key_glyph
					ufo.groups.kerning[name] = (0, glyphs)
					ufo.kern.firsts_by_key_glyph[key_glyph] = name
					ufo.kern.key_glyph_from_group[name] = key_glyph
				if second:
					name = PREFIX_2 + key_glyph
					ufo.groups.kerning[name] = (1, glyphs)
					ufo.kern.seconds_by_key_glyph[key_glyph] = name
					ufo.kern.key_glyph_from_group[name] = key_glyph


def groups_from_kern_feature(font):

	font_groups = {i: py_unicode(group).split(': ')
		for i, group in enumerate(font.classes)}

	firsts, seconds = set(), set()
	kern_feature = py_unicode(font.MakeKernFeature().value).replace('enum ', '')
	kern_feature = [line.split()[1:3] for line in kern_feature.splitlines()
		if '@' in line]
	for first, second in kern_feature:
		if '@' in first[0]:
			firsts.add(first[2:])
		if '@' in second[0]:
			seconds.add(second[2:])

	return font_groups, firsts, seconds


def import_flc(ufo):

	print(f' Importing groups from {os.path.basename(ufo.paths.flc)}..')

	font = fl[ufo.master_copy.ifont]
	flc_file = user.read_file(ufo.paths.flc)
	flc_groups = parse_flc(flc_file)

	for name, (flag, glyphs) in items(flc_groups):
		if flag is None:
			ufo.groups.opentype[name] = glyphs.split()
			continue
		key_glyph, no_key_glyph = group_key_glyph(glyphs, ("'" in glyphs))
		if no_key_glyph:
			KeyGlyphWarning(name, key_glyph)
			glyphs = glyphs.split()
		else:
			glyphs = glyphs.replace("'", '').split()
		if 'L' in flag:
			name = PREFIX_1 + key_glyph
			ufo.groups.kerning[name] = (0, glyphs)
			ufo.kern.firsts_by_key_glyph[key_glyph] = name
			ufo.kern.key_glyph_from_group[name] = key_glyph
		if 'R' in flag:
			name = PREFIX_2 + key_glyph
			ufo.groups.kerning[name] = (1, glyphs)
			ufo.kern.seconds_by_key_glyph[key_glyph] = name
			ufo.kern.key_glyph_from_group[name] = key_glyph

	ufo.groups.imported = 1


def import_groups_plist(ufo):

	print(f' Importing groups from {os.path.basename(ufo.paths.groups_plist)}..')

	font = fl[ufo.master_copy.ifont]
	plist = user.read_file(ufo.paths.groups_plist)

	if '@MMK' in plist:
		for (ver1, ver2) in [('@MMK_L_', PREFIX_1), ('@MMK_R_', PREFIX_2)]:
			plist = plist.replace(ver1, ver2)

	plist_groups = parse_plist(plist)

	for name, glyphs in items(plist_groups):
		if 'public.kern' not in name:
			ufo.groups.opentype[name] = glyphs
			continue
		key_glyph = name[13:]
		if PREFIX_1 in name:
			name = PREFIX_1 + key_glyph
			ufo.groups.kerning[name] = (0, glyphs)
			ufo.kern.firsts_by_key_glyph[key_glyph] = name
			ufo.kern.key_glyph_from_group[name] = key_glyph
		else:
			name = PREFIX_2 + key_glyph
			ufo.groups.kerning[name] = (1, glyphs)
			ufo.kern.seconds_by_key_glyph[key_glyph] = name
			ufo.kern.key_glyph_from_group[name] = key_glyph

	ufo.groups.imported = 1


def update_groups(ufo):

	font = fl[ufo.master_copy.ifont]

	if ufo.groups.imported:
		ufo.opts.groups_ignore_no_kerning = 0

	font_classes = []
	for name, glyphs in sorted(items(ufo.groups.opentype)):
		font_classes.append(f"{name}: {' '.join(glyphs)}")
	for name, (_, glyphs) in sorted(items(ufo.groups.kerning)):
		key_glyph = ufo.kern.key_glyph_from_group[name]
		font_classes.append(f"_{name}: {insert_key_glyph(glyphs, key_glyph)}")

	font.classes = py_bytes('\n'.join(font_classes)).splitlines()
	for i, group in enumerate(font.classes):
		if ufo.opts.groups_ignore_no_kerning:
			if i in ufo.groups.no_kerning:
				continue
		if b'_' in group[0]:
			if b'.kern1.' in group:
				font.SetClassFlags(i, 1, 0)
			elif b'.kern2.' in group:
				font.SetClassFlags(i, 0, 1)


def write_flc(ufo):

	if ufo.opts.groups_export_flc_path:
		flc_export_path = ufo.opts.groups_export_flc_path.encode('utf_8')
	else:
		version = ufo.master.version.replace('.', '_')
		if ufo.master.font_style in (1, 33):
			filename = f'{ufo.master.family_name}_Italic_{version}.flc'
		else:
			filename = f'{ufo.master.family_name}_{version}.flc'
		flc_export_path = os.path.join(ufo.paths.out, filename).encode('utf_8')

	if os.path.isfile(flc_export_path):
		if ufo.opts.force_overwrite:
			remove_path(flc_export_path, force=1)
		else:
			raise UserWarning(f'{flc_export_path} already exists.\n'
				'Please rename or move existing class file')

	print(f' Writing {filename}..')

	flc_file = [FLC_HEADER + '\n']
	flc_end_marker = FLC_END_MARKER + '\n'
	for name, glyphs in sorted(items(ufo.groups.opentype)):
		flc_file += [
			f'{FLC_GROUP_MARKER} {name}',
			f"{FLC_GLYPHS_MARKER} {' '.join(glyphs)}",
			flc_end_marker,
			]
	for name, (second, glyphs) in sorted(items(ufo.groups.kerning)):
		key_glyph = ufo.kern.key_glyph_from_group[name]
		if second:
			flc_file += [
				f'{FLC_GROUP_MARKER} _{name}',
				f'{FLC_GLYPHS_MARKER} {insert_key_glyph(glyphs, key_glyph)}',
				FLC_RIGHT_KERNING_MARKER,
				flc_end_marker,
				]
		else:
			flc_file += [
				f'{FLC_GROUP_MARKER} _{name}',
				f'{FLC_GLYPHS_MARKER} {insert_key_glyph(glyphs, key_glyph)}',
				FLC_LEFT_KERNING_MARKER,
				flc_end_marker,
				]

	flc_file = file_str('\n'.join(flc_file))
	write_file(flc_export_path, flc_file)
