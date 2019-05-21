# coding: future_fstrings
# cython: wraparound=False, boundscheck=False
# cython: infer_types=True, cdivision=True
# cython: optimize.use_switch=True, optimize.unpack_method_calls=True
from __future__ import absolute_import, division, print_function, unicode_literals

import os
import shutil

from FL import fl

from vfb2ufo import tools
from vfb2ufo.future import *

cdef glyph_order_db(object ufo, object font):

	'''
	GlyphOrderAndAliasDB file

	final/output_name working/source_name uni_name
	.notdef	.notdef	uniFFFD
	space	space	uni0020
	exclam	exclam	uni0021
	quotedbl	quotedbl	uni0022
	numbersign	numbersign	uni0023
	dollar	dollar	uni0024
	percent	percent	uni0025
	ampersand	ampersand	uni0026
	'''

	if not ufo.afdko.GOADB_path:
		goadb = []
		for glyph_name, glyph_uni_name in ufo.afdko.GOADB:
			if glyph_name in ufo.glyphs:
				if glyph_uni_name:
					goadb.append(f'{glyph_name} {glyph_name} {glyph_uni_name}')
				else:
					goadb.append(f'{glyph_name} {glyph_name}')

		tools.write_file(ufo.instance_paths.afdko.goadb, '\n'.join(goadb))

	else:
		shutil.copy2(ufo.afdko.GOADB_path, ufo.instance_paths.afdko.goadb)


cdef font_name_db(object ufo, object font):

	'''
	FontMenuNameDB file
	'''

	cdef:
		unicode fontnamedb = '\n'.join([
			f'[{font.font_name}]',
			f'f={font.family_name}',
			f's={font.pref_style_name}',
			f'l={font.pref_family_name}',
			])

	tools.write_file(ufo.instance_paths.afdko.fontnamedb, fontnamedb)


cdef makeotf_command(object ufo, bint batch):

	'''
	generate MakeOTF command

	* -f  input path
	* -o  output path                     >> default (<ufoname>.otf)
	-b/nb  bold on/off
	-i/ni  italic on/off
	-ff  features
	-fs  create stub GSUB table if no features file
	-gs  omit glyphs not in goadb
	-mf  fontmenuname                     >> default (FontMenuNameDB)
	-gf/nga  goadb on/off                 >> default (GlyphOrderAndAliasDB)
	-r  release mode                      >> default
	-S/nS  subroutinization on/off
	-ga  if not -r (release mode)
	-osbOn/osbOff turn on/off os2 bits
		0 italic
		1 underscore
		2 outlined
		4 strikeout
		5 bold
		6 regular
		7 USE_TYPO_METRICS                  >> default -osbOn 7
		8 WWS (weight width slope only)     >> default -osbOn 8
		9 (oblique)
	-osv  os/2 version
	-addn/naddn  replace notdef with makeotf notdef on/off
	-adds/nadds  add mac symbol glyphs on/off
	-serif (serifed generated glyphs)
	-sans (sans serif generated glyphs)
	-overrideMenuNames
	-cs # override heuristics
	-cl # override heuristics
	-cm # CMap encoding file Mac encoding CID-fonts
	-ch # CMap encoding file for horizontal glyphs UTF-32-fonts
	-cv # CMap encoding file for vertical glyphs UTF-32-fonts
	-ci # unicode variation sequence
	-dbl # double encode glyphs (deprecated per makeotf user manual)
	-dcs # set os/2 default character to 'space' glyph instead of 'notdef'
	-fi # font info file
	-sp # save options to file
	'''

	cdef:
		object font = fl[ufo.ifont]
		list args = []
		list bits = []
		list command
		unicode makeotf_input = f'..\\{os.path.basename(ufo.instance_paths.ufo)}'
		unicode makeotf_output = f'..\\{os.path.basename(ufo.instance_paths.otf)}'
		unicode makeotf_goadb = os.path.basename(ufo.instance_paths.afdko.goadb)
		unicode makeotf_fontmenudb = os.path.basename(ufo.instance_paths.afdko.fontnamedb)

	if font.font_style in (1, 33):
		args.append('-osbOn 0')

	if font.font_style in (32, 33):
		args.append('-osbOn 5')

	if font.font_style == 64:
		args.append('-osbOn 6')

	args.extend(['-osbOn 7', '-osbOn 8', '-osbOff 9'])

	if ufo.afdko.makeotf_addDSIG:
		args.append('-addDSIG')
	if ufo.afdko.makeotf_release:
		args.append('-r')
	if ufo.afdko.makeotf_subroutinization:
		args.append('-S')
	if ufo.afdko.makeotf_verbose:
		args.append('-V')
	if ufo.afdko.makeotf_sans:
		args.append('-sans')
		ufo.afdko.makeotf_serif = 0
	if ufo.afdko.makeotf_serif:
		args.append('-serif')
	if ufo.afdko.makeotf_replace_notdef:
		args.append('-addn')
	if ufo.afdko.makeotf_suppress_unhinted_glyph_warnings:
		args.append('-shw')
	if ufo.afdko.makeotf_suppress_width_optimization:
		args.append('-swo')

	for arg in ufo.afdko.makeotf_args:
		if arg not in args:
			args.append(arg)

	command = [
		'makeotf',
		f'-f {makeotf_input}',
		f'-gf {makeotf_goadb}',
		f'-mf {makeotf_fontmenudb}',
		' '.join(sorted(list(set(args)))),
		'-skco',
		'-osv 4',
		f'-o {makeotf_output}',
		]

	if ufo.afdko.makeotf_batch_cmd:
		ufo.afdko.cmd.append(chr(32).join(command))
		if ufo.last:
			command_path = ufo.afdko.cmd_path
			write_makeotf_cmd(ufo.afdko.cmd, command_path, batch)
	else:
		command_path = ufo.instance_paths.afdko.cmd
		write_makeotf_cmd(command, command_path, batch)


cdef write_makeotf_cmd(list command, unicode command_path, bint batch):

	'''
	write batch MakeOTF command
	'''

	cdef:
		unicode command_str

	if batch:
		command_str = f'echo on\n{chr(10).join(command)}\npause'
	else:
		command_str = f'echo on\n{chr(32).join(command)}\npause'

	tools.write_file(command_path, command_str)


def parts(ufo):

	'''
	build FontMenuNameDB, GlyphOrderAndAliasDB, and batch MakeOTF command
	'''

	font = fl[ufo.ifont]
	font_name_db(ufo, font)
	glyph_order_db(ufo, font)

	if ufo.afdko.makeotf_batch_cmd:
		makeotf_command(ufo, 1)
	elif ufo.afdko.makeotf_cmd:
		makeotf_command(ufo, 0)
