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

from libcpp.string cimport string

import os
import shutil
import stat
import threading
import time

from FL import fl

include 'includes/thread.pxi'
include 'includes/path.pxi'
include 'includes/file.pxi'

def fdk(ufo):
	start = time.clock()
	if ufo.opts.afdko_parts:
		_parts(ufo)
	if ufo.opts.psautohint_cmd or ufo.opts.psautohint_cmd:
		batch = bool(ufo.opts.psautohint_batch_cmd and len(ufo.instance_values) > 1)
		psautohint_command(ufo, batch=batch)
	ufo.instance_times.afdko = time.clock() - start

def _parts(ufo):

	'''
	build FontMenuNameDB, GlyphOrderAndAliasDB, and batch MakeOTF command
	'''

	instance = fl[ufo.instance.ifont]
	font_menu_name_db(ufo, instance)
	glyph_order_db(ufo, instance)

	if ufo.opts.afdko_makeotf_batch_cmd or ufo.opts.afdko_makeotf_cmd:
		batch = ufo.opts.afdko_makeotf_batch_cmd and len(ufo.instance_values) > 1
		makeotf_command(ufo, batch=batch)


def glyph_order_db(ufo, font):

	'''
	GlyphOrderAndAliasDB file

	final (working source name) uni_name
	.notdef	.notdef	uniFFFD
	space	space	uni0020
	exclam	exclam	uni0021
	quotedbl	quotedbl	uni0022
	numbersign	numbersign	uni0023
	dollar	dollar	uni0024
	percent	percent	uni0025
	ampersand	ampersand	uni0026
	...
	'''

	if not ufo.paths.afdko.goadb:
		text = []
		for glyph_name, glyph_uni_name in ufo.afdko.GOADB:
			if font.FindGlyph(glyph_name.encode('cp1252')) not in ufo.glyph_sets.omit:
				if glyph_uni_name is None:
					text.append(f'{glyph_name} {glyph_name}')
				else:
					text.append(f'{glyph_name} {glyph_name} {glyph_uni_name}')
		write_file(ufo.paths.instance.goadb, '\n'.join(text))
	else:
		copy_file(ufo.paths.afdko.goadb, ufo.instance_paths.afdko.goadb)


def font_menu_name_db(ufo, font):

	text = (
		f'[{font.font_name.replace(" ", "")}]\n'
		f'f={font.family_name}\n'
		f's={font.pref_style_name}\n'
		f'l={font.family_name} {font.pref_style_name}\n'
		)

	write_file(ufo.paths.instance.fontnamedb, text)


def makeotf_command(ufo, batch=0):

	'''
	generate MakeOTF command

	* -f  input path
	* -o  output path                                        >> default (<ufoname>.otf)
	-b/nb  bold on/off
	-i/ni  italic on/off
	-ff  features
	-fs  create stub GSUB table if no features file
	-gs  omit glyphs not in goadb
	-mf  fontmenuname                                        >> default (FontMenuNameDB)
	-gf/nga  goadb on/off                                    >> default (GlyphOrderAndAliasDB)
	-r  release mode                                         >> default
	-S/nS  subroutinization on/off
	-ga  if not -r (release mode)
	-osbOn/osbOff turn on/off os2 bits
		0 italic
		1 underscore
		2 outlined
		4 strikeout
		5 bold
		6 regular
		7 USE_TYPO_METRICS                                     >> default -osbOn 7
		8 WWS (weight width slope only)                        >> default -osbOn 8
		9 (oblique)
	-osv  os/2 version
	-shw/-nshw  show/hide warnings about unhinted glyphs     >> default -nshw
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

	instance = fl[ufo.instance.ifont]
	args = []

	if instance.font_style in (1, 33):
		args.append('-osbOn 0')
	elif instance.font_style in (32, 33):
		args.append('-osbOn 5')
	elif instance.font_style == 64:
		args.append('-osbOn 6')

	args += ['-osbOn 7', '-osbOn 8', '-osbOff 9']

	if ufo.opts.afdko_makeotf_addDSIG:
		args.append('-addDSIG')
	if ufo.opts.afdko_makeotf_release:
		args.append('-r')
	if ufo.opts.afdko_makeotf_subroutinization:
		args.append('-S')
	if ufo.opts.afdko_makeotf_verbose:
		args.append('-V')
	if ufo.opts.afdko_makeotf_sans:
		args.append('-sans')
		ufo.opts.afdko_makeotf_serif = 0
	if ufo.opts.afdko_makeotf_serif:
		args.append('-serif')
	if ufo.opts.afdko_makeotf_replace_notdef:
		args.append('-addn')
	if ufo.opts.afdko_makeotf_suppress_unhinted_glyph_warnings:
		args.append('-nshw')

	if ufo.opts.afdko_makeotf_args:
		for arg in ufo.opts.afdko_makeotf_args:
			if arg not in args:
				args.append(arg)

	command = ' '.join((
		f'makeotf -f "{os_path_basename(ufo.paths.instance.ufo)}"',
		f'-gf "{os_path_basename(ufo.paths.instance.goadb)}"',
		f'-mf "{os_path_basename(ufo.paths.instance.fontnamedb)}"',
		*args,
		f'-skco -osv 4 -o "{os_path_basename(ufo.paths.instance.otf)}"',
		))

	if batch:
		ufo.afdko.makeotf.cmd.append(command)
		if ufo.last:
			write_bat(ufo.afdko.makeotf.cmd, ufo.paths.afdko.makeotf_cmd, batch=1)
	else:
		write_bat(command, ufo.paths.instance.makeotf_cmd)


def psautohint_command(ufo, batch=0):

	'''
	-v, verbose mode
	-vv, extra-verbose mode.
	-a, hint all glyphs
	-w, write hints to default layer. This is a UFO-only
	-d, use decimal coordinates
	-g, comma-separated sequence of glyphs to hint
		The glyph identifiers may be glyph indexes, glyph
		names, or glyph CIDs. CID values must be prefixed with
		a forward slash.
		Examples:
			psautohint -g A,B,C,69 MyFont.ufo
			psautohint -g /103,/434,68 MyCIDFont
	-x, comma-separated sequence of glyphs to NOT hint
	-c, allow changes to the glyph outlines
	--report-only, process the font without modifying it
	--log, write output messages to a file
	--no-flex, suppress generation of flex commands
	--no-hint-sub, suppress hint substitution
	--no-zones-stems, allow the font to have no alignment zones nor stem widths
	'''

	args = []
	if ufo.opts.psautohint_write_to_default_layer:
		args.append('-w')
	if ufo.opts.psautohint_decimal:
		args.append('-d')
	if ufo.opts.psautohint_allow_outline_changes:
		args.append('-c')
	if ufo.opts.psautohint_no_flex:
		args.append('--no-flex')
	if ufo.opts.psautohint_no_hint_substitution:
		args.append('--no-hint-sub')
	if ufo.opts.psautohint_no_zones_stems:
		args.append('--no-zones-stems')
	if ufo.opts.psautohint_verbose:
		args.append('-v')
	if ufo.opts.psautohint_extra_verbose:
		args.append('-vv')
	if ufo.opts.psautohint_glyphs_list:
		args.append(f'-g {",".join(ufo.opts.psautohint_glyphs_list)}')
	if ufo.opts.psautohint_glyphs_omit_list:
		args.append(f'-x {",".join(ufo.opts.psautohint_glyphs_omit_list)}')
	if ufo.opts.psautohint_log:
		log_path = ufo.paths.instance.psautohint_cmd.replace('.bat', '.log')
		args.append(f'--log {log_path}')
	if ufo.opts.psautohint_report_only:
		args.append('--report-only')

	command = ' '.join((
		'psautohint',
		*args,
		f'"{os_path_basename(ufo.paths.instance.ufo)}"',
		))

	if batch:
		if ufo.psautohint.cmd is None:
			ufo.psautohint.cmd = []
		ufo.psautohint.cmd.append(command)
		if ufo.last:
			write_bat(ufo.psautohint.cmd, ufo.paths.psautohint_cmd, batch=1)
	else:
		write_bat(command, ufo.paths.instance.psautohint_cmd)

def write_bat(command, command_path, batch=0):

	if batch:
		command = '\n'.join(command)
	command = f'echo on\n{command}\npause'

	write_file(command_path, command)
