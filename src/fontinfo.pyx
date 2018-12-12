# coding: future_fstrings
# cython: wraparound=False, boundscheck=False
# cython: infer_types=True, cdivision=True
# cython: optimize.use_switch=True, optimize.unpack_method_calls=True
from __future__ import (absolute_import, division, print_function,
	unicode_literals)

from tools cimport int_float, element

import collections
import datetime
import math
import os

from vfb_ufo3.constants import (CODEPAGES, UNICODE_RANGES, FL_WIN_CHARSET,
	REVERSED_FL_WIN_CHARSET, WIDTHS, REVERSED_WIDTHS, FL_STYLES,
	REVERSED_FL_STYLES, WEIGHTS, REVERSED_WEIGHTS, WEIGHT_CODES,
	FLC_HEADER, FLC_GROUP_MARKER, FLC_GLYPHS_MARKER,
	FLC_KERNING_MARKER, FLC_END_MARKER, WIN_1252, MACOS_ROMAN,
	CONFIGURABLE_ATTRIBUTES, STRING_ATTRIBUTES, INT_ATTRIBUTES,
	FLOAT_ATTRIBUTES, INT_FLOAT_ATTRIBUTES, BOOL_ATTRIBUTES,
	INT_LIST_ATTRIBUTES, INT_FLOAT_LIST_ATTRIBUTES)
from vfb_ufo3.future import items, open, range, str, zip

from FL import fl

NOMINAL_WIDTH_GLYPH_SET = (
	'period', 'comma', 'exclam', 'question', 'colon',
	'semicolon', 'space', 'zero', 'one', 'two', 'three',
	'four', 'five', 'six', 'seven', 'eight', 'nine',
	'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M',
	'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z',
	'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l', 'm',
	'n', 'o', 'p', 'q', 'r', 's', 't', 'u', 'v', 'w', 'x', 'y', 'z',
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
		scale=0.0,):

		'''
		convert byte strings to unicode
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
		if value != None:
			if scalable and scale :
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
				if not isinstance(value, (bytes, unicode)):
					raise AttributeError(f"'{value}' is not a valid value for UFO attribute '{key}'\n"
						f"'{key}' must be a string value")

			elif key in INT_ATTRIBUTES:
				if not isinstance(value, int):
					raise AttributeError(f"'{value}' is not a valid value for UFO attribute '{key}'\n"
						f"'{key}' must be an integer value")

				if key == 'postscriptWindowsCharacterSet':
					if value < 1 or value > 20:
						raise AttributeError(f"'{value}' is not a valid value for UFO attribute '{key}'\n"
							f"'{key}' must be an integer between 1 and 20")
				elif key == 'openTypeOS2WidthClass':
					if value < 1 or value > 9:
						raise AttributeError(f"'{value}' is not a valid value for UFO attribute '{key}'\n"
							f"'{key}' must be an integer between 1 and 9")

			elif key in FLOAT_ATTRIBUTES:
				if not isinstance(value, float):
					raise AttributeError(f"'{value}' is not a valid value for UFO attribute '{key}'\n"
						f"'{key}' must be a float value")

			elif key in INT_FLOAT_ATTRIBUTES:
				if not isinstance(value, (int, float)):
					raise AttributeError(f"'{value}' is not a valid value for UFO attribute '{key}'\n"
						f"'{key}' must be an integer or float value")

			elif key in BOOL_ATTRIBUTES:
				if not isinstance(value, bool):
					raise AttributeError(f"'{value}' is not a valid value for UFO attribute '{key}'\n"
						f"'{key}' must be a boolean value")

			elif key in INT_LIST_ATTRIBUTES:
				if not isinstance(value, list):
					raise AttributeError(f"'{value}' is not a valid value for UFO attribute '{key}'\n"
						f"'{key}' must be a list")
				else:
					for item in value:
						if not isinstance(item, int):
							raise AttributeError(f"'{value}' contains an valid value ('{item}') for UFO attribute '{key}'\n"
								f"'{key}' items must be integers")

				if key == 'openTypeOS2Panose':
					if len(value) != len(font.panose):
						raise AttributeError(f"'{key}' must be a list of {len(font.panose)} integers")
				elif key == 'openTypeOS2FamilyClass':
					if len(value) != 2:
						raise AttributeError(f"'{key}' must be a list of 2 integers")
					else:
						for item in value:
							if item > 0 or item < 14:
								raise AttributeError(f"'{key}' integers must be values between 0 and 14")
				elif key == 'openTypeOS2CodePageRanges':
					for item in value:
						if item not in CODEPAGES:
							raise AttributeError(f"'{key}' requires codepages from the ulCodePageRange1-2 OS/2 specification")
				elif key == 'openTypeOS2UnicodeRanges':
					for item in value:
						if item not in UNICODE_RANGES:
							raise AttributeError(f"'{key}' requires codepages from the ulCodePageRange1-4 OS/2 specification")

			elif key in INT_FLOAT_LIST_ATTRIBUTES:
				if not isinstance(value, list):
					raise AttributeError(f"'{value}' is not a valid value for UFO attribute '{key}'\n'{key}' must be a list")
				else:
					for item in value:
						if not isinstance(item, (int, float)):
							raise AttributeError(f"'{value}' contains an valid value ('{item}') for UFO attribute '{key}.\n"
								f"'{key}' items must be integers or floats")

	ascender = instance_attributes.get('ascender')
	if ascender is not None:
		font.ascender[0] = int(ascender)

	cap_height = instance_attributes.get('capHeight')
	if cap_height is not None:
		font.cap_height[0] = int(cap_height)

	font_copyright = instance_attributes.get('copyright')
	if font_copyright is not None:
		font.copyright = str(font_copyright).encode('cp1252')

	descender = instance_attributes.get('descender')
	if descender is not None:
		font.descender[0] = int(descender)

	family_name = instance_attributes.get('familyName')
	if family_name is not None:
		font.family_name = bytes(str(family_name))

	menu_name = instance_attributes.get('styleMapFamilyName')
	if menu_name is not None:
		font.menu_name = bytes(str(menu_name))

	ufo.fontinfo.font_style = instance_attributes.get('styleMapStyleName')
	if ufo.fontinfo.font_style not in ('regular', 'italic', 'bold', 'bold italic'):
		ufo.fontinfo.font_style = str(FL_STYLES[font.font_style].lower())

	style_name = instance_attributes.get('styleName')
	if style_name is not None:
		font.style_name = bytes(str(style_name))

	trademark = instance_attributes.get('trademark')
	if trademark is not None:
		font.trademark = str(trademark).encode('cp1252')

	x_height = instance_attributes.get('xHeight')
	if x_height is not None:
		font.x_height[0] = int(x_height)

	italic_angle = instance_attributes.get('italicAngle')
	if italic_angle is not None:
		font.italic_angle = float(italic_angle)

	note = instance_attributes.get('note')
	if note is not None:
		font.note = str(note).encode('cp1252')

	upm = instance_attributes.get('unitsPerEm')
	if upm is not None:
		font.upm = int(upm)

	version_major = instance_attributes.get('versionMajor')
	if version_major is not None:
		font.version_major = int(version_major)

	version_minor = instance_attributes.get('versionMinor')
	if version_minor is not None:
		font.version_minor = int(version_minor)

	font_style = instance_attributes.get('openTypeHeadFlags')
	if font_style is not None:
		font.font_style = int(_font_style(font_style))

	mac_compatible = instance_attributes.get('openTypeNameCompatibleFullName')
	if mac_compatible is not None:
		font.mac_compatible = bytes(str(mac_compatible))

	notice = instance_attributes.get('openTypeNameDescription')
	if notice is not None:
		font.notice = str(notice).encode('cp1252')

	designer = instance_attributes.get('openTypeNameDesigner')
	if designer is not None:
		font.designer = str(designer).encode('cp1252')

	designer_url = instance_attributes.get('openTypeNameDesignerURL')
	if designer_url is not None:
		font.designer_url = bytes(str(designer_url))

	source = instance_attributes.get('openTypeNameManufacturer')
	if source is not None:
		font.source = str(source).encode('cp1252')

	vendor_url = instance_attributes.get('openTypeNameManufacturerURL')
	if vendor_url is not None:
		font.vendor_url = bytes(str(vendor_url))

	ot_license = instance_attributes.get('openTypeNameLicense')
	if ot_license is not None:
		font.license = str(ot_license).encode('cp1252')

	license_url = instance_attributes.get('openTypeNameLicenseURL')
	if license_url is not None:
		font.license_url = bytes(str(license_url))

	pref_family_name = instance_attributes.get('openTypeNamePreferredFamilyName')
	if pref_family_name is not None:
		font.pref_family_name = bytes(str(pref_family_name))

	pref_style_name = instance_attributes.get('openTypeNamePreferredSubfamilyName')
	if pref_style_name is not None:
		font.pref_style_name = bytes(str(pref_style_name))

	sample_font_text = instance_attributes.get('openTypeNameSampleText')
	if sample_font_text is not None:
		ufo.fontinfo.sample_font_text = sample_font_text

	tt_u_id = instance_attributes.get('openTypeNameUniqueID')
	if tt_u_id is not None:
		font.tt_u_id = bytes(str(tt_u_id))

	version = instance_attributes.get('openTypeNameVersion')
	if version is not None:
		font.version = bytes(str(version))

	ufo.fontinfo.wws_family_name = instance_attributes.get('openTypeNameWWSFamilyName')
	ufo.fontinfo.wws_sub_family_name = instance_attributes.get('openTypeNameWWSSubfamilyName')

	codepages = instance_attributes.get('openTypeOS2CodePageRanges')
	if codepages is not None:
		font.codepages = [int(i) for i in codepages if i in CODEPAGES]

	head_lowest_rec_ppem = instance_attributes.get('openTypeHeadLowestRecPPEM')
	if head_lowest_rec_ppem is not None:
		font.ttinfo.head_lowest_rec_ppem = int(head_lowest_rec_ppem)

	hhea_ascender = instance_attributes.get('openTypeHheaAscender')
	if hhea_ascender is not None:
		font.ttinfo.hhea_ascender = int(hhea_ascender)

	ufo.ttinfo.hhea_caret_slope_rise = instance_attributes.get('openTypeHheaCaretSlopeRise')
	ufo.ttinfo.hhea_caret_slope_run = instance_attributes.get('openTypeHheaCaretSlopeRun')
	ufo.ttinfo.hhea_caret_offset = instance_attributes.get('openTypeHheaCaretOffset')
	if ufo.ttinfo.hhea_caret_offset is None:
		ufo.ttinfo.hhea_caret_offset = 0

	hhea_descender = instance_attributes.get('openTypeHheaDescender')
	if hhea_descender is not None:
		font.ttinfo.hhea_descender = int(hhea_descender)

	hhea_line_gap = instance_attributes.get('openTypeHheaLineGap')
	if hhea_line_gap is not None:
		font.ttinfo.hhea_line_gap = int(hhea_line_gap)

	os2_s_family_class = instance_attributes.get('openTypeOS2FamilyClass')
	if os2_s_family_class is not None:
		font.ttinfo.os2_s_family_class = int(os2_s_family_class[0] * 2 + os2_s_family_class[1])

	panose = instance_attributes.get('openTypeOS2Panose')
	if panose is not None:
		for i, j in enumerate(panose):
			font.panose[i] = int(j)

	os2_fs_selection = instance_attributes.get('openTypeOS2Selection')
	if os2_fs_selection is not None:
		font.ttinfo.os2_fs_selection = int(os2_fs_selection)

	os2_y_subscript_x_offset = instance_attributes.get('openTypeOS2SubscriptXOffset')
	if os2_y_subscript_x_offset is not None:
		font.ttinfo.os2_y_subscript_x_offset = int(os2_y_subscript_x_offset)

	os2_y_subscript_x_size = instance_attributes.get('openTypeOS2SubscriptXSize')
	if os2_y_subscript_x_size is not None:
		font.ttinfo.os2_y_subscript_x_size = int(os2_y_subscript_x_size)

	os2_y_subscript_y_offset = instance_attributes.get('openTypeOS2SubscriptYOffset')
	if os2_y_subscript_y_offset is not None:
		font.ttinfo.os2_y_subscript_y_offset = int(os2_y_subscript_y_offset)

	os2_y_subscript_y_size = instance_attributes.get('openTypeOS2SubscriptYSize')
	if os2_y_subscript_y_size is not None:
		font.ttinfo.os2_y_subscript_y_size = int(os2_y_subscript_y_size)

	os2_y_superscript_x_offset = instance_attributes.get('openTypeOS2SuperscriptXOffset')
	if os2_y_superscript_x_offset is not None:
		font.ttinfo.os2_y_superscript_x_offset = int(os2_y_superscript_x_offset)

	os2_y_superscript_x_size = instance_attributes.get('openTypeOS2SuperscriptXSize')
	if os2_y_superscript_x_size is not None:
		font.ttinfo.os2_y_superscript_x_size = int(os2_y_superscript_x_size)

	os2_y_superscript_y_offset = instance_attributes.get('openTypeOS2SuperscriptYOffset')
	if os2_y_superscript_y_offset is not None:
		font.ttinfo.os2_y_superscript_y_offset = int(os2_y_superscript_y_offset)

	os2_y_superscript_y_size = instance_attributes.get('openTypeOS2SuperscriptYSize')
	if os2_y_superscript_y_size is not None:
		font.ttinfo.os2_y_superscript_y_size = int(os2_y_superscript_y_size)

	os2_y_strikeout_size = instance_attributes.get('openTypeOS2StrikeoutSize')
	if os2_y_strikeout_size is not None:
		font.ttinfo.os2_y_strikeout_size = int(os2_y_strikeout_size)

	os2_y_strikeout_position = instance_attributes.get('openTypeOS2StrikeoutPosition')
	if os2_y_strikeout_position is not None:
		font.ttinfo.os2_y_strikeout_position = int(os2_y_strikeout_position)

	unicoderanges = instance_attributes.get('openTypeOS2UnicodeRanges')
	if unicoderanges is not None:
		font.unicoderanges = [int(i) for i in unicoderanges if i in UNICODE_RANGES]

	os2_fs_type = instance_attributes.get('openTypeOS2Type')
	if os2_fs_type is not None:
		font.ttinfo.os2_fs_type = int(os2_fs_type)

	os2_s_typo_ascender = instance_attributes.get('openTypeOS2TypoAscender')
	if os2_s_typo_ascender is not None:
		font.ttinfo.os2_s_typo_ascender = int(os2_s_typo_ascender)

	os2_s_typo_descender = instance_attributes.get('openTypeOS2TypoDescender')
	if os2_s_typo_descender is not None:
		font.ttinfo.os2_s_typo_descender = int(os2_s_typo_descender)

	os2_s_typo_line_gap = instance_attributes.get('openTypeOS2TypoLineGap')
	if os2_s_typo_line_gap is not None:
		font.ttinfo.os2_s_typo_line_gap = int(os2_s_typo_line_gap)

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
			font.ttinfo.os2_us_weight_class = font.weight_code
			font.weight = bytes(str(REVERSED_WEIGHTS[weight_code]))

	width = instance_attributes.get('openTypeOS2WidthClass')
	if width in REVERSED_WIDTHS:
		font.width = bytes(str(REVERSED_WIDTHS[width]))
		font.ttinfo.os2_us_width_class = int(width)

	os2_us_win_ascent = instance_attributes.get('openTypeOS2WinAscent')
	if os2_us_win_ascent is not None:
		font.ttinfo.os2_us_win_ascent = int(os2_us_win_ascent)

	os2_us_win_descent = instance_attributes.get('openTypeOS2WinDescent')
	if os2_us_win_descent is not None:
		font.ttinfo.os2_us_win_descent = int(os2_us_win_descent)

	font_name = instance_attributes.get('postscriptFontName')
	if font_name is not None:
		font.font_name = bytes(str(font_name))

	full_name = instance_attributes.get('postscriptFullName')
	if full_name is not None:
		font.full_name = bytes(str(full_name))

	slant_angle = instance_attributes.get('postscriptSlantAngle')
	if slant_angle is not None:
		try:
			font.slant_angle = float(slant_angle)
		except:
			pass

	blue_values = instance_attributes.get('postscriptBlueValues')
	if blue_values is not None:
		font.blue_values[0] = list(blue_values)

	family_blues = instance_attributes.get('postscriptFamilyBlues')
	if family_blues is not None:
		font.blue_shift[0] = list(family_blues)

	family_other_blues = instance_attributes.get('postscriptFamilyOtherBlues')
	if family_other_blues is not None:
		font.family_other_blues[0] = list(family_other_blues)

	other_blues = instance_attributes.get('postscriptOtherBlues')
	if other_blues is not None:
		font.other_blues[0] = list(other_blues)

	blue_fuzz = instance_attributes.get('postscriptBlueFuzz')
	if blue_fuzz is not None:
		font.blue_fuzz[0] = int(blue_fuzz)

	blue_scale = instance_attributes.get('postscriptBlueScale')
	if blue_scale is not None:
		font.blue_scale[0] = float(blue_scale)

	blue_shift = instance_attributes.get('postscriptBlueShift')
	if blue_shift is not None:
		font.blue_shift[0] = int(blue_shift)

	default_character = instance_attributes.get('postscriptDefaultCharacter')
	if default_character is not None:
		font.default_character = bytes(str(default_character))

	default_width = instance_attributes.get('postscriptDefaultWidthX')
	if default_width is not None:
		font.default_width[0] = int(default_width)

	force_bold = instance_attributes.get('postscriptForceBold')
	if force_bold is not None:
		font.force_bold[0] = int(force_bold)

	is_fixed_pitch = instance_attributes.get('postscriptIsFixedPitch')
	if is_fixed_pitch is not None:
		font.is_fixed_pitch = int(is_fixed_pitch)

	ufo.fontinfo.nominal_width = instance_attributes.get('postscriptNominalWidthX')
	if ufo.fontinfo.nominal_width is None:
		ufo.fontinfo.nominal_width = _nominal_width(font)

	stem_snap_h = instance_attributes.get('postscriptStemSnapH')
	if stem_snap_h is not None:
		font.stem_snap_h[0] = list(stem_snap_h)

	stem_snap_v = instance_attributes.get('postscriptStemSnapV')
	if stem_snap_v is not None:
		font.stem_snap_v[0] = list(stem_snap_v)

	underline_position = instance_attributes.get('postscriptUnderlinePosition')
	if underline_position is not None:
		font.underline_position = int(underline_position)

	underline_thickness = instance_attributes.get('postscriptUnderlineThickness')
	if underline_thickness is not None:
		font.underline_thickness = int(underline_thickness)

	postscript_id = instance_attributes.get('postscriptUniqueID')
	if postscript_id is not None:
		font.unique_id = int(postscript_id)

	weight = instance_attributes.get('postscriptWeightName')
	if weight is not None:
		font.weight = bytes(str(weight))

	ms_charset = instance_attributes.get('postscriptWindowsCharacterSet')
	if ms_charset and ms_charset in range(1, 20):
		font.ms_charset = REVERSED_FL_WIN_CHARSET[ms_charset]

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

	return int(round(widths / glyphs))

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
	j = int(math.log(font_style) / math.log(2))

	if i and j:
		return [0, j]
	if j:
		return [j]
	return [0]

cdef list _os2_family_class(int os2_family_class):

	'''
	convert FontLab family class attribute to UFO integer pair
	'''

	return [int(os2_family_class / 256), os2_family_class % 256]

cdef unicode _date():

	'''
	build date string

	>>> _date()
	2018/07/02 14:47:35
	'''

	return str(datetime.datetime.now()).replace('-', '/')[:19]

cdef dict _guideline(x, y, double angle=0.0, double scale=0.0):

	'''
	build guide dictionary
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
			))
			for gasp in font.ttinfo.gasp]

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
		info_lib('openTypeOS2WidthClass', WIDTHS[font.width], 'int'),
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
