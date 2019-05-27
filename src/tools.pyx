# coding: future_fstrings
# cython: boundscheck=False
# cython: infer_types=True, cdivision=True
# cython: optimize.use_switch=True, optimize.unpack_method_calls=True
from __future__ import absolute_import, division, print_function, unicode_literals
from vfb2ufo3.future import open, range, str, zip, items

from tools cimport uni_transform

import collections
import contextlib
import os
import re
import shutil
import tempfile
import time
import zipfile

from FL import fl, Feature, Font

from vfb2ufo3 import fontinfo, groups, vfb
from vfb2ufo3.constants import (
	WIN_1252, MACOS_ROMAN, FL_ENC_HEADER, FLC_HEADER, FLC_GROUP_MARKER,
	FLC_GLYPHS_MARKER, FLC_KERNING_MARKER, FLC_END_MARKER, OT_SCRIPTS,
	OT_LANGUAGES,
	)

ENVIRON = os.path.expanduser('~')

# --------
#  errors
# --------

class GlyphNameError(Exception):

	'''
	Error class for glyph name errors

	Valid Type 1 glyph name character set: A-Z, a-z, 0-9, '.', and '_'
	Valid production glyph name character set: A-Z, a-z, 0-9, and [_ . - + * : ~ ^ !]
	'''

	def __init__(self, message):
		super(GlyphNameError, self).__init__(message)

class GlyphUnicodeError(Exception):

	'''
	Error class for glyph unicode errors

	Error raised when Unicode value has been mapped to more than one glyph
	'''

	def __init__(self, message):
		super(GlyphUnicodeError, self).__init__(message)

# -------------------------
#  argument wrapping class
# -------------------------

class AttributeDict(object):

	def __init__(self, **kwargs):
		self.__dict__.update(kwargs)

# -----------------------------
#  try/except pass replacement
# -----------------------------

@contextlib.contextmanager
def ignored(*exceptions):
	if not exceptions:
		try:
			yield
		except:
			pass
	else:
		try:
			yield
		except exceptions:
			pass

# ----------------
#  report builder
# ----------------

def report_log(ufo):

	'''
	output window reporter
	'''

	if ufo.ufoz.write:
		filename = os.path.basename(ufo.instance_paths.ufoz)
	else:
		filename = os.path.basename(ufo.instance_paths.ufo)

	if ufo.report:
		# build a more detailed output report
		if ufo.scale.auto or ufo.scale.factor:
			if ufo.scale.auto:
				upm = f'{ufo.upm} upm (auto-scaled)'
			else:
				upm = f'{ufo.upm} upm (scaled)'
		else:
			upm = f'{ufo.upm} upm'

		glyph_options = []
		if ufo.glyph.decompose or ufo.glyph.remove_overlaps:
			if ufo.glyph.decompose and ufo.glyph.remove_overlaps:
				glyph_options.append('decomposition')
			if ufo.glyph.remove_overlaps:
				glyph_options.append('overlaps removed')
			glyph_options = '\n    '.join(glyph_options)
			glyph_options = f'  glyph options:\n    {glyph_options}'

		font_options = ''
		if ufo.afdko.parts:
			font_options = '  font options:\n    AFDKO'

		completion = f'\n  {filename} completed'
		upm_version = f'  {upm} UFO{ufo.version}'
		ufo_time = time.clock() - ufo.instance_start
		time_total = f'  {time_string(ufo_time)} ({len(ufo.glyphs)} glyphs)'

		# final report
		font_report = [completion, upm_version, time_total]
		if font_options:
			font_report.append(font_options)
		if glyph_options:
			font_report.append(glyph_options)

		if ufo.report_detailed:
			times = ufo.instance_times
			other_time = ufo_time - times.glifs - times.fea - times.plist - times.afdko
			font_report.extend([
				'  times:',
				f'    {time_string(times.glifs)} (glyphs)',
				f'    {time_string(times.fea)} (features)',
				f'    {time_string(times.plist)} (plists)',
				f'    {time_string(times.afdko)} (afdko)',
				f'    {time_string(other_time)} (other)',
				])

		print('\n'.join(font_report))

	else:
		print(f'  {filename} (UFO{ufo.version}) completed '
			f'({time_string(time.clock() - ufo.instance_start)}).')

	if ufo.last:
		print(f'\n{ufo.completed} UFO(s) completed '
			f'({time_string(time.clock() - ufo.total_start)})')
		remove_file(str(ufo.encoding))

# ----------------
#  font utilities
# ----------------

cdef list GOADB_from_encoding(object ufo):

	cdef:
		list glyph_order = ufo.glyph_order
		object font = fl[fl.ifont]
		list first_256_names, first_256_uni_names, goadb_names
		list goadb_uni_names = []
		tuple first_256
		dict glyph_uni_dict

	if ufo.afdko.GOADB_win1252:
		first_256 = WIN_1252

	if ufo.afdko.GOADB_macos_roman:
		first_256 = MACOS_ROMAN

	if ufo.afdko.GOADB_win1252 or ufo.afdko.GOADB_macos_roman:
		first_256_names = ['.notdef']
		first_256_names.extend([
			str(font[font.FindGlyph(int(glyph_unicode))].name)
			for glyph_unicode in first_256
			if glyph_unicode and font.has_key(int(glyph_unicode))
			])
		first_256_uni_names = [None for i in range(len(first_256_names))]
	else:
		first_256_names, first_256_uni_names = ['.notdef'], [None]

	goadb_names = [glyph for glyph in ufo.glyph_order
		if glyph not in set(first_256_names)]

	glyph_uni_dict = {str(glyph.name): glyph.unicode
		for glyph in font.glyphs}

	for glyph in goadb_names:
		glyph_unicode = glyph_uni_dict[glyph]
		if glyph_unicode:
			glyph_uni = uni_transform(glyph_unicode)
			if len(glyph_uni) == 4:
				goadb_uni_names.append(f'uni{glyph_uni}')
			else:
				goadb_uni_names.append(f'u{glyph_uni}')
		else:
			goadb_uni_names.append(None)

	return list(zip(first_256_names + goadb_names, first_256_uni_names + goadb_uni_names))


cdef font_encoding(object font, object ufo):

	'''
	build FontLab encoding file from the master font's encoding attribute
	'''

	cdef:
		list encoding = []
		list glyph_order = []
		list encoding_file = [FL_ENC_HEADER]

	for record in font.encoding:
		# calls to font.encoding attributes will crash FontLab
		record = repr(record)[1:-1].replace('"', '').replace(',', '').split()
		glyph_name, glyph_unicode = record[1], record[3]
		if glyph_name == '(null)':
			glyph_name = None
		if glyph_unicode == '-1':
			glyph_unicode = None
		else:
			glyph_unicode = uni_transform(int(glyph_unicode))
		encoding.append((glyph_name, glyph_unicode))

	for i, (glyph_name, glyph_unicode) in enumerate(encoding):
		if glyph_name and not glyph_name.startswith('_'):
			glyph_order.append(glyph_name)
			if glyph_name and glyph_unicode:
				encoding_file.append(f'{glyph_name} {i} % U+{glyph_unicode}:')
			else:
				encoding_file.append(f'{glyph_name} {i} %')

	encoding_path = user_path('__temp__.enc', temp=True)
	write_file(encoding_path, '\n'.join(encoding_file))

	ufo.encoding = bytes(encoding_path)
	ufo.glyph_order = [glyph for glyph in glyph_order
		if font.has_key(bytes(glyph))]

	if ufo.afdko.parts:
		if ufo.afdko.GOADB_path:
			temp_GOADB_path = user_path('__GOADB__', temp=True)
			shutil.copy2(ufo.afdko.GOADB_path, temp_GOADB_path)
			with open(temp_GOADB_path, 'r') as f:
				ufo.afdko.GOADB = str(f.read()).strip().splitlines()
		else:
			ufo.afdko.GOADB = GOADB_from_encoding(ufo)


def master_names_values(font):

	'''
	build master layer instance values and names
	'''

	axes_n = len(font.axis)
	layers = 2 ** axes_n

	a_0 = (0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1)
	a_1 = (0, 0, 1, 1, 0, 0, 1, 1, 0, 0, 1, 1, 0, 0, 1, 1)
	a_2 = (0, 0, 0, 0, 1, 1, 1, 1, 0, 0, 0, 0, 1, 1, 1, 1)
	a_3 = (0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1)

	axes = zip(a_0[:layers], a_1[:layers], a_2[:layers], a_3[:layers])

	axes_shorts = [[f'{axis[1]}{i}' for i in range(2)] for axis in font.axis]
	axis_matrix = [i[:axes_n] for i in axes]

	master_values = [tuple([j * 1000 for j in i]) for i in axis_matrix]
	names = [[axes_shorts[i][j]
		for i, j in enumerate(vector)] for vector in axis_matrix]

	return master_values, names


cdef write_flc(object ufo, object font):

	'''
	export groups to .flc file
	'''

	cdef:
		unicode flc_export_path = user_path('UFO_classes.flc')
		list flc_file = [FLC_HEADER]

	if os.path.exists(flc_export_path) and not ufo.force_overwrite:
		raise UserWarning(f'{flc_export_path} already exists.\n'
			'Please rename or move existing class file')
	elif ufo.force_overwrite:
		remove_file(flc_export_path)

	for font_class in font.classes:
		group_name, group_glyphs = str(font_class).split(': ')
		group_glyphs = ' '.join(group_glyphs.split())
		if group_name.startswith('_'):
			if group_name.count(ufo.kern.first_prefix):
				flc_file.extend([
					f'{FLC_GROUP_MARKER} {group_name}',
					f'{FLC_GLYPHS_MARKER} {group_glyphs}',
					f'{FLC_KERNING_MARKER} L 0',
					FLC_END_MARKER,
					])
			else:
				flc_file.extend([
					f'{FLC_GROUP_MARKER} {group_name}',
					f'{FLC_GLYPHS_MARKER} {group_glyphs}',
					f'{FLC_KERNING_MARKER} R 0',
					FLC_END_MARKER,
					])
		else:
			flc_file.extend([
				f'{FLC_GROUP_MARKER} {group_name}',
				f'{FLC_GLYPHS_MARKER} {group_glyphs}',
				FLC_END_MARKER,
				])

	write_file(flc_export_path, '\n'.join(flc_file))


def check_paths(ufo):

	'''
	check (and clear if force_overwrite) directories to be generated
	'''

	font = fl[ufo.master_copy]
	print('  Checking output paths')

	for names in ufo.names:
		instance_ufo_name = f'{font.family_name}{font.version}-{names}'
		instance_ufo_filename = f"{instance_ufo_name.replace(' ', '')}.ufo"

		if ufo.path:
			instance_ufo_path = user_path(instance_ufo_filename, path=ufo.path)
		else:
			instance_ufo_path = user_path(instance_ufo_filename)

		if ufo.designspace.designspace:
			instance_ufo_path = os.path.join(
				os.path.dirname(instance_ufo_path), 'masters', os.path.basename(instance_ufo_path)
				)

		if ufo.ufoz.write:
			instance_ufoz_path = f'{instance_ufo_path}z'
			if ufo.force_overwrite:
				with ignored(OSError):
					temp_path = f'__{instance_ufoz_path}'
					os.rename(instance_ufoz_path, temp_path)
					os.remove(temp_path)
		else:
			with ignored(OSError):
				if os.lstat(instance_ufo_path).st_mode:
					if ufo.force_overwrite:
						with ignored(OSError):
							temp_path = f'__{instance_ufo_path}'
							shutil.move(instance_ufo_path, temp_path)
							shutil.rmtree(temp_path)
					else:
						raise OSError(f"{instance_ufo_path} already exists.\n"
							"Please remove directory or set 'force_overwrite' to True")


def add_master_copy(master, ufo):

	'''
	add master copy of source font

	this involves copying information from master font to copy that is
	not copied during the normal FontLab copy operation
	'''

	fl.output = b''
	ufo.total_start = time.clock()
	ufo.last, ufo.completed = 0, 0
	ufo.master = fl.ifont
	master_filename = os.path.basename(master.file_name)

	if ufo.report:
		if master.axis:
			print(f"Processing <Font: '{master.full_name}' "
				f"filename='{master_filename}' "
				f"axes={len(master.axis)}>\n")
		else:
			print(f"Processing <Font: '{master.full_name}' "
				f"filename='{master_filename}'>\n")

	print('Pre-processing (building master copy)..')

	# copy glyph groups and font features
	ot_classes = master.ot_classes.strip()
	ot_features = [(fea.tag, fea.value.strip()) for fea in master.features]

	# build language blocks for lookups
	scripts = collections.OrderedDict()
	for line in str(ot_classes).splitlines():
		if line.startswith('languagesystem'):
			line = line.strip().replace(';', '').split()
			script, language = line[1], line[2]
			if script not in scripts:
				scripts[script] = []
			if language != 'dflt':
				scripts[script].append(language)

	lookup_block = []
	if scripts:
		for script, languages in items(scripts):
			lookup_block.append(f'script {script}; # {OT_SCRIPTS[script]}')
			for language in languages:
				lookup_block.append(f'  language {language}; # {OT_LANGUAGES[language]}')

	ufo.default_lookup_block = lookup_block

	font_encoding(master, ufo)

	master_copy = Font(master)
	fl.Add(master_copy)
	ufo.master_copy = fl.ifont
	master_copy = fl[ufo.master_copy]

	if ufo.glyph.omit_names or ufo.glyph.omit_suffixes:
		if ufo.glyph.omit_suffixes:
			omit_names = set()
			for suffix in ufo.glyph.omit_suffixes:
				omit_names.update(set([str(glyph.name)
					for glyph in master_copy.glyphs
					if str(glyph.name).endswith(suffix)]))
		if ufo.glyph.omit_names and ufo.glyph.omit_suffixes:
			omit_names.update(ufo.glyph.omit_names)
			glyphs = (str(glyph.name)
				for glyph in master_copy.glyphs
				if str(glyph.name) not in omit_names)
		elif ufo.glyph.omit_names:
			glyphs = (str(glyph.name)
				for glyph in master_copy.glyphs
				if str(glyph.name) not in ufo.glyph.omit_names)
		elif ufo.glyph.omit_suffixes:
			glyphs = (str(glyph.name)
				for glyph in master_copy.glyphs
				if str(glyph.name) not in omit_names)
	else:
		glyphs = (str(glyph.name) for glyph in master_copy.glyphs)

	ufo.glyphs = set(glyphs)
	ufo.glifs = {}
	for glyph in master_copy.glyphs:
		glyph_name = str(glyph.name)
		if glyph_name in ufo.glyphs:
			glyph_name, glif_glyph_name = glif_name(glyph_name, ufo.afdko.makeotf_release)
			ufo.glifs[glyph_name] = glif_glyph_name

	if ufo.afdko.makeotf_release:
		check_glyph_unicodes(master_copy)

	# load master encoding
	master_copy.encoding.Load(ufo.encoding)

	# rename font kern groups
	groups.rename_groups(ufo, master_copy)

	if ufo.groups.export_flc:
		write_flc(ufo, master_copy)

	# load master OT prefix and feature copies
	master_copy.ot_classes = ot_classes
	for feature_tag, feature_value in ot_features:
		master_copy.features.append(Feature(feature_tag, feature_value))

	master_copy.full_name = bytes(f'{master_copy.family_name} - master')
	master_copy.modified = 0
	fl.UpdateFont(ufo.master_copy)

	if ufo.afdko.makeotf_batch_cmd:
		ufo.afdko.cmd = []
	if ufo.designspace.designspace:
		ufo.path = user_path(path=ufo.path)
		ufo.designspace.path = os.path.join(ufo.path, f'{master_copy.family_name}{master_copy.version}.designspace')

	# check paths for instances
	check_paths(ufo)

	ufo.start = 1


def add_instance(ufo, masters, instance_value, instance_name, instance_attrs):

	'''
	add instance from master copy
	'''

	if ufo.start:
		print('\nBuilding UFOs..')
		ufo.start = 0

	ufo.instance_start = time.clock()

	master_copy = fl[ufo.master_copy]
	instance_name = ''.join(instance_name)

	# copy glyph groups and font features
	ot_classes = master_copy.ot_classes.strip()
	ot_features = [(feature.tag, feature.value.strip())
		for feature in master_copy.features]

	# instance or master
	if len(instance_value) != len(master_copy.axis):
		raise UserWarning('\nInstance value must have one value for each axis')
	else:
		if master_copy.axis:
			instance = Font(master_copy, instance_value)
		if instance_value == ufo.values[-1]:
			ufo.last = 1

	# single layer instance
	if not ufo.layer and not instance_value:
		if not len(master_copy.axis):
			instance = Font(master_copy)

	fl.Add(instance)
	instance = fl[fl.ifont]
	ufo.ifont = fl.ifont
	ufo.completed += 1
	ufo.italic = instance.font_style in (1, 33)

	# load master encoding
	instance.encoding.Load(ufo.encoding)

	# check instance dict attributes
	ufo.fontinfo = AttributeDict(
		ascender=None,
		blue_fuzz=None,
		blue_scale=None,
		blue_shift=None,
		blue_values=None,
		cap_height=None,
		codepages=None,
		copyright=None,
		date=None,
		default_character=None,
		default_width=None,
		descender=None,
		designer=None,
		designer_url=None,
		family_blues=None,
		family_name=None,
		family_other_blues=None,
		font_name=None,
		font_style=None,
		force_bold=None,
		full_name=None,
		is_fixed_pitch=None,
		italic_angle=None,
		license=None,
		license_url=None,
		mac_compatible=None,
		menu_name=None,
		ms_charset=None,
		nominal_width=None,
		note=None,
		notice=None,
		other_blues=None,
		panose=None,
		postscript_id=None,
		pref_family_name=None,
		pref_style_name=None,
		sample_font_text='The quick brown fox jumps over the lazy dog',
		slant_angle=None,
		source=None,
		stem_snap_h=None,
		stem_snap_v=None,
		style_name=None,
		trademark=None,
		tt_u_id=None,
		underline_position=None,
		underline_thickness=None,
		unicoderanges=None,
		upm=None,
		vendor=None,
		vendor_url=None,
		version=None,
		version_major=None,
		version_minor=None,
		vhea_vert_typo_line_gap=None,
		weight=None,
		weight_code=None,
		width=None,
		wws_family_name=None,
		wws_sub_family_name=None,
		x_height=None,
		)

	ufo.ttinfo = AttributeDict(
		head_lowest_rec_ppem=None,
		hhea_ascender=None,
		hhea_caret_offset=None,
		hhea_caret_slope_rise=None,
		hhea_caret_slope_run=None,
		hhea_descender=None,
		hhea_line_gap=None,
		os2_fs_type=None,
		os2_s_family_class=None,
		os2_s_typo_ascender=None,
		os2_s_typo_descender=None,
		os2_s_typo_line_gap=None,
		os2_selection=None,
		os2_us_win_ascent=None,
		os2_us_win_descent=None,
		os2_y_strikeout_position=None,
		os2_y_strikeout_size=None,
		os2_y_subscript_x_offset=None,
		os2_y_subscript_x_size=None,
		os2_y_subscript_y_offset=None,
		os2_y_subscript_y_size=None,
		os2_y_superscript_x_offset=None,
		os2_y_superscript_x_size=None,
		os2_y_superscript_y_offset=None,
		os2_y_superscript_y_size=None,
		vhea_caret_offset=None,
		vhea_caret_slope_rise=None,
		vhea_caret_slope_run=None,
		vhea_vert_typo_ascender=None,
		vhea_vert_typo_descender=None,
		vhea_vert_typo_line_gap=None,
		)

	fontinfo.set_attributes(ufo, instance, instance_attrs)

	# update instance vfb
	vfb.update(ufo, instance)

	# load OT prefix and feature copies from master
	instance.ot_classes = ot_classes
	for feature_tag, feature_value in ot_features:
		instance.features.append(Feature(feature_tag, feature_value))

	if masters:
		instance.full_name = bytes(f'{master_copy.family_name} {instance_name}')

	# create ufo paths
	instance_ufo_name = f'{master_copy.family_name}{master_copy.version}-{instance_name}'
	instance_ufo_filename = f"{instance_ufo_name.replace(' ', '')}.ufo"

	if ufo.path:
		instance_ufo_path = user_path(instance_ufo_filename, path=ufo.path)
	else:
		instance_ufo_path = user_path(instance_ufo_filename)

	instance_dir = os.path.dirname(instance_ufo_path)
	ufo.path = instance_dir

	if ufo.designspace.designspace:
		instance_ufo_path = os.path.join(instance_dir, 'masters', instance_ufo_filename)
		ufo.designspace.sources.append(instance_ufo_filename)

	instance_otf_path = instance_ufo_path.replace('.ufo', '.otf')
	instance_ufo_glyphs_path = user_path('glyphs', path=instance_ufo_path)
	instance_ufoz_path = instance_ufo_path.replace('.ufo', '.ufoz')
	instance_vfb_path = instance_ufo_path.replace('.ufo', '.vfb')

	if not ufo.ufoz.write:
		make_dir(instance_ufo_glyphs_path)

	plist_paths = AttributeDict(
		metainfo=os.path.join(instance_ufo_path, 'metainfo.plist'),
		fontinfo=os.path.join(instance_ufo_path, 'fontinfo.plist'),
		groups=os.path.join(instance_ufo_path, 'groups.plist'),
		kerning=os.path.join(instance_ufo_path, 'kerning.plist'),
		lib=os.path.join(instance_ufo_path, 'lib.plist'),
		layercontents=os.path.join(instance_ufo_path, 'layercontents.plist'),
		glyphs_contents=os.path.join(instance_ufo_glyphs_path, 'contents.plist'),
		glyphs_layerinfo=os.path.join(instance_ufo_glyphs_path, 'layerinfo.plist'),
		)

	prev_plist_paths = AttributeDict(
		metainfo=None,
		groups=None,
		lib=None,
		layercontents=None,
		glyphs_contents=None,
		glyphs_layerinfo=None,
		)

	ufo.instance_paths = AttributeDict(
		ufo=instance_ufo_path,
		ufoz=instance_ufoz_path,
		otf=instance_otf_path,
		vfb=instance_vfb_path,
		glyphs=instance_ufo_glyphs_path,
		features=os.path.join(instance_ufo_path, 'features.fea'),
		plists=plist_paths,
		plists_prev=prev_plist_paths,
		afdko=None,
		)

	if ufo.afdko.parts:
		afdko_path = os.path.join(ufo.path, 'afdko_parts')
		make_dir(afdko_path)
		fontnamedb = os.path.join(afdko_path, f'{instance_ufo_filename}_FontMenuNameDB')
		goadb = os.path.join(afdko_path, f'{instance_ufo_filename}_GlyphOrderAndAliasDB')
		cmd = os.path.join(afdko_path, f'{instance_ufo_filename}.cmd')
		afdko_paths = AttributeDict(
			fontnamedb=fontnamedb,
			goadb=goadb,
			cmd=cmd,
			)
		ufo.instance_paths.afdko = afdko_paths
		ufo.afdko.cmd_path = os.path.join(afdko_path, f'{master_copy.family_name}{master_copy.version}.cmd')

	ufo.instance_times = AttributeDict(
		glifs=0.0,
		fea=0.0,
		plists=0.0,
		afdko=0.0,
		)
	instance.modified = 0
	fl.UpdateFont(ufo.ifont)

# ------------------
#  file write tools
# ------------------

def write_file(path, text):

	'''
	write text to path
	'''

	with open(path, 'w', encoding='utf_8') as f:
		f.write(text + '\n')


def write_ufoz(ufo):

	'''
	create .ufoz archive
	'''

	if ufo.ufoz.compress:
		MODE = 8
	else:
		MODE = 0

	file_open_error = (f'{os.path.basename(ufo.instance_paths.ufoz)} is open.'
		'\nPlease close the file.')

	if ufo.force_overwrite:
		if os.path.exists(ufo.instance_paths.ufoz):
			try:
				os.rename(ufo.instance_paths.ufoz, ufo.instance_paths.ufoz + '__')
				os.remove(ufo.instance_paths.ufoz + '__')
			except OSError:
				raise OSError(file_open_error)

	try:
		with zipfile.ZipFile(ufo.instance_paths.ufoz, 'w', compression=MODE) as z:
			for path, contents in items(ufo.archive):
				try:
					z.writestr(path, contents)
				except UnicodeError:
					z.writestr(path, contents.encode('utf_8'))

	except IOError:
		raise IOError(f'{os.path.basename(ufo.instance_paths.ufoz)} already exists.'
			"\nPlease rename or delete the existing file, or set 'force_overwrite' to True")

	except OSError:
		raise OSError(file_open_error)

	ufo.archive = {}

# --------------------
#  file/path handlers
# --------------------

def user_path(filename_path=None, path=None, temp=False):

	'''
	create a directory path
	user's desktop is the default directory
	'''

	if temp:
		path = tempfile.gettempdir()

	if not path and not filename_path:
		return os.path.join(ENVIRON, 'Desktop')
	elif not path:
		return os.path.join(ENVIRON, 'Desktop', filename_path)
	else:
		return os.path.join(path, filename_path)


def make_dir(path):

	'''
	create a directory if it does not exist
	default to the user's desktop if path is not an absolute path
	'''

	if not os.path.isabs(path):
		path = os.path.join(ENVIRON, 'Desktop', path)

	with ignored(OSError):
		os.makedirs(path)


cpdef remove_file(path):

	'''
	remove file, ignoring race condition
	'''

	with ignored(OSError):
		os.remove(path)

# --------------
#  string tools
# --------------

def time_string(duration, precision=1, simple_output=False):

	'''
	time string from time.clock() double

	>>> time.string(4.505)
	4.5 sec
	'''

	_second_ = 'sec'
	_minute_ = 'min'
	_hour_ = 'hr'
	_microsecond_ = '\xb5sec'
	_millisecond_ = 'msec'
	_nanosecond_ = 'nsec'

	def hours_time(hours, minutes, seconds):

		# hour times

		if simple_output:
			return hours, minutes, seconds
		else:
			return f'{hours} {_hour_} {minutes} {_minute_} {seconds} {_second_}'


	def minutes_time(minutes, seconds, duration):

		# minute times

		if simple_output :
			return minutes, seconds
		else:
			return f'{minutes} {_minute_} {seconds} {_second_}'


	def seconds_time(seconds, duration):

		# short times

		str_seconds = str(duration)
		if str_seconds.count('.0000'):
			seconds = str_seconds[:str_seconds.find('.')] + '.000'
		if simple_output:
			return seconds
		else:
			return f'{seconds} {_second_}'


	def milliseconds_time(milliseconds, duration):

		# very short times

		milliseconds = int(round(milliseconds))
		if simple_output:
			return int(round(milliseconds))
		else:
			return f'{milliseconds} {_millisecond_}'


	def microseconds_time(microseconds, duration):

		# very very short times

		microseconds = int(round(microseconds))
		if simple_output:
			return int(round(microseconds))
		else:
			return f'{microseconds} {_microsecond_}'


	def nanoseconds_time(nanoseconds, duration):

		# very very very short times

		nanoseconds = int(round(nanoseconds))
		if simple_output:
			return round(duration, 9)
		else:
			return f'{nanoseconds} {_nanosecond_}'


	if 1 > duration >= 1e-9:
		milliseconds = duration * 1e3
		if 999 > milliseconds >= 1:
			return milliseconds_time(milliseconds, duration)
		else:
			microseconds = duration * 1e6
			if 999 > microseconds >= 1:
				return microseconds_time(microseconds, duration)
			else:
				nanoseconds = duration * 1e9
				if 999 > nanoseconds >= 1:
					return nanoseconds_time(nanoseconds, duration)

	if 3600 > duration >= 1:
			minutes, seconds = duration // 60, duration % 60
			if 59 > minutes >= 1:
				return minutes_time(minutes, round(seconds, precision), duration)
			else:
				seconds = round(duration, precision)
				return seconds_time(seconds, duration)

	if duration >= 3600:
		hours, minutes = duration // 3600, duration % 3600
		seconds = round(duration % 3600, precision)
		return hours_time(hours, minutes, seconds)

# ------------------
#  glyph name tools
# ------------------

cdef tuple glif_name(unicode glyph_name, bint release_mode):

	'''
	return valid glyph name and glif filename from glyph name

	>>> glif_name("a")
	a.glif
	>>> glif_name("A")
	A_.glif
	'''

	cdef:
		set invalid_characters = {
			'“', '*', '+', '/', ':', '<', '>', '?', '[', ']', '|',
			'\t', '&', '\r', '\\', '\x00', '\x01', '\x02', '\x03',
			'\x04', '\x05', '\x06', '\x07', '\x08', '\x0b', '\x0c',
			'\x0e', '\x0f', '\x10', '\x11', '\x12', '\x13', '\x14',
			'\x15', '\x16', '\x17', '\x18', '\x19', '\x1a', '\x1b',
			'\x1c', '\x1d', '\x1e', '\x1f', '\x7f',
			}
		set invalid_names = {
			'lpt1', 'lpt2', 'lpt3', 'a:-z:', 'com1', 'com2', 'com3',
			'com4', 'con', 'prn', 'aux', 'nul', 'clock$',
			}


	regex_production = re.compile('[A-Za-z_\-\+\*\:\~\^\!][A-Za-z0-9_.\-\+\*\:\~\^\!]* *$')
	regex_release = re.compile('[A-Za-z_][A-Za-z0-9_.]* *$')


	def verify_glyph_name(glyph_name, release_mode):
		if release_mode:
			if re.match(regex_release, glyph_name):
				return glyph_name
			else:
				raise GlyphNameError(f"'{glyph_name}' contains at least 1 invalid character.\n"
					"Glyph should be renamed or 'fdk_release' set to False\n"
					"Valid Type 1 spec glyph name character set:\n"
					"A-Z, a-z, 0-9, '.' (period), and '_' (underscore).")
		else:
			if re.match(regex_production, glyph_name):
				return glyph_name
			print(f"  '{glyph_name}' contains at least 1 invalid production character.\n"
				"  Valid production glyph name character set:\n"
				"  A-Z, a-z, 0-9, and [_ . - + * : ~ ^ !]")
			return glyph_name


	def check_glyph_name(glyph_name, release_mode):
		if glyph_name == '.notdef':
			return glyph_name
		try:
			_ = glyph_name.encode('ascii')
		except UnicodeError:
			raise GlyphNameError(f"'{glyph_name}' contains non-ASCII character(s).")

		if verify_glyph_name(glyph_name, release_mode):
			return glyph_name

	glyph_name = check_glyph_name(glyph_name, release_mode)

	if glyph_name in invalid_names:
		glyph_name = f'_{glyph_name}'

	glif_filename = ''
	for character in glyph_name:
		if character in invalid_characters:
			glif_filename += '_'
		elif character.isupper():
			glif_filename += character + '_'
		else:
			glif_filename += character

	if glif_filename[0] == '.':
		glif_filename = f'_{glif_filename[1:]}'

	if glif_filename.count('.'):
		glif_filename_list = glif_filename.split('.')
		for i, name in enumerate(glif_filename_list):
			if name in invalid_names:
				glif_filename[i] = '_' + name
		glif_filename = '.'.join(glif_filename_list)

	return glyph_name, f'{glif_filename[:250]}.glif'

cdef check_glyph_unicodes(object font):

	cdef:
		list unicodes = []
		dict unicode_errors = {}

	for glyph in font.glyphs:
		for unicode in glyph.unicodes:
			if unicode not in unicodes:
				unicodes.append(glyph.unicode)
			else:
				if unicode in unicode_errors:
					unicode_errors[unicode].append(str(glyph.name))
				else:
					unicode_errors[unicode] = [str(glyph.name)]

	if unicode_errors:
		message = []
		for unicode, glyphs in items(unicode_errors):
			message.append(f"'{uni_transform(unicode)}' is mapped to more than one glyph:")
			for glyph in glyphs:
				message.append(f'  {glyph}')

		raise GlyphUnicodeError('\n'.join(message))
