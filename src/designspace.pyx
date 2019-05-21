# coding: future_fstrings
# cython: wraparound=False, boundscheck=False
# cython: infer_types=True, cdivision=True
# cython: optimize.use_switch=True, optimize.unpack_method_calls=True
from __future__ import absolute_import, division, print_function, unicode_literals

from tools cimport element, int_float

import os

from FL import fl

from vfb2ufo import tools
from vfb2ufo.constants import *
from vfb2ufo.future import *

cdef list designspace_axis(unicode tag, default_value):

	'''
	designspace axis
	'''

	cdef:
		unicode attrs = (f'default="{default_value}" minimum="0" maximum="1000"'
			f' name="{tag.lower()}" tag="{AXIS_TAGS[tag]}"')

	elems = element('labelname', attrs='xml:lang="en"', text=tag, elems=None)

	return element('axis', attrs=attrs, text=None, elems=[elems])


cdef list designspace_location(list dimensions):

	'''
	designspace location
	'''

	return element('location', attrs=None, text=None, elems=dimensions)


cdef unicode designspace_dimension(unicode name, value):

	'''
	designspace dimension
	'''

	cdef:
		unicode	attrs = f'name="{name.lower()}" xvalue="{int_float(value)}"'

	return element('dimension', attrs=attrs, text=None, elems=None)


cdef list designspace_source(
	unicode filename,
	unicode familyname,
	unicode stylename,
	unicode name,
	list location,
	bint features=0,
	bint groups=0,
	bint info=0,
	bint lib=0,
	):

	'''
	designspace source
	'''

	cdef:
		list copies = []
		list elems = []
		unicode	attrs = (f'filename="{filename}" familyname="{familyname}"'
			f' stylename="{stylename}" name="{name}"')

	if features:
		copies.append(element('features', attrs='copy="1"', text=None, elems=None))
	if groups:
		copies.append(element('groups', attrs='copy="1"', text=None, elems=None))
	if info:
		copies.append(element('info', attrs='copy="1"', text=None, elems=None))
	if lib:
		copies.append(element('lib', attrs='copy="1"', text=None, elems=None))

	elems = copies + location

	return element('source', attrs=attrs, text=None, elems=elems)


cdef list designspace_instance(
	unicode familyname,
	unicode filename,
	unicode stylename,
	unicode ps_name,
	list location,
	):

	'''
	designspace instance
	'''

	cdef:
		unicode	attrs = (f'filename="{filename}" familyname="{familyname}"'
			f' name="{name}"')

	if ps_name:
		attrs += f' postscriptfontname="{ps_name}"'

	return element('instance', attrs=attrs, text=None, elems=location)


cdef list designspace_axes(list axes):

	'''
	designspace axes
	'''

	return element('axes', attrs=None, text=None, elems=axes)


cdef list designspace_instances(list instances):

	'''
	designspace instances
	'''

	return element('instances', attrs=None, text=None, elems=instances)


cdef list designspace_sources(list sources):

	'''
	designspace sources
	'''

	return element('sources', attrs=None, text=None, elems=sources)


def designspace(ufo):

	'''
	designspace document
	'''

	master_copy = fl[ufo.master_copy]
	family_name = str(master_copy.family_name)
	version = str(master_copy.version)
	axes_names = [str(axis[0]) for axis in master_copy.axis]
	master_values, master_names = tools.master_names_values(master_copy)
	master_filenames = ufo.designspace.sources
	axes, sources, instances = [], [], []

	for axis_name, default in zip(axes_names, ufo.designspace.default):
		axes.extend(designspace_axis(axis_name, default))

	i = 1
	for filename, values, names in zip(master_filenames, master_values, master_names):
		location = [designspace_dimension(name, value)
			for name, value in zip(axes_names, values)]
		location = designspace_location(location)
		style_name = ' '.join(names)
		name = f'{family_name} {style_name}'
		if i:
			sources.extend(designspace_source(
				f'masters\\{filename}', family_name, style_name, name, location, 1, 1, 1, 1,
				))
			i = 0
		else:
			sources.extend(designspace_source(
				f'masters\\{filename}', family_name, style_name, name, location,
				))

	doc = designspace_axes(axes) + designspace_sources(sources)

	if ufo.designspace.values:
		for values, names, attrs in zip(ufo.designspace.values, ufo.designspace.names, ufo.designspace.attrs):
			location = [designspace_dimension(name, value)
				for name, value in zip(axes_names, values)]
			location = designspace_location(location)
			if not isinstance(names, str):
				style_name = ' '.join(names)
			family_name = attrs.get('familyName', family_name)
			name = attrs.get('styleName', style_name)
			ps_name = attrs.get('postscriptFontName', '')
			filename = os.path.join('instances', f'{family_name}-{style_name}').replace(' ', '')
			instances.extend(designspace_instance(
				family_name, filename, name, ps_name, location,
				))
		doc += designspace_instances(instances)

	doc = '\n'.join(element('designspace', attrs='format="3"', text=None, elems=doc))
	tools.write_file(ufo.designspace.path, XML_DECLARATION + doc)
