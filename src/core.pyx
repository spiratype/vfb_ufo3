# coding: utf-8
# cython: wraparound=False
# cython: boundscheck=False
# cython: infer_types=True
# cython: cdivision=True
# cython: auto_pickle=False
# cython: c_string_type=unicode
# cython: c_string_encoding=utf_8
# distutils: language=c++
# distutils: extra_compile_args=[-O2, -Wno-register, -fno-strict-aliasing, -std=c++17]
from __future__ import division, unicode_literals, print_function
include 'includes/future.pxi'

cimport cython
from cpython.dict cimport PyDict_SetItem
from cpython.set cimport PySet_Add
from libcpp.string cimport string

import linecache
import os
import shutil
import stat
import threading
import time
import uuid

from . import fea, vfb
from .designspace import designspace
from .fdk import fdk
from .fea import features
from .glif import glifs
from .groups import groups
from .plist import plists
from .tools import finish
from .user import load_encoding, save_encoding
from .vfb import add_instance

from FL import fl, Font, Rect

include 'includes/thread.pxi'
include 'includes/path.pxi'
include 'includes/unique.pxi'
include 'includes/dict.pxi'
include 'includes/attribute_dict.pxi'
include 'includes/ordered_set.pxi'
include 'includes/options.pxi'
include 'includes/defaults.pxi'
include 'includes/core.pxi'

def write_ufo(options):

	ufo = parse_options(options)
	copy_master_info(ufo)

	for instance in ufo.instances:

		add_instance(ufo, *instance)
		glifs(ufo)
		plists(ufo)
		features(ufo)

		if ufo.opts.ufoz:
			ufo.archive.write()

		if ufo.opts.afdko_parts or ufo.opts.psautohint_cmd:
			fdk(ufo)

		finish(ufo, instance=1)

	if ufo.opts.designspace_export:
		designspace(ufo)

	finish(ufo)


def parse_options(options):

	'''
	parse and check user options
	'''

	fl.output = b''

	if not len(fl):
		raise UserWarning(b'No open fonts')

	start = time.clock()
	ufo = attribute_dict(UFO_BASE)
	ufo.start = 1
	ufo.last = 0
	ufo.instance.completed = 0
	ufo.total_times.start = start
	ufo.paths.encoding = unique_path('__temp__.enc', 1)

	print(b'Processing user options..\n')
	ufo.master.ifont = fl.ifont
	master = fl[fl.ifont]

	options = check_instance_lists(options, master)
	ufo.opts = opts = option_dict()
	opts.update(options)

	dirname, basename = os_path_split(master.file_name)
	filename, ext = os_path_splitext(basename)
	if not basename.endswith('.vfb'):
		save_path = unique_path(f'{filename}.vfb', 1)
		master.Save(save_path.encode('cp1252'))

	ufo.master.filename = basename
	ufo.master.dirname = os_path_normpath(dirname)
	ufo.master.family_name = master.family_name.decode('cp1252')
	ufo.master.version_major = master.version_major
	ufo.master.version_minor = master.version_minor
	ufo.master.version = f'{master.version_major}.{master.version_minor:>03}'
	ufo.master.axes_names = [str(axis[0]) for axis in master.axis]
	ufo.master.axes_names_short = [str(axis[1]) for axis in master.axis]
	ufo.master.upm = master.upm
	ufo.master.font_style = master.font_style
	fea.copy_opentype(ufo, master)
	save_encoding(ufo, master)

	ufo.paths.out = opts.output_path if opts.output_path else DESKTOP

	if opts.scale_to_upm != master.upm or opts.scale_auto:
		if opts.scale_to_upm >= 1000:
			ufo.scale = opts.scale_to_upm / master.upm

	if not opts.scale_auto:
		opts.scale_to_upm = master.upm
		ufo.scale = None

	if not master.axis:
		ufo.instance_from_master = 1
		opts.designspace_export = 0

	if opts.designspace_export:
		set_designspace_values(ufo, master)

	if opts.layer and master.axis:
		if opts.layer not in range(2 ** len(master.axis) - 1):
			raise IndexError(
				b"Provided layer index is greater than the number of available layers.\n"
				b"'%s' has %d layers(s)" % (repr(master), 2 ** len(master.axis))
				)

	if opts.instance_values:
		set_instance_values(ufo)
	else:
		if opts.layer is not None:
			set_master_values(ufo, master, layer=opts.layer)
		else:
			set_master_values(ufo, master)

	if opts.mark_anchors_include:
		opts.mark_anchors_include = encode_string_list(opts.mark_anchors_include)
		opts.mark_anchors_omit = None
	elif opts.mark_anchors_omit:
		opts.mark_anchors_omit = encode_string_list(opts.mark_anchors_omit)
		opts.mark_anchors_include = None

	if opts.kern_feature_file_path:
		if opts.kern_feature_file_path.endswith('.fea'):
			check_user_file(opts.kern_feature_file_path, 'kern')
		ufo.paths.kern_feature = opts.kern_feature_file_path

	if opts.groups_flc_path:
		if opts.groups_flc_path.endswith('.flc'):
			check_user_file(opts.groups_flc_path, 'flc')
		ufo.paths.flc = opts.groups_flc_path

	if opts.groups_export_flc_path:
		if os_path_isfile(opts.groups_export_flc_path) and not opts.force_overwrite:
			raise RuntimeError(b'%s already exists.\nPlease rename or move existing '
				b".flc file or set 'force_overwrite to True." % opts.groups_export_flc_path)

	if opts.groups_plist_path:
		if os_path_basename(opts.groups_plist_path).endswith('groups.plist'):
			ufo.paths.groups_plist = opts.groups_plist_path

	if opts.afdko_parts:
		if opts.designspace_export:
			raise RuntimeError(b"'designspace_export' not currently supported for use with 'afdko_parts'.")
		if opts.afdko_makeotf_args:
			opts.afdko_makeotf_args = unique_string_list(opts.afdko_makeotf_args)
		if opts.afdko_makeotf_sans:
			opts.afdko_makeotf_serif = 0
		if opts.afdko_makeotf_batch_cmd:
			ufo.afdko.makeotf.cmd = []
			ufo.paths.afdko.makeotf_cmd = os_path_join(ufo.paths.out, f'{filename}_makeOTF.bat')
		if opts.afdko_makeotf_GOADB_path:
			ufo.paths.GOADB = opts.afdko_makeotf_GOADB_path
		else:
			ufo.paths.GOADB = os_path_join(TEMP, 'GOADB')

	if opts.psautohint_cmd or opts.psautohint_batch_cmd:
		if opts.designspace_export:
			raise RuntimeError(b"'designspace_export' not currently supported for use with 'psautohint_cmd'.")
		if opts.psautohint_batch_cmd:
			ufo.psautohint.cmd = []
			ufo.paths.psautohint_cmd = os_path_join(ufo.paths.out, f'{filename}_psautohint.bat')
		if opts.psautohint_glyphs_list:
			glyph_list = opts.psautohint_glyphs_list
			opts.psautohint_glyphs_list = unique_string_list(glyph_list)
			opts.psautohint_glyphs_omit_list = []
		if opts.psautohint_glyphs_omit_list:
			glyph_list = opts.psautohint_glyphs_omit_list
			opts.psautohint_glyphs_omit_list = unique_string_list(glyph_list)

	if not opts.glyphs_decompose:
		opts.glyphs_optimize = 0

	if opts.glyphs_optimize_names:
		opts.glyphs_optimize_names = encode_string_list(opts.glyphs_optimize_names)

	if opts.glyphs_omit_suffixes:
		opts.glyphs_omit_suffixes = tuple(encode_string_list(opts.glyphs_omit_suffixes))

	if opts.glyphs_omit_names:
		opts.glyphs_omit_names = encode_string_list(opts.glyphs_omit_names)

	if opts.glyphs_optimize:
		if opts.glyphs_optimize_code_points:
			ufo.code_points.optimize = parse_code_points(opts.glyphs_optimize_code_points)
		else:
			ufo.code_points.optimize = OPTIMIZE_CODE_POINTS

	return ufo

def unique_string_list(user_list):
	return [string for string in set(user_list) if isinstance(string, basestring)]

def unique_list(user_list, ordered=0):
	if ordered:
		return list(ordered_set(user_list))
	return list(set(user_list))

def encode_string_list(string_list):
	return {encoded(string) for string in unique_string_list(string_list)}

def decode_string_list(string_list):
	return {decoded(string) for string in unique_string_list(string_list)}

def parse_code_points(code_point_list):

	'''
	verify user code point list and convert to a set

	an attempt will be made to convert string code point entries to integers;
	malformed entries unable be casted to an integer will raise a ValueError;
	users are expected to provide correct input values
	'''

	code_points = set()
	for code_point in code_point_list:
		try:
			if isinstance(code_point, int):
				code_points.add(code_point)
			elif isinstance(code_point, basestring):
				code_points.add(int(code_point, 16))
		except ValueError as e:
			raise ValueError(b"'%s' could not be converted to an integer.\n%s"
				 % (code_point, e.message))

	return code_points

def copy_master_info(ufo):

	'''
	add a copy of the user's master font and begin build process
	'''

	def font_repr(font):
		filename = os_path_basename(font.file_name)
		fullname = font.full_name
		if font.axis:
			axes = len(font.axis)
			return f'<Font: {fullname!r} filename={filename!r} axes={axes}>'
		return f'<Font: {fullname!r} filename={filename!r}>'

	master = fl[ufo.master.ifont]

	if ufo.opts.report:
		print(f'Processing {font_repr(master)}..\n')

	print(b' Processing master..')

	if ufo.opts.afdko_makeotf_release:
		vfb.check_glyph_unicodes(master)

	vfb.process_master(ufo, master)

	groups(ufo)

	if ufo.opts.afdko_parts:
		vfb.build_goadb(ufo, master)

def build_paths(ufo, master=0):

	'''
	build and check paths for output
	'''

	paths = []
	if master:
		base_filename = ufo.master.filename.replace('.vfb', '')
	else:
		base_filename = ufo.master.family_name

	for name in ufo.instance_names:
		filename = f'{base_filename}-{name}' if name else base_filename
		filename = filename.replace(' ', '')
		ufo_filename = f'{filename}.ufo'
		ufoz_filename = f'{filename}.ufoz'
		vfb_filename = f'{filename}.vfb'

		if ufo.opts.designspace_export:
			ufo_path = os_path_join(ufo.paths.out, 'masters', ufo_filename)
			ufoz_path = os_path_join(ufo.paths.out, 'masters', ufoz_filename)
		else:
			ufo_path = os_path_join(ufo.paths.out, ufo_filename)
			ufoz_path = os_path_join(ufo.paths.out, ufoz_filename)

		check_paths = [ufoz_path] if ufo.opts.ufoz else [ufo_path]

		if ufo.opts.vfb_save:
			check_paths.append(os_path_join(ufo.paths.out, vfb_filename))

		for path in check_paths:
			if os_path_exists(path):
				if not ufo.opts.force_overwrite:
					raise IOError(b"%s already exists.\nPlease remove directory/file "
						b"or set 'force_overwrite' to True" % path)
			if 'masters' in path:
				dirname = os_path_dirname(path)
				if not os_path_isdir(dirname):
					os_makedirs(dirname)

		paths.append(ufo_path)

	return paths


def master_instances(font, layer=None):

	'''
	build master values, names, and attributes for building master instances or
	an individual layer

	>>> font = fl.font
	>>> font.axis
	[('Weight', 'Wt', 'Weight')]
	>>> master_instances(font)
	([0, 1000], ['Wt0', 'Wt1'], [{'styleName': 'Wt0'}, {'styleName': 'Wt1'}])
	>>> master_instances(font, layer=0)
	([0], ['Wt0'], [{'styleName': 'Wt0'}])
	'''

	j, k = len(font.axis), 2 ** len(font.axis)

	shorts = [[str(axis[1]) for axis in font.axis] for i in range(k)]
	axes = [axis for axis in zip(*MATRIX)][:k]

	values = [[i * 1000 for i in axis][:j] for axis in axes]

	names = [''.join(f'{short_name[i]}{axis[i]}' for i in range(j))
		for short_name, axis in zip(shorts, axes)]

	attributes = [{'styleName': name} for name in names]

	if layer is not None:
		return [values[layer]], [names[layer]], [attributes[layer]]
	return values, names, attributes


def check_designspace_default(ufo, master):

	'''
	verify user-supplied designspace default instance
	'''

	len_error = b'.designspace default instance length must match the source font axis length.'
	val_error = b'.designspace default instance values must be numeric.'
	if ufo.opts.designspace_default:
		if len(ufo.opts.designspace_default) != len(master.axis):
			raise ValueError(len_error)
		for val in ufo.opts.designspace_default:
			if not isinstance(val, (int, float)):
				raise ValueError(val_error)
		ufo.designspace.default = ufo.opts.designspace_default


def set_designspace_values(ufo, master):

	'''
	copy user-supplied instance variables as designspace variables and
	create instance variables to build UFOs for each master
	'''

	check_designspace_default(ufo, master)

	ufo.designspace.values = values = ufo.opts.instance_values[:]
	ufo.designspace.names = names = ufo.opts.instance_names[:]
	ufo.designspace.attributes = attributes = ufo.opts.instance_attributes[:]
	ufo.designspace.default = ufo.opts.designspace_default[:]
	set_designspace_glyphs_omit(ufo, master)
	ufo.opts.instance_values = []
	ufo.opts.instance_names = []
	ufo.opts.instance_attributes = []
	ufo.opts.glyphs_omit_names = []
	ufo.opts.glyphs_omit_suffixes = ()
	set_master_values(ufo, master, designspace=1)
	ufo.designspace.instances = zip(values, names, attributes)
	filename = ufo.master.filename.replace('.vfb', '.designspace')
	ufo.paths.designspace = os_path_join(ufo.paths.out, filename)


def set_designspace_glyphs_omit(ufo, master):

	if not (ufo.opts.glyphs_omit_names or ufo.opts.glyphs_omit_suffixes):
		ufo.designspace.glyphs_omit = []
		return

	glyphs_omit_names = encode_string_list(ufo.opts.glyphs_omit_names)
	glyphs_omit_suffixes = encode_string_list(ufo.opts.glyphs_omit_suffixes)
	glyphs_omit = set()
	for i, glyph in enumerate(master.glyphs):
		if glyph.name in glyphs_omit_names:
			glyphs_omit.add(glyph.name.decode('cp1252'))
		if b'.' in glyph.name:
			for suffix in glyphs_omit_suffixes:
				if glyph.name.endswith(suffix):
					glyphs_omit.add(glyph.name.decode('cp1252'))
					break

	ufo.designspace.glyphs_omit = list(sorted(glyphs_omit))


def set_master_values(ufo, master, layer=None, designspace=0):

	'''
	create instance variables to build UFOs for each master
	'''

	values, names, attributes = master_instances(master, layer)

	ufo.instance_values = values
	ufo.instance_names = names
	ufo.instance_attributes = attributes
	ufo.opts.features_kern_feature_generate = 0
	ufo.build_masters = 1
	ufo.instance_paths = paths = build_paths(ufo, master=1)
	ufo.instances = zip(range(len(values)), values, names, attributes, paths)
	if designspace:
		ufo.designspace.sources = zip(values, names, attributes, paths)


def set_instance_values(ufo):

	'''
	set user-supplied instance variables
	'''

	ufo.instance_values = values = ufo.opts.instance_values
	ufo.instance_names = names = ufo.opts.instance_names
	ufo.instance_attributes = attributes = ufo.opts.instance_attributes
	ufo.instance_paths = paths = build_paths(ufo)
	ufo.instances = zip(range(len(values)), values, names, attributes, paths)


def show_default_optimize_code_points():

	'''
	user convenience function to print the OPTIMIZE_CODE_POINTS code point set to
	the FontLab output window
	'''

	code_points = list(sorted(OPTIMIZE_CODE_POINTS))

	code_points = [[f'0x{code_points[i+j]:04x},'
		for j in range(8) if i + j < len(code_points)]
		for i in range(0, len(code_points), 8)]
	code_points = '\n'.join(f'\t{" ".join(line)}' for line in code_points)

	print(f'OPTIMIZE_CODE_POINTS = \n{code_points}n\t')


def check_instance_lists(options, master):

	'''
	check user-supplied instance variables and reset options if font is not
	multiple master
	'''

	if not master.axis:
		options['instance_values'] = []
		options['instance_names'] = []
		options['instance_attributes'] = []
		return options

	if not options['instance_values']:
		options['instance_names'] = []
		options['instance_attributes'] = []
		return options

	return check_instance_values(options, master)


def check_instance_values(options, master):

	'''
	check each user-supplied option for multiple master fonts
	'''

	min_len = len(master.axis)
	len_error_msg = (
		f"Values from a list of 'instance_values' must be "
		f'lists or tuples equal in length to the # of source font axes.\n'
		f'<Font {master.family_name}> has {min_len} axe(s)'
		).encode('cp1252')

	# check instance options
	user_instance_options = [options[option]
		for option in INSTANCE_OPTIONS if options[option]]

	if options['designspace_export'] and options['designspace_default']:
		if len(options['designspace_default']) != min_len:
			raise ValueError(
				b"'designspace_default' must be a list of values "
				b'equal in length to the # of source font axes.\n'
				b'<Font %s> has %d axe(s)' % (master.family_name, min_len)
				)

	# check lengths of names and attributes against length of values
	try:
		user_values_len = len(options['instance_values'])
	except TypeError as e:
		raise TypeError(
			b"'instance_values' must be a list or tuple of values\n%s" % e.message
			)

	for option in user_instance_options:
		if len(option) != user_values_len:
			raise ValueError(
				b"'instance_values', 'instance_names', and 'instance_attributes'\n"
				b" options must be lists or tuples of the same length"
				)

	# check instance values list; convert to list of lists/tuples
	user_instance_values = []
	for values in options['instance_values']:

		if isinstance(values, (list, tuple)):
			if len(values) != min_len:
				raise ValueError(len_error_msg)

		try:
			if len(values) != min_len:
				raise ValueError(len_error_msg)
		except TypeError as e:
			if min_len != 1:
				raise TypeError(f'{len_error_msg}\n{e.message}')

		if not isinstance(values, (list, tuple)):
			user_instance_values.append([values])
		else:
			user_instance_values.append(values)

	options['instance_values'] = user_instance_values[:]
	return options


def check_user_file(path, file_type):

	'''
	check the first line of a user-supplied file path for quasi-correctness
	'''

	if FILE_HEADERS[file_type] not in linecache.getline(path, 1):
		raise ValueError(FILE_HEADER_ERRORS[file_type])
