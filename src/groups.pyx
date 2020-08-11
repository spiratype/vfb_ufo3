# coding: utf-8
# cython: wraparound=False
# cython: boundscheck=False
# cython: infer_types=True
# cython: cdivision=True
# cython: auto_pickle=False
# cython: c_string_type=unicode
# cython: c_string_encoding=utf_8
# distutils: language=c++
# distutils: extra_compile_args=[-O3, -fconcepts, -Wno-register, -fno-strict-aliasing, -std=c++17]
from __future__ import division, unicode_literals, print_function
include 'includes/future.pxi'

cimport cython
from cpython.dict cimport PyDict_SetItem
from libcpp.string cimport string
from libcpp.vector cimport vector

import os
import shutil
import stat
import threading
import time
import uuid

from FL import fl

include 'includes/thread.pxi'
include 'includes/path.pxi'
include 'includes/unique.pxi'
include 'includes/file.pxi'
include 'includes/flc.pxi'
include 'includes/groups.pxi'
include 'includes/ordered_dict.pxi'
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
			ufo.kern.glyphs_len[name] = len(glyphs)
			if second:
				ufo.kern.seconds.update(glyphs)
			else:
				ufo.kern.firsts.update(glyphs)

	if ufo.opts.vfb_save:
		update_groups(ufo)


def rename_groups(ufo):

	print(b' Processing font groups..')

	font = fl[ufo.master_copy.ifont]

	font_groups, firsts, seconds = groups_from_kern_feature(font)
	firsts_seconds = firsts | seconds

	no_kerning = {}
	for i, (name, glyphs) in items(font_groups):
		if not name.startswith('_'):
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
				first = PREFIX_1 in lc_name or 'mmk_l' in lc_name or lc_name.endswith('_l')
				second = PREFIX_2 in lc_name or 'mmk_r' in lc_name or lc_name.endswith('_r')
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

	font_groups = {i: group.decode('cp1252').split(': ')
		for i, group in enumerate(font.classes)}

	firsts, seconds = set(), set()
	kern_feature = font.MakeKernFeature().value.decode('cp1252').replace('enum ', '')
	kern_feature = [line.split()[1:3]
		for line in kern_feature.splitlines()
		if '@' in line]
	for first, second in kern_feature:
		if first.startswith('@'):
			firsts.add(first[2:])
		if second.startswith('@'):
			seconds.add(second[2:])

	return font_groups, firsts, seconds


def import_flc(ufo):

	print(f' Importing groups from {os_path_basename(ufo.paths.flc)}..')

	font = fl[ufo.master_copy.ifont]
	flc_file = read_file(ufo.paths.flc).decode('cp1252')
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

	print(f' Importing groups from {os_path_basename(ufo.paths.groups_plist)}..')

	font = fl[ufo.master_copy.ifont]
	plist = read_file(ufo.paths.groups_plist).decode('utf_8')

	if '@MMK' in plist:
		for (ver1, ver2) in (('@MMK_L_', PREFIX_1), ('@MMK_R_', PREFIX_2)):
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
		font_classes.append(f'{name}: {" ".join(glyphs)}')
	for name, (_, glyphs) in sorted(items(ufo.groups.kerning)):
		key_glyph = ufo.kern.key_glyph_from_group[name]
		font_classes.append(f'_{name}: {insert_key_glyph(glyphs, key_glyph)}')

	output = fl.output
	font.classes = '\n'.join(font_classes).encode('cp1252').splitlines()
	fl.BeginProgress(b'Updating groups for master.vfb...', len(font_classes))
	for i, group in enumerate(font.classes):
		if not i % 4:
			fl.TickProgress(i)
		if ufo.opts.groups_ignore_no_kerning:
			if i in ufo.groups.no_kerning:
				continue
		if group.startswith(b'_'):
			if b'.kern1.' in group:
				font.SetClassFlags(i, 1, 0)
			elif b'.kern2.' in group:
				font.SetClassFlags(i, 0, 1)
	fl.EndProgress()


def write_flc(ufo):

	if ufo.opts.groups_export_flc_path:
		filename = os_path_basename(ufo.opts.groups_export_flc_path)
		flc_export_path = ufo.opts.groups_export_flc_path
	else:
		version = ufo.master.version.replace('.', '_')
		if ufo.master.font_style in (1, 33):
			filename = f'{ufo.master.family_name}_Italic_{version}.flc'
		else:
			filename = f'{ufo.master.family_name}_{version}.flc'
		flc_export_path = os_path_join(ufo.paths.out, filename)

	if os_path_isfile(flc_export_path):
		if ufo.opts.force_overwrite:
			remove_path(flc_export_path, force=1)
		else:
			raise RuntimeError(b'%s already exists.\n'
				b'Please rename or move existing class file' % flc_export_path)

	print(f' Writing {filename}..')

	flc_file = [f'{FLC_HEADER}\n']
	flc_end_marker = f'{FLC_END_MARKER}\n'
	for name, glyphs in sorted(items(ufo.groups.opentype)):
		flc_file += [
			f'{FLC_GROUP_MARKER} {name}',
			f'{FLC_GLYPHS_MARKER} {" ".join(glyphs)}',
			flc_end_marker,
			]
	for name, (second, glyphs) in sorted(items(ufo.groups.kerning)):
		key_glyph = ufo.kern.key_glyph_from_group[name]
		glyphs = insert_key_glyph(glyphs, key_glyph)
		group_marker = FLC_RIGHT_KERNING_MARKER if second else FLC_LEFT_KERNING_MARKER
		flc_file += [
			f'{FLC_GROUP_MARKER} _{name}',
			f'{FLC_GLYPHS_MARKER} {glyphs}',
			group_marker,
			flc_end_marker,
			]

	write_file(flc_export_path, '\n'.join(flc_file))
