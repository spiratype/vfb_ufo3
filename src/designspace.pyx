# coding: future_fstrings
# cython: wraparound=False, boundscheck=False
# cython: infer_types=True, cdivision=True
# cython: optimize.use_switch=True, optimize.unpack_method_calls=True
from __future__ import absolute_import, division, print_function, unicode_literals
from vfb2ufo3.future import open, range, str, zip, items

from tools cimport element, int_float

import os

from FL import fl

from vfb2ufo3 import tools
from vfb2ufo3.constants import XML_DECLARATION, AXIS_TAGS

cdef list ds_axis(unicode tag, default):

	'''
	designspace axis
	'''

	cdef:
		unicode attrs = (f'default="{default}" minimum="0" maximum="1000"'
			f' name="{tag.lower()}" tag="{AXIS_TAGS[tag]}"')

	elems = [element('labelname', attrs='xml:lang="en"', text=tag, elems=None)]

	return element('axis', attrs=attrs, text=None, elems=elems)


cdef list ds_location(list dimensions):

	'''
	designspace location
	'''

	return element('location', attrs=None, text=None, elems=dimensions)


cdef unicode ds_dimension(unicode name, value):

	'''
	designspace dimension
	'''

	cdef:
		unicode	attrs = f'name="{name.lower()}" xvalue="{int_float(value)}"'

	return element('dimension', attrs=attrs, text=None, elems=None)


cdef list ds_source(
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
		unicode	attrs = f'filename="{filename}" familyname="{familyname}"' + \
			f' stylename="{stylename}" name="{name}"'

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


cdef list ds_instance(
	unicode familyname,
	unicode filename,
	unicode name,
	unicode ps_name,
	list location,
	):

	'''
	designspace instance
	'''

	cdef:
		unicode	attrs

	attrs = f'filename="{filename}" familyname="{familyname}" name="{name}"'

	if ps_name:
		attrs += f' postscriptfontname="{ps_name}"'

	return element('instance', attrs=attrs, text=None, elems=location)


cdef list ds_axes(list axes):

	'''
	designspace axes
	'''

	return element('axes', attrs=None, text=None, elems=axes)


cdef list ds_instances(list instances):

	'''
	designspace instances
	'''

	return element('instances', attrs=None, text=None, elems=instances)


cdef list ds_sources(list sources):

	'''
	designspace sources
	'''

	return element('sources', attrs=None, text=None, elems=sources)


def designspace(ufo):

	'''
	designspace document
	'''

	dspace = ufo.designspace
	master_copy = fl[ufo.master_copy]
	family_name = str(master_copy.family_name)
	version = str(master_copy.version)
	axes_names = [str(axis[0]) for axis in master_copy.axis]
	master_values, master_names = tools.master_names_values(master_copy)
	master_filenames = dspace.sources
	axes, sources, instances = [], [], []

	for axis_name, default in zip(axes_names, dspace.default):
		axes.extend(ds_axis(axis_name, default))

	for filename, values, names in zip(master_filenames, master_values, master_names):
		location = ds_location([
			ds_dimension(name, value) for name, value in zip(axes_names, values)
			])
		style_name = ' '.join(names)
		name = f'{family_name} {style_name}'
		if not sources:
			sources.extend(ds_source(
				f'masters\\{filename}', family_name, style_name, name, location, 1, 1, 1, 1,
				))
		else:
			sources.extend(ds_source(
				f'masters\\{filename}', family_name, style_name, name, location,
				))

	doc = ds_axes(axes) + ds_sources(sources)

	if dspace.values:
		for values, names, attrs in zip(dspace.values, dspace.names, dspace.attrs):
			location = ds_location([
				ds_dimension(name, value) for name, value in zip(axes_names, values)
				])
			if not isinstance(names, str):
				style_name = ' '.join(names)
			family_name = attrs.get('familyName', family_name)
			name = attrs.get('styleName', style_name)
			ps_name = attrs.get('postscriptFontName', '')
			filename = os.path.join('instances', f'{family_name}-{style_name}').replace(' ', '')
			instances.extend(ds_instance(family_name, filename, name, ps_name, location))
		doc += ds_instances(instances)

	doc = '\n'.join(element('designspace', attrs='format="3"', text=None, elems=doc))
	tools.write_file(dspace.path, XML_DECLARATION + doc)
