# coding: utf-8
from __future__ import (absolute_import, division, print_function,
	unicode_literals)

from vfb2ufo import fdk

from vfb2ufo.fea import features
from vfb2ufo.glif import glifs
from vfb2ufo.plist import plists
from vfb2ufo.designspace import designspace

from vfb2ufo.tools import (AttributeDict, add_master_copy, add_instance,
	master_names_values, report_log, write_ufoz)
from vfb2ufo.future import items, open, range, str, zip

from FL import fl

__version__ = '0.1.0'

__doc__ = '''
DESCRIPTION
Multiple master-compatible UFO writer API for Windows FontLab 5.2

VFB2UFO3 is primarily intended to create scaled UFOs from a > 1000 upm
multiple master VFB font. Hinting output is optional; as of psautohint v1.7,
psautohint rounds all coordinates to integers, negating the lossless scaling
performed during UFO creation. The most significant non-trivial change that
will occur in export is the renaming of kerning glyph groups ('classes' in
FontLab). See KERN GROUP OPTIONS below.

REQUIREMENTS
This module is written in Python 3 syntax where and whenever possible. The
submodules are written in Cython and compiled into .pyd extension modules.
To recompile the submodules, PyPi packages 'future_fstrings' and 'cython' will
need to be installed. It is suggested to install the <optional> modules.

  <optional>
  future_fstrings (pip install future_fstrings)
  AFDKO (pip install afdko)

FUNCTIONALITY
UFO output is produced without changes to the source font. A copy will be
created and the UFO will be processed from the copy. If the font is multiple
master, instances will be generated from the copy. In the multiple master-
use case, if 'instance_values' or a specific master layer is not provided, a
UFO will be generated for each master in the font. The generated instances/
layers can be saved and/or left open after generation via the 'vfb_save' and
'vfb_close' arguments. If an output path is provided, it must be an absolute
path, otherwise the output will be saved to the user's Desktop. A dictionary
of attributes may be suppled via the 'instance_attributes' argument. These
attributes should consist of keys from the UFO specification and they must
match the data type in the specification. If it is a scalable font metric and
the font is being scaled, the unscaled value should be supplied. Any attribute
in the dictionary will be updated in the generated vfb instance if it is
mappable to a FontLab attribute.

------------------------------------------------------------------------------
EXAMPLE UFO GENERATION SCRIPT
------------------------------------------------------------------------------

#FLM: write ufo
# coding: utf-8

import os

from vfb2ufo import write_ufo

path = os.path.join('C:', 'Users', 'username', 'Documents', 'fonts')

font = fl.font

instances = [
	[0],
	[200],
	[400],
	[650],
	[1000],
	]
names = [
	['Thin'],
	['Light'],
	['Regular'],
	['SemiBold'],
	['Bold'],
	]
attributes = [
	{'openTypeOS2WeightClass': 200},
	{'openTypeOS2WeightClass': 300},
	{'openTypeOS2WeightClass': 400},
	{'openTypeOS2WeightClass': 600},
	{'openTypeOS2WeightClass': 700},
	]

write_ufo(
	font,
	path=path,
	instance_values=instances,
	instance_names=names,
	instance_attributes=attributes,
	decompose_glyphs=True,
	remove_glyph_overlaps=True
	)

------------------------------------------------------------------------------

OPTIONS
Lossless glyph scaling
Compressed UFO output (direct-to-disk UFOZ)
features.fea table additions (AFDKO)
MakeOTF parts/batch command (AFDKO)
OpenType and kerning group import to features.fea

KERNING OPTIONS
Kern values will be scaled in parity with the output UFO. The values will
be changed in the generated vfb instance during generation and reverted if
the vfb is being saved.

KERN FEATURE OPTIONS
A feature file with the 'kern' feature can be imported to the font features
using the 'features_kern_feature_file' argument, which expects a path to a
text file with the .fea extension. The 'features_kern_feature_omit' and
'features_kern_feature_passthrough' arguments allow for 'kern' feature
omission and 'kern' feature pass-through, respectively. A new 'kern'
feature can be generated setting 'features_kern_feature_generate' to True.
The 'kern' feature generation utilises FontLab's MakeKernFeature() command
with additional subtables and a lookup as necessary. This is not particularly
elegant, and no checks are made to guarantee a working 'kern' feature. Any
remaining subtable overflows may be due to glyph(s) being in more than one
kern group of the same side, however overflows can also be caused by issues
from one or more GPOS features located earlier in the feature list.

GROUP OPTIONS
Optionally, a FontLab-class file (.flc) or groups.plist may be provided. Group
names will be normalized to match the UFO3 kern group naming scheme. If the
imported groups.plist contains kern group names that do not follow the @MMK-
or public.kern- prefixes, or the key glyphs from the imported .flc file do not
match the master font key glyphs, the font's kerning will very likely no longer
remain functional. Providing a FontLab-class file or groups.plist file is
considerably faster than using FontLab's builtin methods.

Setting the 'export_flc' argument to True will produce an .flc file on the
desktop that matches the group names of the generated UFOs.

KERN GROUP OPTIONS
For portability and uniformity, kerning glyph groups will be renamed to match
the UFO3 specification for both UFO2 and UFO3 exports. Combined left/right
FL classes will be split into separate groups.

If there are any FL kern classes without a key glyph in a provided .flc file
or in the master font's kern classes, the first glyph in the FL class will be
marked as the key glyph and it will be noted in the output console. This may
affect the kerning.

  Kern group naming recommendations
  ---------------------------------
  FontLab-style kerning groups:
  _A_l: A' Agrave Aacute Acircumflex Atilde Adieresis Aring...
  _A_r: A' AE Agrave Aacute Acircumflex Atilde Adieresis Aring...

  Working output:
  _public.kern1.A: A' Agrave Aacute Acircumflex Atilde Adieresis Aring...
  _public.kern2.A: A' AE Agrave Aacute Acircumflex Atilde Adieresis Aring...

  Final output:
  <key>public.kern1.A</key>
  array>
    <string>A</string>
    <string>Agrave</string>
    <string>Aacute</string>
    <string>Acircumflex</string>
    <string>Atilde</string>
    <string>Adieresis</string>
    <string>Aring</string>
    ...
  </array>

  <key>public.kern2.A</key>
  <array>
    <string>A</string>
    <string>AE</string>
    <string>Agrave</string>
    <string>Aacute</string>
    <string>Acircumflex</string>
    <string>Atilde</string>
    <string>Adieresis</string>
    <string>Aring</string>
    ...
  </array>

GLYPH OPTIONS
Glyph decomposition and overlap removal is optional and occurs after instances
are generated. This option is intended for final output when a binary font will
be created from the UFO.

  Omit glyphs from instance
  -------------------------
  A list of glyph names and/or glyph suffixes can be supplied that should be
  omitted from the instance UFO via the 'glyphs_omit_list' and
  'glyphs_omit_suffixes_list' arguments.

HINTING OPTIONS
All glyph hints may be omitted by setting 'hints_ignore' to True and vertical
hints may be omitted by setting 'hints_ignore_vertical' to True. All hint
operations occur after glyph decomposition/overlap removal (if they are set).
Glyph links are converted to hints after instance generation. If vertical hints
were in the original hint replacement list, the replacement list is reset by
FontLab during removal. FontLab's builtin hint replacement can be run during
generation by setting 'hints_autoreplace' to True. Setting 'hints_afdko' to
True will build hints compatible with MakeOTF.

AFDKO OPTIONS
GlyphOrderAndAliasDB (GOADB) and FontMenuNameDB files can be generated for use
with MakeOTF. The GOADB can be generated using a provided GOADB file path,
derived from the FL font's encoding, or the order of the source font.
Optionally, the first 256 characters can be filled from the Windows 1252 or
Mac OS Roman codepages. The first character of a generated GOADB file will
always start with the '.notdef' glyph. The OS/2, hhea, head, and name
tables will be added to the features file. If a GOADB file is provided, it
is not checked for correctness. A batch command to run MakeOTF for each
generated instance or all instances using the arguments 'afdko_makeotf_cmd'
and 'afdko_makeotf_batch_cmd', respectively.

  FDK arguments
  -------------
  There are several explicit keyword agruments to enable specific makeotf
  switches. For those not available via a keyword agrument, they should be
  defined as a list of strings and passed to the 'afdko_args' argument.

UFOZ OPTIONS
UFOs can be written as a .ufoz archive. By default, the archive is written in
compressed mode. Setting 'ufoz_compress' to False will write an uncompressed
.ufoz.

DESIGNSPACE FONT OPTIONS
A .designspace document can be created in lieu of individual instances. A UFO
for each master will be generated and the instances will be described in the
.designspace document.

NOTES
Generally, no assumptions are made about the correctness of the input. Glyph
name errors are noted in the output window. In the case of 'afdko_release'
mode, glyph name errors will raise an exception and UFO generation will not
continue. Other errors in font will likely be passed through to the UFO.

AUTHOR
Jameson R Spires - jameson@spiratype.com

VERSION HISTORY
version 0.1.0
initial release

MIT LICENSE
© 2018 Jameson R Spires

Permission is hereby granted, free of charge, to any person obtaining a
copy of this software and associated documentation files (the "Software"),
to deal in the Software without restriction, including without limitation
the rights to use, copy, modify, merge, publish, distribute, sublicense,
and/or sell copies of the Software, and to permit persons to whom the
Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included
in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
DEALINGS IN THE SOFTWARE.

https://opensource.org/licenses/MIT
'''

def write_ufo(
	font,
	path=None,
	version=3,

	layer=None,

	scale_auto=False,
	scale_factor=None,

	instance_values=[],
	instance_names=[],
	instance_attributes=[],

	features_import_groups=True,
	features_kern_feature_omit=False,
	features_kern_feature_passthrough=False,
	features_kern_feature_generate=True,
	features_kern_feature_file=None,

	groups_ignore_kern_groups_with_no_kerning=False,
	groups_export_flc=False,
	groups_import_flc_path=None,
	groups_import_groups_plist_path=None,

	afdko_parts=False,
	afdko_makeotf_cmd=False,
	afdko_makeotf_batch_cmd=False,
	afdko_makeotf_GOADB_path=None,
	afdko_makeotf_GOADB_win1252=True,
	afdko_makeotf_GOADB_macos_roman=False,
	afdko_makeotf_release=False,
	afdko_makeotf_subroutinization=True,
	afdko_makeotf_no_subroutinization=False,
	afdko_makeotf_sans=False,
	afdko_makeotf_serif=False,
	afdko_makeotf_replace_notdef=False,
	afdko_makeotf_verbose=False,
	afdko_makeotf_addDSIG=True,
	afdko_makeotf_suppress_unhinted_glyph_warnings=True,
	afdko_makeotf_suppress_width_optimization=True,
	afdko_makeotf_args=[],

	glyphs_decompose=False,
	glyphs_remove_overlaps=False,
	glyphs_omit_names_list=[],
	glyphs_omit_suffixes_list=[],

	hints_ignore=False,
	hints_ignore_vertical=False,
	hints_autoreplace=False,
	hints_ignore_replacements=False,
	hints_afdko=False,

	ufoz=False,
	ufoz_compress=True,

	designspace_export=False,
	designspace_default=[],

	vfb_save=False,
	vfb_close=True,

	force_overwrite=False,
	report=True,
	):

	# ------------
	#  pre-flight
	# ------------

	# check ufo version input
	if version not in (2, 3):
		raise UserWarning('Only UFO versions 2 and 3 are supported')

	# turn off kern groups rename if .flc file is provided
	kern_groups_rename = True
	if groups_import_flc_path or groups_import_groups_plist_path:
		if groups_import_flc_path:
			if not groups_import_flc_path.endswith('.flc'):
				raise UserWarning("FontLab-class file must end with the '.flc' file extension")
		if groups_import_groups_plist_path:
			if not groups_import_groups_plist_path.endswith('.plist'):
				raise UserWarning("Groups plist file must end with the '.plist' file extension")
		kern_groups_rename = False

	# check provided kern feature file
	if features_kern_feature_file:
		if not features_kern_feature_file.endswith('.fea'):
			raise UserWarning("Kern feature must end with the '.fea' file extension")

	if features_kern_feature_generate:
		features_kern_feature_passthrough = False
		features_kern_feature_omit = False

	# check fdk arguments
	if afdko_parts:
		if afdko_makeotf_args:
			if isinstance(afdko_makeotf_args, tuple):
				afdko_makeotf_args = list(afdko_makeotf_args)
			if not isinstance(afdko_makeotf_args, list):
				raise UserWarning("'afdko_makeotf_args' must be a tuple or list")
			for arg in afdko_makeotf_args:
				if not isinstance(arg, (bytes, unicode)):
					raise UserWarning("'afdko_makeotf_args' must be a list of strings")
				if not arg.startswith('-'):
					raise UserWarning("Arguments in the 'afdko_makeotf_args' must contain strings beginning with '-'")
			afdko_makeotf_args = [str(arg) if isinstance(arg, bytes) else arg
				for arg in afdko_makeotf_args]

	if afdko_makeotf_no_subroutinization:
		afdko_makeotf_subroutinization = False
		afdko_makeotf_release = False

	if afdko_makeotf_GOADB_path:
		if isinstance(afdko_makeotf_GOADB_path, bytes):
			afdko_makeotf_GOADB_path = str(afdko_makeotf_GOADB_path)
		if not isinstance(afdko_makeotf_GOADB_path, unicode):
			raise UserWarning("'afdko_makeotf_GOADB_path' must be string")

	# check for conflicting scale_auto and scale_factor arguments
	if scale_auto and scale_factor:
		raise UserWarning("'auto_scale' and 'scale_factor' are mutually exclusive\n"
			"Please re-run with only one of these arguments")

	if scale_factor is None:
		scale_factor = 0.0

	# set auto scale factor for 1000 upm output
	upm = font.upm
	if scale_auto:
		if font.upm != 1000:
			scale_factor = 1000 / font.upm
	if scale_factor:
		upm = int(round(font.upm * scale_factor))

	# verify glyphs omit list type
	if glyphs_omit_names_list or glyphs_omit_suffixes_list:
		if glyphs_omit_names_list:
			glyphs_omit_names_list = set(glyphs_omit_names_list)
		if glyphs_omit_suffixes_list:
			glyphs_omit_suffixes_list = set(glyphs_omit_suffixes_list)

	if designspace_export:
		if not len(font.axis):
			raise UserWarning('Font must be a multiple-master font to build a'
				' .designspace document')
		else:
			if designspace_default:
				if len(designspace_default) != len(font.axis):
					raise UserWarning("designspace_default instance must be the same"
						"length as the font's axis")
			else:
				designspace_default = [0] * len(font.axis)
		designspace_values = instance_values
		designspace_names = instance_names
		designspace_attrs = instance_attributes
		afdko_parts = False

	# check for instance_values, instance_names, and instance_attributes
	if instance_values or instance_names or instance_attributes:
		if instance_values and instance_names:
			# check instance_values and instance_names sequences for matching lengths
			if len(instance_values) != len(instance_names):
				raise UserWarning('The instance_values and instance_names lists'
					' must be of the same length')
		if instance_values and instance_attributes:
			if len(instance_values) != len(instance_attributes):
				raise UserWarning('The instance_values and instance_attributes lists'
					' must be of the same length')

	# set up instance values and names for master layer instance generation
	masters = False
	master_values, master_names = master_names_values(font)
	if not instance_values or designspace_export:
		if len(font.axis):
			instance_values, instance_names = master_values, master_names
		if layer is not None:
			instance_values, instance_names = master_values[layer], master_names[layer]
		masters = True

	# normalize instance_values and instance_names lists to lists of lists
	if instance_values and instance_names:
		layer = None
		instance_values = [list(value)
			if not isinstance(value, (list, tuple)) else value
			for value in instance_values]
		instance_names = [list(name)
			if not isinstance(value, (list, tuple)) else name
 			for name in instance_names]

	if not instance_attributes:
		instance_attributes = [{} for i in range(len(instance_values))]

	build_hints = True
	if hints_ignore:
		build_hints = False

	# wrap ufo arguments
	scale_args = AttributeDict(
		auto=int(scale_auto),
		factor=float(scale_factor),
		)

	features_args = AttributeDict(
		omit_kern=int(features_kern_feature_omit),
		passthrough_kern=int(features_kern_feature_passthrough),
		import_groups=int(features_import_groups),
		generate_kern=int(features_kern_feature_generate),
		)

	groups_args = AttributeDict(
		export_flc=int(groups_export_flc),
		import_flc_path=groups_import_flc_path,
		import_groups_plist_path=groups_import_groups_plist_path,
		)

	afdko_args = AttributeDict(
		parts=int(afdko_parts),
		GOADB_path=afdko_makeotf_GOADB_path,
		GOADB_win1252=int(afdko_makeotf_GOADB_win1252),
		GOADB_macos_roman=int(afdko_makeotf_GOADB_macos_roman),
		makeotf_cmd=int(afdko_makeotf_cmd),
		makeotf_batch_cmd=int(afdko_makeotf_batch_cmd),
		makeotf_release=int(afdko_makeotf_release),
		makeotf_subroutinization=int(afdko_makeotf_subroutinization),
		makeotf_no_subroutinization=int(afdko_makeotf_no_subroutinization),
		makeotf_sans=int(afdko_makeotf_sans),
		makeotf_serif=int(afdko_makeotf_serif),
		makeotf_replace_notdef=int(afdko_makeotf_replace_notdef),
		makeotf_verbose=int(afdko_makeotf_verbose),
		makeotf_addDSIG=int(afdko_makeotf_addDSIG),
		makeotf_suppress_unhinted_glyph_warnings=int(afdko_makeotf_suppress_unhinted_glyph_warnings),
		makeotf_suppress_width_optimization=int(afdko_makeotf_suppress_width_optimization),
		makeotf_args=afdko_makeotf_args,
		)

	kern_args = AttributeDict(
		feature_file=features_kern_feature_file,
		groups_rename=int(kern_groups_rename),
		ignore_groups_with_no_kerning=int(groups_ignore_kern_groups_with_no_kerning),
		kerning_scaled=0,
		first_prefix='public.kern1.',
		second_prefix='public.kern2.',
		)

	glyph_args = AttributeDict(
		decompose=int(glyphs_decompose),
		remove_overlaps=int(glyphs_remove_overlaps),
		omit_names=glyphs_omit_names_list,
		omit_suffixes=glyphs_omit_suffixes_list,
		)

	hints_args = AttributeDict(
		ignore=hints_ignore,
		build=build_hints,
		autoreplace=int(hints_autoreplace),
		ignore_vertical=int(hints_ignore_vertical),
		ignore_replacements=int(hints_ignore_replacements),
		afdko=int(hints_afdko),
		)

	vfb_args = AttributeDict(
		save=vfb_save,
		close=vfb_close,
		)

	ufoz_args = AttributeDict(
		ufoz=ufoz,
		compress=int(ufoz_compress),
		)

	designspace_args = AttributeDict(
		designspace=designspace_export,
		default=designspace_default,
		values=designspace_values,
		names=designspace_names,
		attrs=designspace_attrs,
		sources=[],
		)

	ufo = AttributeDict(
		path=path,
		version=version,
		glif_version=version-1,
		layer=layer,
		upm=upm,
		names=instance_names,
		values=instance_values,
		attrs=instance_attributes,
		designspace=designspace_args,
		scale=scale_args,
		features=features_args,
		groups=groups_args,
		afdko=afdko_args,
		kern=kern_args,
		glyph=glyph_args,
		hints=hints_args,
		ufoz=ufoz_args,
		archive={},
		vfb=vfb_args,
		creator='com.spiratype',
		force_overwrite=force_overwrite,
		report=report,
		)

	# ---------------------
	#  instance generation
	# ---------------------

	# generate master copy
	add_master_copy(font, ufo)

	# ufo generation
	for values, names, attrs in zip(ufo.values, ufo.names, ufo.attrs):
		add_instance(ufo, masters, values, names, attrs)

		# glifs(ufo)
		# features(ufo)
		# plists(ufo)

		if ufo.afdko.parts:
			fdk.parts(ufo)

		if ufo.ufoz.ufoz:
			write_ufoz(ufo)

		if ufo.vfb.save:
			fl.Save(ufo.instance_paths.vfb)

		if ufo.vfb.close:
			fl.Close(ufo.ifont)

		report_log(ufo)
	# 	raise UserWarning
	# --------------------------
	#  variable font generation
	# --------------------------

	if ufo.designspace.designspace:
		designspace(ufo)

	if ufo.vfb.close:
		fl.Close(ufo.master_copy)
