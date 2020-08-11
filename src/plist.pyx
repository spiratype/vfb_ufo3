# coding: utf-8
# cython: wraparound=False
# cython: boundscheck=False
# cython: infer_types=True
# cython: cdivision=True
# cython: auto_pickle=False
# cython: c_string_type=unicode
# cython: c_string_encoding=utf_8
# distutils: language=c++
# distutils: extra_compile_args=[-O3, -fopenmp, -fconcepts, -Wno-register, -fno-strict-aliasing, -std=c++17]
# distutils: extra_link_args=[-fopenmp]
from __future__ import division, unicode_literals
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

from FL import fl

include 'includes/thread.pxi'
include 'includes/path.pxi'
include 'includes/files.pxi'
include 'includes/plist.pxi'
include 'includes/ordered_dict.pxi'
include 'includes/xml.pxi'

def plists(ufo):
	start = time.clock()
	_plists(ufo)
	ufo.instance_times.plists = time.clock() - start

def _plists(ufo):

	cdef cpp_files files

	if not ufo.opts.ufoz:
		files.reserve(7)

	metainfo(ufo, files)
	fontinfo(ufo, files)
	groups(ufo, files)
	kerning(ufo, files)
	lib(ufo, files)
	glyphs_contents(ufo, files)
	layercontents(ufo, files)

	if not ufo.opts.ufoz:
		write_files(files)


cdef metainfo(ufo, cpp_files &files):

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
		add_file(files, ufo.paths.instance.metainfo, plist)
		ufo.plists.metainfo = ufo.paths.instance.metainfo


cdef fontinfo(ufo, cpp_files &files):

	plist = plist_doc(ufo.instance.fontinfo)

	if ufo.opts.ufoz:
		ufo.archive[ufo.paths.instance.fontinfo] = plist
	else:
		add_file(files, ufo.paths.instance.fontinfo, plist)


cdef groups(ufo, cpp_files &files):

	if ufo.groups.all and ufo.plists.groups:
		copy_file(ufo.plists.groups, ufo.paths.instance.groups)
		return

	plist = plist_doc(ufo.groups.all)

	if ufo.opts.ufoz:
		ufo.archive[ufo.paths.instance.groups] = plist
	else:
		add_file(files, ufo.paths.instance.groups, plist)
		ufo.plists.groups = ufo.paths.instance.groups


cdef kerning(ufo, cpp_files &files):

	if ufo.instance.kerning:
		plist = plist_doc(ufo.instance.kerning)
		if ufo.opts.ufoz:
			ufo.archive[ufo.paths.instance.kerning] = plist
		else:
			add_file(files, ufo.paths.instance.kerning, plist)


cdef lib(ufo, cpp_files &files):

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
		add_file(files, ufo.paths.instance.lib, plist)
		ufo.plists.lib = ufo.paths.instance.lib


cdef glyphs_contents(ufo, cpp_files &files):

	if ufo.plists.glyphs_contents:
		copy_file(ufo.plists.glyphs_contents, ufo.paths.instance.glyphs_contents)
		return

	master_copy = fl[ufo.master_copy.ifont]

	glyph_contents = ordered_dict()
	for i, glyph in enumerate(master_copy.glyphs):
		if i not in ufo.glyph_sets.omit:
			glyph_contents[glyph.name.decode('cp1252')] = ufo.glifs[i][1]

	plist = plist_doc(glyph_contents)

	if ufo.opts.ufoz:
		ufo.archive[ufo.paths.instance.glyphs_contents] = plist
	else:
		add_file(files, ufo.paths.instance.glyphs_contents, plist)
		ufo.plists.glyphs_contents = ufo.paths.instance.glyphs_contents


cdef layercontents(ufo, cpp_files &files):

	if ufo.plists.layercontents:
		copy_file(ufo.plists.layercontents, ufo.paths.instance.layercontents)
		return

	layercontents = [['public.default', 'glyphs']]

	plist = plist_doc(layercontents)

	if ufo.opts.ufoz:
		ufo.archive[ufo.paths.instance.layercontents] = plist
	else:
		add_file(files, ufo.paths.instance.layercontents, plist)
		ufo.plists.layercontents = ufo.paths.instance.layercontents
