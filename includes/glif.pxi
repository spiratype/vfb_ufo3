# GLIF

cimport cython

import os

cdef double UFO_SCALE = 1.0

POINT_TYPES = {
	0: '',
	1: 'curve',
	2: 'qcurve',
	3: 'line',
	4: 'off',
	5: 'move',
	}

NO_OFFSET = FL.Point(0, 0)
NO_SCALE = FL.Point(1, 1)

def Anchor(x, y, name):
	anchor = Point(x, y, 0, 0)
	anchor.name = py_unicode(name)
	anchor.anchor = 1
	return anchor

@cython.final
cdef class Point:

	cdef readonly:
		int x, y
		int type, alignment

	cdef public:
		bint anchor
		object name

	def __cinit__(self, x, y, type, alignment):
		self.x = x
		self.y = y
		self.type = type
		self.alignment = alignment
		self.anchor = 0
		self.name = None

	@property
	def smooth(self):
		if self.alignment:
			return 'yes'

	@property
	def attrs(self):

		if self.anchor:
			return (
				('x', number_str(<double>self.x * UFO_SCALE)),
				('y', number_str(<double>self.y * UFO_SCALE)),
				('name', self.name),
				)

		if self.type > 3:
			return (
				('x', number_str(<double>self.x * UFO_SCALE)),
				('y', number_str(<double>self.y * UFO_SCALE)),
				)

		return (
			('x', number_str(<double>self.x * UFO_SCALE)),
			('y', number_str(<double>self.y * UFO_SCALE)),
			('type', POINT_TYPES[self.type]),
			('smooth', self.smooth),
			('name', self.name),
			)

	def __reduce__(self):
		return self.__class__


@cython.final
cdef class Component:

	cdef readonly:
		object offset, scale
		unicode base

	def __cinit__(self, offset, scale, base):
		self.offset = offset
		self.scale = scale
		self.base = base.decode('cp1252')

	@property
	def attrs(self):
		return (
			('base', self.base),
			('xOffset', number_str(<double>self.offset.x * UFO_SCALE)),
			('yOffset', number_str(<double>self.offset.y * UFO_SCALE)),
			('xScale', '%.1f' % self.scale.x),
			('yScale', '%.1f' % self.scale.y),
			)

	def __reduce__(self):
		return self.__class__


@cython.final
cdef class Glif:

	cdef readonly:
		unicode name, filename
		bytes path
		tuple mark_color
		list unicodes
		int index
		double scale
		bint omit, base, ufoz
		dict ufoz_archive

	cdef public:
		bytes text
		int width
		list anchors, components, contours, component_contours

	def __cinit__(self, name, filename, mark_color, unicodes, index, parent):
		self.path = file_str(os.path.join(parent.paths.instance.glyphs, filename))
		self.name = name
		self.filename = filename
		self.mark_color = mark_color
		self.index = index
		self.unicodes = unicodes
		self.anchors = []
		self.components = []
		self.component_contours = []
		self.contours = []
		self.base = index in parent.glyph_sets.bases
		self.omit = index in parent.glyph_sets.omit
		self.scale = parent.scale
		self.ufoz = parent.opts.ufoz
		if self.ufoz:
			self.ufoz_archive = parent.archive

	def write(self):
		if not self.omit:
			write_file(self.path, self.text)

	def archive(self):
		if not self.omit:
			self.ufoz_archive[self.path] = self.text

	@property
	def advance(self):
		return number_str(<double>self.width * self.scale)

	@property
	def mark(self):
		return ','.join([number_str(value) for value in self.mark_color])

	@property
	def lib(self):
		return [
			'\t<lib>',
			'\t\t<dict>',
			'\t\t\t<key>public.markColor</key>',
			f'\t\t\t<string>{self.mark}</string>',
			'\t\t</dict>',
			'\t</lib>',
			]

	def __reduce__(self):
		return self.__class__


def glif_unicode(code_point):
	return f'\t<unicode hex="{code_point}"/>'

def glif_anchor(anchor):
	return f'\t<anchor {attributes(anchor.attrs)}/>'

def glif_point(point):
	return f'\t\t\t<point {attributes(point.attrs)}/>'

def glif_component(component):
	return f'\t\t<component {attributes(component.attrs)}/>'

def glif_contour(contour):
	contour = [glif_point(point) for point in contour]
	return ['\t\t<contour>', *contour, '\t\t</contour>']

def glif_outline(outline):
	if outline:
		return ['\t<outline>', *outline, '\t</outline>']
	return []
