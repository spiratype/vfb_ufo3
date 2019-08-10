# coding: utf-8
# cython: wraparound=False
# cython: boundscheck=False
# cython: infer_types=True
# cython: cdivision=True
# cython: auto_pickle=False
from __future__ import absolute_import, division, unicode_literals
include 'includes/future.pxi'
include 'includes/cp1252.pxi'

from xml cimport plist_doc

import os
import time

from FL import fl

include 'includes/ignored.pxi'
include 'includes/thread.pxi'
include 'includes/io.pxi'
include 'includes/path.pxi'
include 'includes/objects.pxi'
include 'includes/plist.pxi'
include 'includes/string.pxi'

def plists(ufo):
	start = time.clock()
	_plists(ufo)
	ufo.instance_times.plists = time.clock() - start

def _plists(ufo):

	instance = fl[ufo.instance.ifont]

	metainfo(ufo)
	fontinfo(ufo)
	groups(ufo)
	kerning(ufo, instance)
	lib(ufo, instance)
	glyphs_contents(ufo, instance)
	layercontents(ufo)

def metainfo(ufo):

	if ufo.plists.metainfo:
		copy_file(ufo.plists.metainfo, ufo.paths.instance.metainfo)
		return

	metainfo = ordered_dict()
	metainfo['creator'] = ufo.creator
	metainfo['formatVersion'] = 3

	plist = plist_doc(metainfo)

	if ufo.opts.ufoz:
		ufo.archive[ufo.paths.instance.metainfo] = plist
	else:
		ufo.plists.metainfo = ufo.paths.instance.metainfo
		write_file(ufo.paths.instance.metainfo, plist)


def fontinfo(ufo):

	plist = plist_doc(ufo.instance.fontinfo)

	if ufo.opts.ufoz:
		ufo.archive[ufo.paths.instance.fontinfo] = plist
	else:
		write_file(ufo.paths.instance.fontinfo, plist)


def groups(ufo):

	if ufo.groups.all and ufo.plists.groups:
		copy_file(ufo.plists.groups, ufo.paths.instance.groups)
		return

	plist = plist_doc(ufo.groups.all)

	if ufo.opts.ufoz:
		ufo.archive[ufo.paths.instance.groups] = plist
	else:
		ufo.plists.groups = ufo.paths.instance.groups
		write_file(ufo.paths.instance.groups, plist)


def kerning(ufo, font):

	if ufo.instance.kerning:

		plist = plist_doc(ufo.instance.kerning)

		if ufo.opts.ufoz:
			ufo.archive[ufo.paths.instance.kerning] = plist
		else:
			write_file(ufo.paths.instance.kerning, plist)


def lib(ufo, font):

	if ufo.plists.lib:
		copy_file(ufo.plists.lib, ufo.paths.instance.lib)
		return

	lib = ordered_dict()
	lib['public.glyphOrder'] = ufo.glyph_order
	lib['com.schriftgestaltung.disablesAutomaticAlignment'] = True
	lib['com.schriftgestaltung.disablesLastChange'] = True
	lib['com.schriftgestaltung.useNiceNames'] = False

	plist = plist_doc(lib)

	if ufo.opts.ufoz:
		ufo.archive[ufo.paths.instance.lib] = plist
	else:
		ufo.plists.lib = ufo.paths.instance.lib
		write_file(ufo.paths.instance.lib, plist)


def glyphs_contents(ufo, font):

	if ufo.plists.glyphs_contents:
		copy_file(ufo.plists.glyphs_contents, ufo.paths.instance.glyphs_contents)
		return

	master_copy = fl[ufo.master_copy.ifont]

	glyph_contents = ordered_dict()
	for i, glyph in enumerate(master_copy.glyphs):
		if i not in ufo.glyph_sets.omit:
			glyph_contents[py_unicode(glyph.name)] = ufo.glifs[i][1]

	plist = plist_doc(glyph_contents)

	if ufo.opts.ufoz:
		ufo.archive[ufo.paths.instance.glyphs_contents] = plist
	else:
		ufo.plists.glyphs_contents = ufo.paths.instance.glyphs_contents
		write_file(ufo.paths.instance.glyphs_contents, plist)


def layercontents(ufo):

	if ufo.plists.layercontents:
		copy_file(ufo.plists.layercontents, ufo.paths.instance.layercontents)
		return

	layercontents = [['public.default', 'glyphs']]

	plist = plist_doc(layercontents)

	if ufo.opts.ufoz:
		ufo.archive[ufo.paths.instance.layercontents] = plist
	else:
		ufo.plists.layercontents = ufo.paths.instance.layercontents
		write_file(ufo.paths.instance.layercontents, plist)
