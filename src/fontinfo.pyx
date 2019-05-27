# coding: future_fstrings
# cython: wraparound=False, boundscheck=False
# cython: infer_types=True, cdivision=True
# cython: optimize.use_switch=True, optimize.unpack_method_calls=True
from __future__ import absolute_import, division, print_function, unicode_literals
from vfb2ufo3.future import range, str, items

from tools cimport int_float, element

import collections
import datetime
import math
import os

from FL import fl

from vfb2ufo3.constants import (
	CONFIGURABLE_ATTRIBUTES, STRING_ATTRIBUTES, INT_ATTRIBUTES, FLOAT_ATTRIBUTES,
	INT_FLOAT_ATTRIBUTES, BOOL_ATTRIBUTES, INT_LIST_ATTRIBUTES,
	INT_FLOAT_LIST_ATTRIBUTES, FL_WIDTHS, FL_STYLES, REV_WEIGHTS, REV_WIDTHS,
	REV_FL_WIN_CHARSET, NOMINAL_WIDTH_GLYPH_SET, UNICODE_RANGES, CODEPAGES,
	)

class info_lib(object):

	__slots__ = ['key', 'value', 'value_type', 'layered', 'scalable', 'element']

	def __init__(
		self,
		key,
		value,
		value_type='str',
		layered=0,
		scalable=0,
		scale=0.0,
		):

		'''
		build lib objects for fontinfo
		'''

		# check for list of empty lists
		if value and value_type == 'list':
			value = [elem for elem in value if elem]
			if not value:
				value = None

		self.element = None
		if key == 'openTypeNameDescription':
			if not value:
				value = ''

		if value is not None:
			if scalable and scale:
				if value_type == 'int':
					value = int(round(value * scale))
				if value_type == 'int_float':
					value = int_float(value * scale)
				if value_type == 'int_float_list':
					value = [int_float(value_ * scale) for value_ in value]

			if value_type == 'int':
				self.element = [element('key', attrs=None, text=key, elems=None),
					element('integer', attrs=None, text=str(value), elems=None)]

			elif value_type == 'int_float':
				if isinstance(value, int):
					self.element = [element('key', attrs=None, text=key, elems=None),
						element('integer', attrs=None, text=str(value), elems=None)]
				if isinstance(value, float):
					self.element = [element('key', attrs=None, text=key, elems=None),
						element('real', attrs=None, text=str(value), elems=None)]

			elif value_type == 'float':
				if key in ('italicAngle', 'postscriptSlantAngle'):
					if value:
						self.element = [element('key', attrs=None, text=key, elems=None),
							element('real', attrs=None, text=str(value), elems=None)]
				else:
					self.element = [element('key', attrs=None, text=key, elems=None),
						element('real', attrs=None, text=str(value), elems=None)]

			elif value_type == 'str':
				if value:
					if isinstance(value, bytes):
						try:
							value = str(value)
						except UnicodeError:
							value = value.decode('cp1252', 'ignore')
					self.element = [element('key', attrs=None, text=key, elems=None),
						element('string', attrs=None, text=value, elems=None)]
				else:
					if key == 'openTypeNameDescription':
						self.element = [element('key', attrs=None, text=key, elems=None),
						'<string></string>']

			elif value_type == 'bool':
				self.element = [element('key', attrs=None, text=key, elems=None),
					element(str(bool(value)).lower(), attrs=None, text=None, elems=None)]

			elif value_type == 'int_list':
				if key  == 'openTypeOS2Type':
					if not value:
						values = []
					if values:
						sub_elements = [element('integer', attrs=None, text=str(i), elems=None)
							for i in values]
						self.element = [element('key', attrs=None, text=key, elems=None)]
						self.element.extend(element('array', attrs=None, text=None, elems=sub_elements))
					else:
						self.element = [element('key', attrs=None, text=key, elems=None),
						'<array></array>']

				if key == 'openTypeOS2CodePageRanges':
					if value:
						value_list = [element('integer', attrs=None, text=str(elem), elems=None)
							for elem in value]
						self.element = [element('key', attrs=None, text=key, elems=None)]
						self.element.extend(element('array', attrs=None, text=None, elems=value_list))
					else:
						self.element = [element('key', attrs=None, text=key, elems=None),
						'<array></array>']
				else:
					if value:
						value_list = [element('integer', attrs=None, text=str(elem), elems=None)
							for elem in value]
						self.element = [element('key', attrs=None, text=key, elems=None)]
						self.element.extend(element('array', attrs=None, text=None, elems=value_list))

			elif value_type == 'int_float_list':
				if value:
					value_list = [
						element('integer', attrs=None, text=str(elem), elems=None)
						if isinstance(elem, int) else element('real', attrs=None, text=str(elem), elems=None)
						for elem in value
						]
					self.element = [element('key', attrs=None, text=key, elems=None)]
					self.element.extend(element('array', attrs=None, text=None, elems=value_list))

			elif value_type == 'dict_list':
				dict_list = []
				for dict_value in value:
					dict_array = []
					for d_key, d_value in items(dict_value):
						if isinstance(d_value, int):
							dict_array.extend([
								element('key', attrs=None, text=d_key, elems=None),
								element('integer', attrs=None, text=str(d_value), elems=None)
								])
						elif isinstance(d_value, float):
							dict_array.extend([
								element('key', attrs=None, text=d_key, elems=None),
								element('real', attrs=None, text=str(d_value), elems=None)
								])
						elif isinstance(d_value, list):
							sub_array = []
							for value in d_value:
								sub_array.append(element('integer', attrs=None, text=f'{value}', elems=None))
							dict_array.append(element('key', attrs=None, text=d_key, elems=None))
							dict_array.extend(element('array', attrs=None, text=None, elems=sub_array))
						else:
							dict_array.extend([
								element('key', attrs=None, text=d_key, elems=None),
								element('string', attrs=None, text=str(d_value), elems=None)
								])
					dict_list.extend(element('dict', attrs=None, text=None, elems=dict_array))
				self.element = [element('key', attrs=None, text=key, elems=None)]
				self.element.extend(element('array', attrs=None, text=None, elems=dict_list))

		self.key = key
		self.value = value
		self.value_type = value_type
		self.layered = layered
		self.scalable = scalable


def set_attributes(ufo, font, instance_attributes):

	'''
	set UFO fontinfo attributes from user-defined instance attribute dictionary
	'''

	for key, value in items(instance_attributes):

		'''
		verify user-defined attribute values
		'''

		if key not in CONFIGURABLE_ATTRIBUTES:
			print(f"'{key}' is not a configurable attribute")
		else:
			if key in STRING_ATTRIBUTES:
				if not isinstance(value, (bytes, str)):
					raise TypeError(f"'{value}' is not a valid value for UFO attribute '{key}'\n"
						f"'{key}' must be a string value")

			elif key in INT_ATTRIBUTES:
				if not isinstance(value, int):
					raise TypeError(f"'{value}' is not a valid value for UFO attribute '{key}'\n"
						f"'{key}' must be an integer value")

				if key == 'postscriptWindowsCharacterSet':
					if value < 1 or value > 20:
						raise TypeError(f"'{value}' is not a valid value for UFO attribute '{key}'\n"
							f"'{key}' must be an integer between 1 and 20")
				elif key == 'openTypeOS2WidthClass':
					if value < 1 or value > 9:
						raise TypeError(f"'{value}' is not a valid value for UFO attribute '{key}'\n"
							f"'{key}' must be an integer between 1 and 9")

			elif key in FLOAT_ATTRIBUTES:
				if not isinstance(value, float):
					raise TypeError(f"'{value}' is not a valid value for UFO attribute '{key}'\n"
						f"'{key}' must be a float value")

			elif key in INT_FLOAT_ATTRIBUTES:
				if not isinstance(value, (int, float)):
					raise TypeError(f"'{value}' is not a valid value for UFO attribute '{key}'\n"
						f"'{key}' must be an integer or float value")

			elif key in BOOL_ATTRIBUTES:
				if not isinstance(value, bool):
					raise AttributeError(f"'{value}' is not a valid value for UFO attribute '{key}'\n"
						f"'{key}' must be a boolean value")

			elif key in INT_LIST_ATTRIBUTES:
				if not isinstance(value, list):
					raise TypeError(f"'{value}' is not a valid value for UFO attribute '{key}'\n"
						f"'{key}' must be a list")
				else:
					for item in value:
						if not isinstance(item, int):
							raise TypeError(f"'{value}' contains an valid value ('{item}') for UFO attribute '{key}'\n"
								f"'{key}' items must be integers")

				if key == 'openTypeOS2Panose':
					if len(value) != len(font.panose):
						raise TypeError(f"'{key}' must be a list of {len(font.panose)} integers")
				elif key == 'openTypeOS2FamilyClass':
					if len(value) != 2:
						raise TypeError(f"'{key}' must be a list of 2 integers")
					else:
						for item in value:
							if item > 0 or item < 14:
								raise TypeError(f"'{key}' integers must be values between 0 and 14")
				elif key == 'openTypeOS2CodePageRanges':
					for item in value:
						if item not in CODEPAGES:
							raise TypeError(f"'{key}' requires codepages from the ulCodePageRange1-2 OS/2 specification")
				elif key == 'openTypeOS2UnicodeRanges':
					for item in value:
						if item not in UNICODE_RANGES:
							raise TypeError(f"'{key}' requires codepages from the ulCodePageRange1-4 OS/2 specification")

			elif key in INT_FLOAT_LIST_ATTRIBUTES:
				if not isinstance(value, list):
					raise TypeError(f"'{value}' is not a valid value for UFO attribute '{key}'\n'{key}' must be a list")
				else:
					for item in value:
						if not isinstance(item, (int, float)):
							raise TypeError(f"'{value}' contains an invalid value ('{item}') for UFO attribute '{key}.\n"
								f"'{key}' items must be integers or floats")

	int_attributes = [
		('ascender', 'ascender[0]'),
		('capHeight', 'cap_height[0]'),
		('descender', 'descender[0]'),
		('xHeight', 'x_height[0]'),
		('versionMajor', 'version_major'),
		('versionMinor', 'version_minor'),
		('unitsPerEm', 'upm'),
		('openTypeHeadLowestRecPPEM', 'ttinfo.head_lowest_rec_ppem'),
		('openTypeHheaAscender', 'ttinfo.hhea_ascender'),
		('openTypeHheaDescender', 'ttinfo.hhea_descender'),
		('openTypeHheaLineGap', 'ttinfo.hhea_line_gap'),
		('openTypeOS2Selection', 'ttinfo.os2_fs_selection'),
		('openTypeOS2SubscriptXOffset', 'ttinfo.os2_y_subscript_x_offset'),
		('openTypeOS2SubscriptXSize', 'ttinfo.os2_y_subscript_x_size'),
		('openTypeOS2SubscriptYOffset', 'ttinfo.os2_y_subscript_y_offset'),
		('openTypeOS2SubscriptYSize', 'ttinfo.os2_y_subscript_y_size'),
		('openTypeOS2SuperscriptXOffset', 'ttinfo.os2_y_superscript_x_offset'),
		('openTypeOS2SuperscriptXSize', 'ttinfo.os2_y_superscript_x_size'),
		('openTypeOS2SuperscriptYOffset', 'ttinfo.os2_y_superscript_y_offset'),
		('openTypeOS2SuperscriptYSize', 'ttinfo.os2_y_superscript_y_size'),
		('openTypeOS2StrikeoutSize', 'ttinfo.os2_y_strikeout_size'),
		('openTypeOS2StrikeoutPosition', 'ttinfo.os2_y_strikeout_position'),
		('openTypeOS2Type', 'ttinfo.os2_fs_type'),
		('openTypeOS2TypoAscender', 'ttinfo.os2_s_typo_ascender'),
		('openTypeOS2TypoDescender', 'ttinfo.os2_s_typo_descender'),
		('openTypeOS2TypoLineGap', 'ttinfo.os2_s_typo_line_gap'),
		('openTypeOS2WinAscent', 'ttinfo.os2_us_win_ascent'),
		('openTypeOS2WinDescent', 'ttinfo.os2_us_win_descent'),
		('postscriptDefaultWidthX', 'default_width[0]'),
		('postscriptForceBold', 'force_bold[0]'),
		('postscriptIsFixedPitch', 'is_fixed_pitch'),
		('postscriptBlueFuzz', 'blue_fuzz[0]'),
		('postscriptBlueShift', 'blue_shift[0]'),
		('postscriptUnderlinePosition', 'underline_position'),
		('postscriptUnderlineThickness', 'underline_thickness'),
		('postscriptUniqueID', 'unique_id'),
		]

	float_attributes = [
		('italicAngle', 'italic_angle'),
		('postscriptSlantAngle', 'slant_angle'),
		]

	bytes_attributes = [
		('familyName', 'family_name'),
		('styleMapFamilyName', 'menu_name'),
		('styleName', 'style_name'),
		('openTypeNameCompatibleFullName', 'mac_compatible'),
		('openTypeNameDesignerURL', 'designer_url'),
		('openTypeNameManufacturerURL', 'vendor_url'),
		('openTypeNameLicenseURL', 'license_url'),
		('openTypeNamePreferredFamilyName', 'pref_family_name'),
		('openTypeNamePreferredSubfamilyName', 'pref_style_name'),
		('openTypeNameUniqueID', 'tt_u_id'),
		('openTypeNameVersion', 'version'),
		('postscriptFontName', 'font_name'),
		('postscriptFullName', 'full_name'),
		('postscriptBlueScale', 'blue_scale[0]'),
		('postscriptDefaultCharacter', 'default_character'),
		('postscriptWeightName', 'weight'),
		]

	cp1252_attributes = [
		('copyright', 'copyright'),
		('trademark', 'trademark'),
		('note', 'note'),
		('openTypeNameDescription', 'notice'),
		('openTypeNameDesigner', 'designer'),
		('openTypeNameManufacturer', 'source'),
		('openTypeNameLicense', 'license'),
		]

	int_list_attributes = [
		('openTypeOS2CodePageRanges', 'codepages'),
		('openTypeOS2UnicodeRanges', 'unicoderanges'),
		]

	list_attributes = [
		('postscriptBlueValues', 'blue_values[0]'),
		('postscriptFamilyBlues', 'blue_shift[0]'),
		('postscriptFamilyOtherBlues', 'family_other_blues[0]'),
		('postscriptOtherBlues', 'other_blues[0]'),
		('postscriptStemSnapH', 'stem_snap_h[0]'),
		('postscriptStemSnapV', 'stem_snap_v[0]'),
		]

	# typical-case attribute assignments
	font = fl[ufo.ifont]
	for ufo_attribute, fl_attribute in int_attributes:
		attr = instance_attributes.get(ufo_attribute)
		if attr is not None:
			setattr(font, fl_attribute, int(attr))

	for ufo_attribute, fl_attribute in float_attributes:
		attr = instance_attributes.get(ufo_attribute)
		if attr is not None:
			setattr(font, fl_attribute, float(attr))

	for ufo_attribute, fl_attribute in bytes_attributes:
		attr = instance_attributes.get(ufo_attribute)
		if attr is not None:
			setattr(font, fl_attribute, bytes(str(attr)))

	for ufo_attribute, fl_attribute in cp1252_attributes:
		attr = instance_attributes.get(ufo_attribute)
		if attr is not None:
			setattr(font, fl_attribute, str(attr).encode('cp1252'))

	for ufo_attribute, fl_attribute in int_list_attributes:
		attr = instance_attributes.get(ufo_attribute)
		if attr is not None:
			setattr(font, fl_attribute, [int(i) for i in ufo_attribute])

	# special-case attribute assignments

	ufo.fontinfo.font_style = instance_attributes.get('styleMapStyleName')
	if ufo.fontinfo.font_style not in ('regular', 'italic', 'bold', 'bold italic'):
		ufo.fontinfo.font_style = str(FL_STYLES[font.font_style].lower())

	font_style = instance_attributes.get('openTypeHeadFlags')
	if font_style is not None:
		font.font_style = int(_font_style(font_style))

	sample_font_text = instance_attributes.get('openTypeNameSampleText')
	if sample_font_text is not None:
		ufo.fontinfo.sample_font_text = sample_font_text

	ufo.fontinfo.wws_family_name = instance_attributes.get('openTypeNameWWSFamilyName')
	ufo.fontinfo.wws_sub_family_name = instance_attributes.get('openTypeNameWWSSubfamilyName')
	ufo.ttinfo.hhea_caret_slope_rise = instance_attributes.get('openTypeHheaCaretSlopeRise')
	ufo.ttinfo.hhea_caret_slope_run = instance_attributes.get('openTypeHheaCaretSlopeRun')
	ufo.ttinfo.hhea_caret_offset = instance_attributes.get('openTypeHheaCaretOffset', 0)

	os2_s_family_class = instance_attributes.get('openTypeOS2FamilyClass')
	if os2_s_family_class is not None:
		font.ttinfo.os2_s_family_class = int(os2_s_family_class[0] * 2 + os2_s_family_class[1])

	panose = instance_attributes.get('openTypeOS2Panose')
	if panose is not None:
		for i, j in enumerate(panose):
			font.panose[i] = int(j)

	vendor = instance_attributes.get('openTypeOS2VendorID')
	if vendor is not None:
		font.vendor = bytes(str(vendor[4:].upper()))

	ufo.ttinfo.vhea_vert_typo_ascender = instance_attributes.get('openTypeVheaVertTypoAscender')
	ufo.ttinfo.vhea_vert_typo_descender = instance_attributes.get('openTypeVheaVertTypoDescender')
	ufo.ttinfo.vhea_vert_typo_line_gap = instance_attributes.get('openTypeVheaVertTypoLineGap')
	ufo.ttinfo.vhea_caret_slope_rise = instance_attributes.get('openTypeVheaCaretSlopeRise')
	ufo.ttinfo.vhea_caret_slope_run = instance_attributes.get('openTypeVheaCaretSlopeRun')
	ufo.ttinfo.vhea_caret_offset = instance_attributes.get('openTypeVheaCaretOffset')

	weight_code = instance_attributes.get('openTypeOS2WeightClass')
	if weight_code is not None:
		if weight_code in range(100, 1000, 100):
			font.weight_code = int(weight_code)
			font.ttinfo.os2_us_weight_class = weight_code
			font.weight = bytes(str(REV_WEIGHTS[weight_code]))

	width = instance_attributes.get('openTypeOS2WidthClass')
	if width in REV_WIDTHS:
		font.width = bytes(str(REV_WIDTHS[width]))
		font.ttinfo.os2_us_width_class = int(width)

	ufo.fontinfo.nominal_width = instance_attributes.get('postscriptNominalWidthX')
	if ufo.fontinfo.nominal_width is None:
		ufo.fontinfo.nominal_width = _nominal_width(font)

	ms_charset = instance_attributes.get('postscriptWindowsCharacterSet')
	if ms_charset and ms_charset in range(1, 20):
		font.ms_charset = REV_FL_WIN_CHARSET[ms_charset]

	fl.UpdateFont(ufo.ifont)


def _nominal_width(font):

	'''
	calculate nominal width
	'''

	widths, glyphs = 0, 0
	for glyph in NOMINAL_WIDTH_GLYPH_SET:
		glyph_index = font.FindGlyph(bytes(glyph))
		try:
			if glyph_index >= 0:
				widths += font[glyph_index].width
				glyphs += 1
		except TypeError:
			pass

	return int(round(widths // glyphs))


def _postscript_unique_id(font):

	'''
	return FontLab PostScript integer if it has been set
	'''

	if font.unique_id > -1:
		return font.unique_id
	return


def _font_style(font_style):

	'''
	convert UFO font style bit list to FontLab integer and vice versa
	'''

	if isinstance(font_style, list):
		if font_style == [0]:
			return 1
		if font_style == [5]:
			return 32
		if font_style == [0, 5]:
			return 33
		if font_style == [6]:
			return 64

	i = font_style % 2
	j = math.log(font_style) // math.log(2)

	if i and j:
		return [0, j]
	if j:
		return [j]
	return [0]


cdef list _os2_family_class(int os2_family_class):

	'''
	convert FontLab family class attribute to UFO integer pair
	'''

	return [os2_family_class // 256, os2_family_class % 256]


cdef unicode _date():

	'''
	build date string

	>>> _date()
	2018/07/02 14:47:35
	'''

	return str(datetime.datetime.now()).replace('-', '/')[:19]


cdef dict _guideline(x, y, double angle=0.0, double scale=0.0):

	'''
	build guideline as a dictionary
	'''

	cdef:
		dict guide = {}

	if x is not None:
		if scale:
			guide['x'] = int_float(x * scale)
		else:
			guide['x'] = x
	elif y is not None:
		if scale:
			guide['y'] = int_float(y * scale)
		else:
			guide['y'] = y

	if angle:
		guide['angle'] = angle

	return guide


cdef list _guidelines(object font, object ufo):

	'''
	build list of guideline dictionaries
	'''

	cdef:
		double scale = ufo.scale.factor
		list guides = []

	guides.extend([_guideline(x=None, y=guide.positions[0], angle=guide.angle, scale=scale)
		for guide in font.hguides])
	guides.extend([_guideline(x=guide.positions[0], y=None, angle=guide.angle, scale=scale)
		for guide in font.vguides])

	return guides


cdef list _name_records(object font):

	'''
	build list of name records
	'''

	cdef:
		list records = [collections.OrderedDict((
			('nameID', name_record.nid),
			('platformID', name_record.pid),
			('encodingID', name_record.eid),
			('languageID', name_record.lid),
			('string', name_record.name.decode('cp1252'))))
			for name_record in font.fontnames]

	return records


cdef list _gasp_records(object font):

	'''
	convert FL gasp table record string to a dictionary
	'''

	cdef:
		list records = [collections.OrderedDict((
			('rangeMaxPPEM', gasp.ppm), ('rangeGaspBehavior', [gasp.behavior])
			)) for gasp in font.ttinfo.gasp]

	return records


def fontinfo(ufo):

	'''
	build ufo fontinfo
	'''

	font = fl[ufo.ifont]
	scale = ufo.scale.factor

	info = [
		info_lib('ascender', font.ascender[0],  'int', layered=1, scalable=1, scale=scale),
		info_lib('capHeight', font.cap_height[0], 'int', layered=1, scalable=1, scale=scale),
		info_lib('copyright', font.copyright),
		info_lib('descender', font.descender[0], 'int', layered=1, scalable=1, scale=scale),
		info_lib('familyName', font.family_name),
		info_lib('italicAngle', font.italic_angle, 'float'),
		info_lib('note', font.note),
		info_lib('openTypeHeadCreated', _date()),
		info_lib('openTypeHeadFlags', _font_style(font.font_style), 'int_list'),
		info_lib('openTypeHeadLowestRecPPEM', font.ttinfo.head_lowest_rec_ppem, 'int'),
		info_lib('openTypeHheaAscender', font.ttinfo.hhea_ascender, 'int', scalable=1, scale=scale),
		info_lib('openTypeHheaCaretOffset', ufo.ttinfo.hhea_caret_offset, 'int'),
		info_lib('openTypeHheaCaretSlopeRise', ufo.ttinfo.hhea_caret_slope_rise, 'int'),
		info_lib('openTypeHheaCaretSlopeRun', ufo.ttinfo.hhea_caret_slope_run, 'int'),
		info_lib('openTypeHheaDescender', font.ttinfo.hhea_descender, 'int', scalable=1, scale=scale),
		info_lib('openTypeHheaLineGap', font.ttinfo.hhea_line_gap, 'int', scalable=1, scale=scale),
		# info_lib('openTypeNameCompatibleFullName', font.mac_compatible),
		info_lib('openTypeNameDescription', font.notice),
		info_lib('openTypeNameDesigner', font.designer),
		info_lib('openTypeNameDesignerURL', font.designer_url),
		info_lib('openTypeNameLicense', font.license),
		info_lib('openTypeNameLicenseURL', font.license_url),
		info_lib('openTypeNameManufacturer', font.source),
		info_lib('openTypeNameManufacturerURL', font.vendor_url),
		info_lib('openTypeNamePreferredFamilyName', font.pref_family_name),
		info_lib('openTypeNamePreferredSubfamilyName', font.pref_style_name),
		info_lib('openTypeNameSampleText', ufo.fontinfo.sample_font_text),
		info_lib('openTypeNameUniqueID', font.tt_u_id),
		info_lib('openTypeNameVersion', font.version),
		info_lib('openTypeNameWWSFamilyName', ufo.fontinfo.wws_family_name),
		info_lib('openTypeNameWWSSubfamilyName', ufo.fontinfo.wws_sub_family_name),
		info_lib('openTypeOS2CodePageRanges', font.codepages, 'int_list'),
		info_lib('openTypeOS2FamilyClass', _os2_family_class(font.ttinfo.os2_s_family_class), 'int_list'),
		info_lib('openTypeOS2Panose', font.panose, 'int_list'),
		info_lib('openTypeOS2Selection', font.ttinfo.os2_fs_selection, 'int_list'),
		info_lib('openTypeOS2StrikeoutPosition', font.ttinfo.os2_y_strikeout_position, 'int', scalable=1, scale=scale),
		info_lib('openTypeOS2StrikeoutSize', font.ttinfo.os2_y_strikeout_size, 'int', scalable=1, scale=scale),
		info_lib('openTypeOS2SubscriptXOffset', font.ttinfo.os2_y_subscript_x_offset, 'int', scalable=1, scale=scale),
		info_lib('openTypeOS2SubscriptXSize', font.ttinfo.os2_y_subscript_x_size, 'int', scalable=1, scale=scale),
		info_lib('openTypeOS2SubscriptYOffset', font.ttinfo.os2_y_subscript_y_offset, 'int', scalable=1, scale=scale),
		info_lib('openTypeOS2SubscriptYSize', font.ttinfo.os2_y_subscript_y_size, 'int', scalable=1, scale=scale),
		info_lib('openTypeOS2SuperscriptXOffset', font.ttinfo.os2_y_superscript_x_offset, 'int', scalable=1, scale=scale),
		info_lib('openTypeOS2SuperscriptXSize', font.ttinfo.os2_y_superscript_x_size, 'int', scalable=1, scale=scale),
		info_lib('openTypeOS2SuperscriptYOffset', font.ttinfo.os2_y_superscript_y_offset, 'int', scalable=1, scale=scale),
		info_lib('openTypeOS2SuperscriptYSize', font.ttinfo.os2_y_superscript_y_size, 'int', scalable=1, scale=scale),
		info_lib('openTypeOS2Type', font.ttinfo.os2_fs_type, 'int_list'),
		info_lib('openTypeOS2TypoAscender', font.ttinfo.os2_s_typo_ascender, 'int', scalable=1, scale=scale),
		info_lib('openTypeOS2TypoDescender', font.ttinfo.os2_s_typo_descender, 'int', scalable=1, scale=scale),
		info_lib('openTypeOS2TypoLineGap', font.ttinfo.os2_s_typo_line_gap, 'int', scalable=1, scale=scale),
		info_lib('openTypeOS2UnicodeRanges', font.unicoderanges, 'int_list'),
		info_lib('openTypeOS2VendorID', font.vendor),
		info_lib('openTypeOS2WeightClass', font.weight_code, 'int'),
		info_lib('openTypeOS2WidthClass', FL_WIDTHS[font.width], 'int'),
		info_lib('openTypeOS2WinAscent', font.ttinfo.os2_us_win_ascent, 'int', scalable=1, scale=scale),
		info_lib('openTypeOS2WinDescent', font.ttinfo.os2_us_win_descent, 'int', scalable=1, scale=scale),
		info_lib('openTypeVheaCaretOffset', ufo.ttinfo.vhea_caret_offset, 'int'),
		info_lib('openTypeVheaCaretSlopeRise', ufo.ttinfo.vhea_caret_slope_rise, 'int'),
		info_lib('openTypeVheaCaretSlopeRun', ufo.ttinfo.vhea_caret_slope_run, 'int'),
		info_lib('openTypeVheaVertTypoAscender', ufo.ttinfo.vhea_vert_typo_ascender, 'int', scalable=1, scale=scale),
		info_lib('openTypeVheaVertTypoDescender', ufo.ttinfo.vhea_vert_typo_descender, 'int', scalable=1, scale=scale),
		info_lib('openTypeVheaVertTypoLineGap', ufo.ttinfo.vhea_vert_typo_line_gap, 'int', scalable=1, scale=scale),
		info_lib('postscriptBlueFuzz', font.blue_fuzz[0], 'int_float'),
		info_lib('postscriptBlueScale', font.blue_scale[0], 'float'),
		info_lib('postscriptBlueShift', font.blue_shift[0], 'int_float'),
		info_lib('postscriptBlueValues', font.blue_values[0], 'int_float_list', layered=1, scalable=1, scale=scale),
		info_lib('postscriptDefaultCharacter', font.default_character),
		info_lib('postscriptDefaultWidthX', font.default_width[0], 'int_float', layered=1),
		info_lib('postscriptFamilyBlues', font.family_blues[0], 'int_float_list', layered=1, scalable=1, scale=scale),
		info_lib('postscriptFamilyOtherBlues', font.family_other_blues[0], 'int_float_list', layered=1, scalable=1, scale=scale),
		info_lib('postscriptFontName', font.font_name),
		info_lib('postscriptForceBold', font.force_bold, 'bool'),
		info_lib('postscriptFullName', font.full_name),
		info_lib('postscriptIsFixedPitch', font.is_fixed_pitch, 'bool'),
		info_lib('postscriptNominalWidthX', ufo.fontinfo.nominal_width, 'int_float', scalable=1, scale=scale),
		info_lib('postscriptOtherBlues', font.other_blues[0], 'int_float_list', layered=1, scalable=1, scale=scale),
		info_lib('postscriptSlantAngle', font.slant_angle, 'float'),
		info_lib('postscriptStemSnapH', font.stem_snap_h[0], 'int_float_list', layered=1, scalable=1, scale=scale),
		info_lib('postscriptStemSnapV', font.stem_snap_v[0], 'int_float_list', layered=1, scalable=1, scale=scale),
		info_lib('postscriptUnderlinePosition', font.underline_position, 'int_float', scalable=1, scale=scale),
		info_lib('postscriptUnderlineThickness', font.underline_thickness, 'int_float', scalable=1, scale=scale),
		info_lib('postscriptUniqueID', _postscript_unique_id(font), 'int'),
		info_lib('postscriptWeightName', font.weight),
		info_lib('postscriptWindowsCharacterSet', font.ms_charset, 'int'),
		info_lib('styleMapFamilyName', font.menu_name),
		info_lib('styleMapStyleName', FL_STYLES[font.font_style].lower()),
		info_lib('styleName', font.style_name),
		info_lib('trademark', font.trademark),
		info_lib('unitsPerEm', font.upm, 'int', scalable=1, scale=scale),
		info_lib('versionMajor', font.version_major, 'int'),
		info_lib('versionMinor', font.version_minor, 'int'),
		info_lib('xHeight', font.x_height[0], 'int', layered=1, scalable=1, scale=scale),
		]

	if ufo.version == 3:
		info.extend([
			info_lib('guidelines', _guidelines(font, ufo), 'dict_list', scalable=1, scale=scale),
			info_lib('openTypeGaspRangeRecords', _gasp_records(font), 'dict_list'),
			info_lib('openTypeNameRecords', _name_records(font), 'dict_list'),
			])

	return info
