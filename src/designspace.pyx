# coding: utf-8
# cython: wraparound=False
# cython: boundscheck=False
# cython: infer_types=True
# cython: cdivision=True
# cython: auto_pickle=False
# distutils: extra_compile_args=[-O3, -fno-strict-aliasing]
from __future__ import division, unicode_literals, print_function
include 'includes/future.pxi'
include 'includes/cp1252.pxi'

cimport cython

import os

from FL import fl

include 'includes/string.pxi'
include 'includes/thread.pxi'
include 'includes/io.pxi'
include 'includes/designspace.pxi'
include 'includes/xml.pxi'

def designspace(ufo):
	_designspace(ufo)

def _designspace(ufo):

	if not ufo.designspace.default:
		ufo.designspace.default = [0] * len(ufo.master.axes_names)

	designspace = Designspace(ufo)

	designspace_axes(ufo, designspace)
	designspace_sources(ufo, designspace)

	if ufo.designspace.values:
		designspace_instances(ufo, designspace)

	build(designspace)
	designspace.write()


def designspace_axes(ufo, designspace):
	for axis in zip(ufo.master.axes_names, ufo.designspace.default):
		designspace.axes += dspace_axis(*axis)

def designspace_sources(ufo, designspace):

	opts = {'features': 1, 'groups': 1, 'lib': 1}
	for values, names, attributes, path in ufo.designspace.sources:
		if designspace.sources:
			opts = {}
		if values == ufo.designspace.default:
			opts['info'] = 1
		names = source_names(path, ufo.master.family_name, attributes['styleName'])
		dimensions = zip(ufo.master.axes_names, values)
		dimensions = [dspace_dimension(*dimension) for dimension in dimensions]
		location = dspace_location(dimensions)
		designspace.sources += dspace_source(location, names, **opts)

def source_names(path, familyname, stylename):
	names = {}
	names['familyname'] = familyname
	names['stylename'] = stylename
	names['name'] = f'{familyname} {stylename}'
	names['filename'] = f'masters/{os.path.basename(path)}'
	return names

def designspace_instances(ufo, designspace):

	for values, names, attributes in ufo.designspace.instances:
		family_name = ufo.master.family_name
		if isinstance(names, (list, tuple)):
			style_name = ' '.join(names)
		else:
			style_name = names
		names = instance_names(attributes, ufo.master.family_name, style_name)
		dimensions = zip(ufo.master.axes_names, values)
		dimensions = [dspace_dimension(*dimension) for dimension in dimensions]
		location = dspace_location(dimensions)
		designspace.instances += dspace_instance(location, names, designspace.rules)

def instance_names(attributes, familyname, stylename):
	names = {}
	names['familyname'] = family = attributes.get('familyName', familyname)
	names['stylename'] = style = attributes.get('styleName', stylename)
	names['postscriptfontname'] = attributes.get('postscriptFontName')
	names['stylemapfamilyname'] = attributes.get('styleMapFamilyName')
	names['stylemapstylename'] = attributes.get('styleMapStyleName')
	names['name'] = filename = f'{family}-{style}.ufo'.replace(' ', '')
	names['filename'] = f'instances/{filename}'
	return names

def build(designspace):

	doc = dspace_axes(designspace.axes) + dspace_sources(designspace.sources)

	if designspace.instances:
		doc += dspace_instances(designspace.instances)

	designspace.text = file_str('\n'.join((
		"<?xml version='1.0' encoding='UTF-8'?>",
		"<designspace format='3'>",
		*doc,
		"</designspace>\n",
		)))
