# coding: future_fstrings
# cython: wraparound=False
# cython: infer_types=True, cdivision=True
# cython: optimize.use_switch=True, optimize.unpack_method_calls=True
from __future__ import absolute_import, division, print_function, unicode_literals

import os
import xml.etree.cElementTree as etree

from FL import fl

from vfb2ufo.future import *

def rename_groups(ufo, font):

	if ufo.kern.groups_rename:
		print('\n  Renaming groups')
		rename_font_groups(ufo, font)
	elif ufo.groups.import_flc_path:
		import_flc_path = os.path.basename(ufo.groups.import_flc_path)
		print(f'\n  Importing groups from {import_flc_path}')
		import_flc(ufo, font)
	elif ufo.groups.import_groups_plist_path:
		import_groups_plist_path = os.path.basename(ufo.groups.import_groups_plist_path)
		print(f'\n  Importing groups from {import_groups_plist_path}')
		import_groups_plist(ufo, font)


cdef _rename_font_groups(object ufo, object font):

	'''
	kern groups from GetClassLeft/GetClassRight FL methods
	'''

	ufo.kern_firsts_by_key_glyph, ufo.kern_seconds_by_key_glyph = {}, {}
	ufo.kern_groups, ufo.ot_groups = {}, {}
	for i, font_class in enumerate(font.classes):
		group_name, group_glyphs = str(font_class).strip().split(': ')
		if group_name.startswith('_'):
			first, second = font.GetClassLeft(i), font.GetClassRight(i)
			key_glyph, group_glyphs, no_key_glyph = _group_key_glyph(group_glyphs.strip().split())
			if no_key_glyph:
				print(f"  A key glyph was not found in {group_name}\n"
					f"  Glyph '{key_glyph}' was marked as the key glyph")
			if first and second:
				first_group_name = ufo.kern.first_prefix + key_glyph
				second_group_name = ufo.kern.second_prefix + key_glyph
				ufo.kern_firsts_by_key_glyph[key_glyph] = first_group_name
				ufo.kern_seconds_by_key_glyph[key_glyph] = second_group_name
				ufo.kern_groups[first_group_name] = group_glyphs
				ufo.kern_groups[second_group_name] = group_glyphs
			elif first:
				first_group_name = ufo.kern.first_prefix + key_glyph
				ufo.kern_firsts_by_key_glyph[key_glyph] = first_group_name
				ufo.kern_groups[first_group_name] = group_glyphs
			elif second:
				second_group_name = ufo.kern.second_prefix + key_glyph
				ufo.kern_seconds_by_key_glyph[key_glyph] = second_group_name
				ufo.kern_groups[second_group_name] = group_glyphs
		else:
			ufo.ot_groups[group_name] = group_glyphs

	_master_groups(ufo, font)
	_update_font_groups(ufo, font)


cdef rename_font_groups(object ufo, object font):

	'''
	FontLab's GetClassLeft and GetClassRight methods are not parallelizable
	this method deductively identifies 'left' and 'right' classes using the
	builtin GetClassLeft/GetClassRight FL methods as little as possible
	'''

	cdef:
		list firsts, seconds, first_seconds

	firsts, seconds = _groups_from_kern_feature(ufo, font)
	kern_groups, firsts, seconds, first_seconds = _kern_groups_with_kerning(ufo, font, firsts, seconds)

	if ufo.kern.ignore_groups_with_no_kerning:
		kern_classes = [(i, font_class)
			for i, font_class in enumerate(font.classes)
			if font_class.startswith('_')]
		kern_groups_no_kerning = []
	else:
		kern_classes, kern_groups_no_kerning = _kern_groups_with_no_kerning(ufo, font, firsts, seconds, first_seconds)

	firsts, seconds, first_seconds = _final_kern_groups(ufo, font, kern_classes, kern_groups_no_kerning, firsts, seconds, first_seconds)
	_build_font_groups(ufo, font, firsts, seconds, first_seconds)

	_master_groups(ufo, font)
	_update_font_groups(ufo, font)


cdef tuple _groups_from_kern_feature(object ufo, object font):

	'''
	groups from MakeKernFeature()
	'''

	cdef:
		unicode kern_feature = str(font.MakeKernFeature().value).replace('enum ', '')
		list kern_feature_list = [line.strip() for line in kern_feature.splitlines()
			if line.count('@')]
		list firsts = []
		list seconds = []
		Py_ssize_t i

	for line in kern_feature_list:
		line_list = line.split()
		if line.count('@') == 2:
			firsts.append(line_list[1][1:])
			seconds.append(line_list[2][1:])
		else:
			for i, chunk in enumerate(line_list):
				if chunk.count('@'):
					if i == 1:
						firsts.append(chunk[1:])
					else:
						seconds.append(chunk[1:])

	return firsts, seconds


cdef tuple _kern_groups_with_kerning(
	object ufo,
	object font,
	list firsts,
	list seconds,):

	'''
	kern groups with kerning
	'''

	cdef:
		set firsts_set = set(firsts)
		set seconds_set = set(seconds)
		list first_seconds = []
		dict kern_groups = {}
		Py_ssize_t i

	for i, font_class in enumerate(font.classes):
		if font_class.startswith('_'):
			group_name, group_glyphs = str(font_class).split(': ')
			kern_groups[group_name] = group_glyphs
			if group_name in firsts_set:
				if font.GetClassRight(i):
					first_seconds.append(group_name)
					firsts_set.discard(group_name)
					seconds_set.discard(group_name)

	return kern_groups, list(firsts_set), list(seconds_set), first_seconds


cdef tuple _kern_groups_with_no_kerning(
	object ufo,
	object font,
	list firsts,
	list seconds,
	list first_seconds,):

	'''
	kern groups in FL-classes without kerning
	'''

	cdef:
		Py_ssize_t i
		list kern_classes = [(i, str(font_class))
			for i, font_class in enumerate(font.classes)
			if font_class.startswith('_')]
		set current_groups = set(firsts + seconds + first_seconds)
		list kern_groups_no_kerning = [kern_class
			for kern_class in kern_classes
			if kern_class not in current_groups]

	return kern_classes, kern_groups_no_kerning


cdef tuple _final_kern_groups(
	object ufo,
	object font,
	list kern_classes,
	list kern_groups_no_kerning,
	list firsts,
	list seconds,
	list first_seconds,):

	'''
	finalize kern groups
	check kern group's left/right flag
	add/remove as necessary from existing groups
	'''

	cdef:
		Py_ssize_t i

	if kern_groups_no_kerning:
		for i, kern_class in kern_classes:
			group_name = kern_class.split(': ')[0]
			if group_name in kern_groups_no_kerning:
				left, right = font.GetClassLeft(i), font.GetClassRight(i)

				if left and right:
					first_seconds.append(group_name)
				elif left:
					firsts.append(group_name)
				else:
					seconds.append(group_name)

	return firsts, seconds, first_seconds


cdef _build_font_groups(
	object ufo,
	object font,
	list firsts,
	list seconds,
	list first_seconds,):

	'''
	rename FL-classes for UFO-version specific generation
	'''

	cdef:
		set firsts_set = set(firsts)
		set seconds_set = set(seconds)
		set first_seconds_set = set(first_seconds)

	ufo.kern_firsts_by_key_glyph, ufo.kern_seconds_by_key_glyph = {}, {}
	ufo.ot_groups, ufo.kern_groups = {}, {}
	for i, font_class in enumerate(font.classes):
		group_name, group_glyphs = str(font_class.strip()).split(': ')
		if group_name.startswith('_'):
			key_glyph, group_glyphs, no_key_glyph = _group_key_glyph(group_glyphs.strip().split())
			if no_key_glyph:
				print(f"  A key glyph was not found in {group_name}\n"
					f"  Glyph '{key_glyph}' was marked as the key glyph")
			if group_name in first_seconds_set:
				first_group_name = ufo.kern.first_prefix + key_glyph
				second_group_name = ufo.kern.second_prefix + key_glyph
				ufo.kern_firsts_by_key_glyph[key_glyph] = first_group_name
				ufo.kern_seconds_by_key_glyph[key_glyph] = second_group_name
				ufo.kern_groups[first_group_name] = group_glyphs
				ufo.kern_groups[second_group_name] = group_glyphs
			elif group_name in firsts_set:
				first_group_name = ufo.kern.first_prefix + key_glyph
				ufo.kern_firsts_by_key_glyph[key_glyph] = first_group_name
				ufo.kern_groups[first_group_name] = group_glyphs
			else:
				second_group_name = ufo.kern.second_prefix + key_glyph
				ufo.kern_seconds_by_key_glyph[key_glyph] = second_group_name
				ufo.kern_groups[second_group_name] = group_glyphs
		else:
			ufo.ot_groups[group_name] = group_glyphs


cdef import_flc(object ufo, object font):

	'''
	import groups from .flc file
	'''

	cdef:
		unicode prefix_1 = '_public.kern1.'
		unicode prefix_2 = '_public.kern2.'
		unicode _prefix_1 = '_MMK_L_'
		unicode _prefix_2 = '_MMK_R_'
		Py_ssize_t i, j, k
		unicode flc_filename = os.path.basename(ufo.groups.import_flc_path)
		unicode flc_file
		unicode group_name
		list flc_list
		list group_names = []
		list font_groups = []
		list group_flags = []

	with open(ufo.groups.import_flc_path, 'r') as f:
		flc_file = f.read()

	# normalize group names
	flc_file = flc_file.replace(_prefix_1, '').replace(_prefix_2, '')
	flc_file = flc_file.replace(prefix_1, '').replace(prefix_2, '')
	flc_list = flc_file.splitlines()

	for i, line in enumerate(flc_list):
		if line.startswith('%%C'):
			group_names.append(line.split()[1])
			font_groups.append(flc_list[i+1].split()[1:])
			group_flag = flc_list[i+2]
			if group_flag.startswith('%%K'):
				group_flags.append(group_flag.split()[1])
			else:
				group_flags.append('')

	ufo.kern_firsts_by_key_glyph, ufo.kern_seconds_by_key_glyph = {}, {}
	ufo.kern_groups, ufo.ot_groups = {}, {}
	for group_name, group_glyphs, group_flag in zip(group_names, font_groups, group_flags):
		if group_flag:
			key_glyph, group_glyphs_str, no_key_glyph = _group_key_glyph(group_glyphs)
			if no_key_glyph:
				print(f"  A key glyph was not found in {group_name} from {flc_filename}\n"
					f"  Glyph '{key_glyph}' was marked as the key glyph")
			if group_flag.count('L'):
				group_name = ufo.kern.first_prefix + key_glyph
				ufo.kern_firsts_by_key_glyph[key_glyph] = group_name
				ufo.kern_groups[group_name] = group_glyphs_str
			if group_flag.count('R'):
				group_name = ufo.kern.second_prefix + key_glyph
				ufo.kern_seconds_by_key_glyph[key_glyph] = group_name
				ufo.kern_groups[group_name] = group_glyphs_str
		else:
			ufo.ot_groups[group_name] = ' '.join(group_glyphs)

	_master_groups(ufo, font)
	_update_font_groups(ufo, font)


cdef import_groups_plist(object ufo, object font):

	'''
	import groups plist
	'''

	cdef:
		unicode prefix_1 = 'public.kern1.'
		unicode prefix_2 = 'public.kern2.'
		unicode _prefix_1 = '@MMK_L_'
		unicode _prefix_2 = '@MMK_R_'
		unicode groups_plist
		unicode group_name
		unicode group_glyphs
		dict groups = {}
		list glyphs = []

	with open(ufo.groups.import_groups_plist_path, 'r') as f:
		groups_plist = f.read().strip()

	# normalize group names
	groups_plist = groups_plist.replace(_prefix_1, prefix_1).replace(_prefix_2, prefix_2)
	plist = etree.fromstring(groups_plist)

	ufo.kern_firsts_by_key_glyph, ufo.kern_seconds_by_key_glyph = {}, {}
	ufo.kern_groups, ufo.ot_groups = {}, {}
	group_name = ''
	for plist_dict in plist:
		for key in plist_dict:
			if group_name and glyphs:
				groups[group_name] = f" {' '.join(glyphs)} "
			if key.tag == 'key':
				group_name = str(key.text)
			if key.tag == 'array':
				glyphs = [str(glyph.text) for glyph in key]

	for group_name, group_glyphs in items(groups):
		if group_name.startswith('public.kern'):
			key_glyph = group_name.replace(prefix_1, '').replace(prefix_2, '')
			group_glyphs = group_glyphs.replace(f' {key_glyph} ', f" {key_glyph}' ")
			ufo.kern_groups[group_name] = ' '.join(group_glyphs.split())
			if group_name.count(prefix_1):
				ufo.kern_firsts_by_key_glyph[key_glyph] = group_name
			elif group_name.count(prefix_2):
				ufo.kern_seconds_by_key_glyph[key_glyph] = group_name
		else:
			ufo.ot_groups[group_name] = group_glyphs

	_master_groups(ufo, font)
	_update_font_groups(ufo, font)


cdef tuple _group_key_glyph(list group_glyphs):

	'''
	key glyph from .flc or current fl.font.classes
	check current glyph groups for a key glyph
	if no key glyph is found, mark the first glyph as the key glyph

	_group_key_glyph("A' AA AE")
	>>> (A, "A' AA AE", 0)
	_group_key_glyph("A AA AE")
	>>> (A, "A' AA AE", 1)
	'''

	cdef:
			bint no_key_glyph = 0

	key_glyph = None
	for glyph in group_glyphs:
		if glyph.count("'"):
			key_glyph = glyph.replace("'", '').strip()
			break
	if not key_glyph:
		key_glyph, no_key_glyph = group_glyphs[0], 1
		if len(group_glyphs) > 1:
			group_glyphs = [key_glyph + "'"] + group_glyphs[1:]
		else:
			group_glyphs = [key_glyph + "'"]

	return key_glyph, ' '.join(group_glyphs), no_key_glyph


cdef _update_font_groups(object ufo, object font):

	cdef:
		list font_classes
		Py_ssize_t i

	font_classes = [bytes(f'{group_name}: {group_glyphs}')
		for group_name, group_glyphs in sorted(items(ufo.ot_groups))]
	font_classes += [bytes(f'_{group_name}: {group_glyphs}')
		for group_name, group_glyphs in sorted(items(ufo.kern_groups))]

	font.classes = font_classes

	fl.UpdateFont(ufo.master_copy)

	for i, font_class in enumerate(font.classes):
		if font_class.startswith('_'):
			if font_class.count(ufo.kern.first_prefix):
				font.SetClassFlags(i, 1, 0)
			if font_class.count(ufo.kern.second_prefix):
				font.SetClassFlags(i, 0, 1)

	fl.UpdateFont(ufo.master_copy)


cdef _master_groups(object ufo, object font):

	'''
	map kern group names to key glyph
	'''

	ufo.master_groups_by_key_glyph, ufo.master_groups_by_group_name = {}, {}
	for font_class in font.classes:
		group_name, group_glyphs = str(font_class).split(': ')
		if group_name.startswith('_'):
			key_glyph = _group_key_glyph(group_glyphs.split())[0]
			ufo.master_groups_by_key_glyph[key_glyph] = group_name
			ufo.master_groups_by_group_name[group_name] = key_glyph
