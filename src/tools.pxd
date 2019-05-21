# coding: future_fstrings
from __future__ import (absolute_import, division, print_function,
	unicode_literals)

from vfb2ufo.constants import OT_FEATURES

# -------------
#  value tools
# -------------

cdef inline list hsv_srgb(int fl_color):

	'''
	convert fl color to rgb

	>>> hsv_rgb(50)
	(0.7, 0.8411764705882263, 1.0, 1)
	'''

	cdef:
		double f, h, s, v, p, q, t
		int i
		list srgb

	if fl_color == 1:
		fl_color = 255

	h, s, v = (fl_color / 255.) * 360, .3, 1.0
	i = int(h * 6)
	f = (h * 6) - i
	p = v * (1 - s)
	q = v * (1 - s * f)
	t = v * (1 - s * (1 - f))

	srgb = [
		[v, t, p, 1.],
		[q, v, p, 1.],
		[p, v, t, 1.],
		[p, q, v, 1.],
		[t, p, v, 1.],
		[v, p, q, 1.]
		]

	srgb = [int_float(j) for j in srgb[i % 6]]
	return srgb

cdef inline int_float(double number):

	'''
	return int if int(number) ~= number

	>>> int_float(4.0)
	4
	>>> int_float(4.001)
	4
	>>> int_float(4.0001)
	4
	>>> int_float(4.05)
	4.05
	'''

	if 0.0 <= number % 1 <= 0.0049:
		return <int>number
	if 0.9951 <= number % 1 <= 1.0:
		return <int>number + 1
	return round(number, 3)

# -------------------
#  string transforms
# -------------------

cdef inline unicode glyph_uni_name(glyph_unicode):

	'''
	convert hex unicode to string

	>>> glyph_uni_name(0x00ac)
	uni00AC
	>>> glyph_uni_name(0x1f657)
	u1F657
	'''

	if isinstance(glyph_unicode, int):
		hex_string = uni_transform(glyph_unicode)
	elif isinstance(glyph_unicode, unicode):
		if unicode[:2] == '0x':
			hex_string = uni_transform(glyph_unicode[:2])
		else:
			hex_string = uni_transform(glyph_unicode)
	if len(hex_string) <= 4:
		return f'uni{hex_string}'
	else:
		return f'u{hex_string}'

cdef inline unicode uni_transform(int glyph_unicode):

	'''
	convert integer or integer-string to a zero-filled, uppercase hexadecimal
	value string

	>>> uni_transform(182)
	00B6
	>>> uni_transform(80)
	0050
	'''

	if glyph_unicode <= 65535:
		return hex(glyph_unicode)[2:].zfill(4).upper().decode('ascii')
	return hex(glyph_unicode)[2:].upper().decode('ascii')

# ---------------
#  etree element
# ---------------

cdef inline element(unicode name, unicode attrs, unicode text, list elems):

	'''
	xml element builder
	>>> element('test')
	<test/>
	>>> element('test', attrs="test='test'", text=None, elems=None)
	<test test="test"/>
	>>> element('test', attrs="test='test'", text='test', elems=None)
	<name test="test">test</name>
	>>> element('test', attrs="test='test'", text=None, elems=None)
	<test test="test"/>
	>>> test = element('test')
	>>> element('test', attrs=None, text=None, elems=test)
	<test>
		<test/>
	</test>
	'''

	cdef:
		unicode elems_str

	if attrs and text:
		return f'<{name} {attrs}>{text}</{name}>'
	elif attrs and elems:
		elems_str = '\n  '.join(elems)
		return f'<{name} {attrs}>\n  {elems_str}\n</{name}>'.splitlines()
	elif attrs:
		return f'<{name} {attrs}/>'
	elif text:
		return f'<{name}>{text}</{name}>'
	elif elems:
		elems_str = '\n  '.join(elems)
		return f'<{name}>\n  {elems_str}\n</{name}>'.splitlines()
	else:
		return f'<{name}/>'

# -----------------------
#  fea features elements
# -----------------------

cdef inline list fea_feature(list value, unicode tag):

	'''
	feature builder
	>>> fea_feature(['sub f f by f_f', 'sub f i by f_i'], 'liga')
	feature liga {
	  sub f f by f_f;
	  sub f i by f_i;
	} liga;
	'''

	cdef:
		unicode value_str = '\n  '.join(value)

	return f'feature {tag} {{ # {OT_FEATURES[tag]}\n  {value_str}\n}} {tag};'.splitlines()

cdef inline list fea_lookup(
	list value,
	unicode label,
	object ufo,
	bint use_extension=0,
	list lookupflags=[],
	):

	'''
	lookup builder
	>>> fea_lookup(['sub f f by f_f;', 'sub f i by f_i;'], 'lookup_0', ufo)
	lookup lookup_0 {
	  sub f f by f_f;
	  sub f i by f_i;
	} lookup_0;
	'''

	cdef:
		tuple valid_lookupflags = (
			'RightToLeft',
			'IgnoreBaseGlyphs',
			'IgnoreLigatures',
			'IgnoreMarks',
			'MarkAttachmentType',
			'UseMarkFilteringSet',
			)
		unicode value_str = '\n  '.join(value)
		unicode flags

	if lookupflags:
		lookupflags = [flag for flag in lookupflags
			if flag in valid_lookupflags or isinstance(flag, int)]
		flags = 'lookupflag ' + ';\n'.join(lookupflags) + ';'

	lookup_block = '\n'.join(ufo.default_lookup_block)

	if use_extension:
		lookup = (f'lookup {label} useExtension {{\n{flags}\n  {value_str}'
			f'\n}} {label};\nlookup {label};\n{lookup_block}'.splitlines())
		return lookup
	else:
		lookup = (f'lookup {label} {{\n{flags}\n  {value_str}\n}} {label};'
			f'\n{lookup_block}'.splitlines())
		return lookup

cdef inline list fea_table(list value, unicode tag):

	'''
	table builder
	>>> fea_table(['FontRevision 1.003;'], 'head')
	table head {
	  FontRevision 1.003;
	} head;
	'''

	value_str = '\n  '.join(value)
	return f'table {tag} {{\n  {value_str}\n}} {tag};'.splitlines()

cdef inline unicode fea_string(unicode string, int platform):

	string = ''.join([character for character in string if ord(character) < 255])
	string = string.replace('\\', '\\x5c').replace('"', '\\x22')
	string = string.encode('ascii', 'backslashreplace').decode('ascii')
	if platform == 3:
		return string.replace('\\x', '\\00')
	if platform == 1:
		return string.replace('\\x', '\\')
