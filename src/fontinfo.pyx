# coding: utf-8
# cython: wraparound=False
# cython: boundscheck=False
# cython: cdivision=True
# cython: auto_pickle=False
# distutils: extra_compile_args=[-fconcepts, -O3, -fno-strict-aliasing, -Wno-register]
# distutils: extra_link_args=[-fconcepts, -O3, -fno-strict-aliasing, -Wno-register]
from __future__ import absolute_import, division, unicode_literals, print_function
include 'includes/future.pxi'
include 'includes/cp1252.pxi'

import datetime
import math
import time
import unicodedata

from .user import print

include 'includes/string.pxi'
include 'includes/objects.pxi'
include 'includes/dict.pxi'
include 'includes/nameid.pxi'
include 'includes/fontinfo.pxi'

def fontinfo(ufo, font, user_attributes):
	start = time.clock()
	_fontinfo(ufo, font, user_attributes)
	ufo.instance_times.fontinfo = time.clock() - start

def _fontinfo(ufo, font, user_attributes):

	mapping = {
		'ascender': (font, 'ascender'),
		'capHeight': (font, 'cap_height'),
		'copyright': (font, 'copyright'),
		'descender': (font, 'descender'),
		'familyName': (font, 'family_name'),
		'italicAngle': (font, 'italic_angle'),
		'note': (font, 'note'),
		'openTypeHeadCreated': datetime.datetime.now().strftime('%Y/%m/%d %H:%M:%S'),
		'openTypeHeadFlags': _font_style(font.font_style),
		'openTypeHeadLowestRecPPEM': (font.ttinfo, 'head_lowest_rec_ppem'),
		'openTypeHheaAscender': (font.ttinfo, 'hhea_ascender'),
		'openTypeHheaCaretOffset': None,
		'openTypeHheaCaretSlopeRise': None,
		'openTypeHheaCaretSlopeRun': None,
		'openTypeHheaDescender': (font.ttinfo, 'hhea_descender'),
		'openTypeHheaLineGap': (font.ttinfo, 'hhea_line_gap'),
		'openTypeNameCompatibleFullName': (font, 'mac_compatible'),
		'openTypeNameDescription': (font, 'notice'),
		'openTypeNameDesigner': (font, 'designer'),
		'openTypeNameDesignerURL': (font, 'designer_url'),
		'openTypeNameLicense': (font, 'license'),
		'openTypeNameLicenseURL': (font, 'license_url'),
		'openTypeNameManufacturer': (font, 'source'),
		'openTypeNameManufacturerURL': (font, 'vendor_url'),
		'openTypeNamePreferredFamilyName': (font, 'pref_family_name'),
		'openTypeNamePreferredSubfamilyName': (font, 'pref_style_name'),
		'openTypeNameSampleText': 'The quick brown fox jumps over the lazy dog',
		'openTypeNameUniqueID': (font, 'tt_u_id'),
		'openTypeNameVersion': (font, 'version'),
		'openTypeNameWWSFamilyName': None,
		'openTypeNameWWSSubfamilyName': None,
		'openTypeOS2CodePageRanges': (font, 'codepages'),
		'openTypeOS2FamilyClass': _os2_family_class(font.ttinfo.os2_s_family_class),
		'openTypeOS2Panose': (font, 'panose'),
		'openTypeOS2Selection': (font.ttinfo, 'os2_fs_selection'),
		'openTypeOS2StrikeoutPosition': (font.ttinfo, 'os2_y_strikeout_position'),
		'openTypeOS2StrikeoutSize': (font.ttinfo, 'os2_y_strikeout_size'),
		'openTypeOS2SubscriptXOffset': (font.ttinfo, 'os2_y_subscript_x_offset'),
		'openTypeOS2SubscriptXSize': (font.ttinfo, 'os2_y_subscript_x_size'),
		'openTypeOS2SubscriptYOffset': (font.ttinfo, 'os2_y_subscript_y_offset'),
		'openTypeOS2SubscriptYSize': (font.ttinfo, 'os2_y_subscript_y_size'),
		'openTypeOS2SuperscriptXOffset': (font.ttinfo, 'os2_y_superscript_x_offset'),
		'openTypeOS2SuperscriptXSize': (font.ttinfo, 'os2_y_superscript_x_size'),
		'openTypeOS2SuperscriptYOffset': (font.ttinfo, 'os2_y_superscript_y_offset'),
		'openTypeOS2SuperscriptYSize': (font.ttinfo, 'os2_y_superscript_y_size'),
		'openTypeOS2Type': (font.ttinfo, 'os2_fs_type'),
		'openTypeOS2TypoAscender': (font.ttinfo, 'os2_s_typo_ascender'),
		'openTypeOS2TypoDescender': (font.ttinfo, 'os2_s_typo_descender'),
		'openTypeOS2TypoLineGap': (font.ttinfo, 'os2_s_typo_line_gap'),
		'openTypeOS2UnicodeRanges': (font, 'unicoderanges'),
		'openTypeOS2VendorID': (font, 'vendor'),
		'openTypeOS2WeightClass': (font, 'weight_code'),
		'openTypeOS2WidthClass': FL_WIDTHS[font.width],
		'openTypeOS2WinAscent': (font.ttinfo, 'os2_us_win_ascent'),
		'openTypeOS2WinDescent': (font.ttinfo, 'os2_us_win_descent'),
		'openTypeVheaCaretOffset': None,
		'openTypeVheaCaretSlopeRise': None,
		'openTypeVheaCaretSlopeRun': None,
		'openTypeVheaVertTypoAscender': None,
		'openTypeVheaVertTypoDescender': None,
		'openTypeVheaVertTypoLineGap': None,
		'postscriptBlueFuzz': (font, 'blue_fuzz'),
		'postscriptBlueScale': (font, 'blue_scale'),
		'postscriptBlueShift': (font, 'blue_shift'),
		'postscriptBlueValues': (font, 'blue_values'),
		'postscriptDefaultCharacter': (font, 'default_character'),
		'postscriptDefaultWidthX': (font, 'default_width'),
		'postscriptFamilyBlues': (font, 'family_blues'),
		'postscriptFamilyOtherBlues': (font, 'family_other_blues'),
		'postscriptFontName': (font, 'font_name'),
		'postscriptForceBold': (font, 'force_bold'),
		'postscriptFullName': (font, 'full_name'),
		'postscriptIsFixedPitch': (font, 'is_fixed_pitch'),
		'postscriptNominalWidthX': _nominal_width(font),
		'postscriptOtherBlues': (font, 'other_blues'),
		'postscriptSlantAngle': (font, 'slant_angle'),
		'postscriptStemSnapH': (font, 'stem_snap_h'),
		'postscriptStemSnapV': (font, 'stem_snap_v'),
		'postscriptUnderlinePosition': (font, 'underline_position'),
		'postscriptUnderlineThickness': (font, 'underline_thickness'),
		'postscriptUniqueID': _postscript_unique_id(font.unique_id),
		'postscriptWeightName': (font, 'weight'),
		'postscriptWindowsCharacterSet': (font, 'ms_charset'),
		'styleMapFamilyName': (font, 'menu_name'),
		'styleMapStyleName': FL_STYLES[font.font_style],
		'styleName': (font, 'style_name'),
		'trademark': (font, 'trademark'),
		'unitsPerEm': (ufo.opts, 'scale_to_upm'),
		'versionMajor': (font, 'version_major'),
		'versionMinor': (font, 'version_minor'),
		'xHeight': (font, 'x_height'),
		}

	user_attributes = decode_dict(user_attributes)
	user_attributes = _check_attributes(user_attributes)

	ufo.instance.fontinfo = fontinfo_dict()
	afdko = ufo.opts.afdko_parts

	if user_attributes:
		ufo.instance.fontinfo.update(user_attributes)

	for key, value in items(ufo.instance.fontinfo):

		# set user attributes
		if value is not None:

			if key in LAYERED_ATTRS and key in CONFIGURABLE_ATTRS:
				parent_value = getattr(*mapping[key])
				parent_value[0] = int(value)
				setattr(*mapping[key], value)

			elif key == 'openTypeOS2WidthClass':
				font.width = REV_FL_WIDTHS[value]

			elif key == 'styleMapStyleName':
				font.font_style = REV_FL_STYLES[value]

			elif isinstance(mapping[key], tuple):
				if key in STRING_ATTRS:
					new_value = py_bytes(value)
					if len(new_value) != len(value):
						new_value = ascii_bytes(value)
					setattr(*mapping[key], new_value)
				elif key in CONFIGURABLE_ATTRS:
					setattr(*mapping[key], value)

			continue

		# fill-in attributes not supplied by the user
		if key in mapping:

			if isinstance(mapping[key], tuple):
				if key in LAYERED_ATTRS:
					value = getattr(*mapping[key])[0]
				else:
					value = getattr(*mapping[key])
			else:
				value = mapping[key]

			if key in LIST_ATTRS:
				if isinstance(value, (int, float, basestring)):
					value = [value]
				elif not isinstance(value, list):
					value = list(value)

		if value:
			if key in SCALABLE_ATTRS and ufo.scale is not None:
				if key in LIST_ATTRS:
					value = [val * ufo.scale for val in value]
				else:
					value = value * ufo.scale

			if key in INT_FLOAT_ATTRS and value is not None:
				if int(value) == value:
					value = int(value)

			if key in INT_FLOAT_LIST_ATTRS and value is not None:
				value = [int(val) if int(val) == val else val for val in value]

			if isinstance(value, bytes):
				value = py_unicode(value)

			ufo.instance.fontinfo[key] = value

	if not ufo.build_masters:
		ufo.instance.fontinfo['openTypeNameRecords'] = _name_records(ufo, font)

	ufo.instance.fontinfo['guidelines'] = _guidelines(ufo, font)
	ufo.instance.fontinfo['openTypeGaspRangeRecords'] = _gasp_records(font)

	for key, value in ufo.instance.fontinfo.items():
		if not value:
			ufo.instance.fontinfo[key] = None


def _check_attributes(user_attributes):

	'''
	user-defined per-instance attributes must be verifed
	'''

	user_attributes = decode_dict(user_attributes)

	for attr, value in items(user_attributes):

		if attr not in CONFIGURABLE_ATTRS:
			print(f"'{attr}' is not a configurable attribute")
			continue

		if attr in STRING_ATTRS:
			if not isinstance(value, unicode):
				raise ValueError(f"'{value}' is not a valid value for UFO attribute '{attr}'\n"
					f"'{attr}' must be a string value not a {type(value)} value")

			if attr == 'styleMapStyleName':
				value = value.lower()
				if value not in REV_FL_STYLES:
					raise ValueError(f"'{value}' is not a valid value for UFO attribute '{attr}'\n"
						f"'{attr}' must be either 'regular', 'italic', 'bold', or 'bold italic'")

		elif attr in INT_ATTRS:
			if not isinstance(value, int):
				raise ValueError(f"'{value}' is not a valid value for UFO attribute '{attr}'\n"
					f"'{attr}' must be an integer value")

			if attr == 'postscriptWindowsCharacterSet':
				if value < 1 or value > 20:
					raise ValueError(f"'{value}' is not a valid value for UFO attribute '{attr}'\n"
						f"'{attr}' must be an integer between 1 and 20")

			elif attr == 'openTypeOS2WidthClass':
				if value < 1 or value > 9:
					raise ValueError(f"'{value}' is not a valid value for UFO attribute '{attr}'\n"
						f"'{attr}' must be an integer between 1 and 9")

		elif attr in FLOAT_ATTRS:
			if not isinstance(value, float):
				raise ValueError(f"'{value}' is not a valid value for UFO attribute '{attr}'\n"
					f"'{attr}' must be a float value")

		elif attr in INT_FLOAT_ATTRS:
			if not isinstance(value, (int, float)):
				raise ValueError(f"'{value}' is not a valid value for UFO attribute '{attr}'\n"
					f"'{attr}' must be an integer or float value")

		elif attr in BOOL_ATTRS:
			if not isinstance(value, (int, bool)):
				try:
					_ = bool(value)
				except ValueError:
					raise ValueError(f"'{value}' is not a valid value for UFO attribute '{attr}'\n"
						f"'{attr}' must be a boolean value or convertible to a boolean value")

		elif attr in INT_LIST_ATTRS:
			if not isinstance(value, list):
				raise ValueError(f"'{value}' is not a valid value for UFO attribute '{attr}'\n"
					f"'{attr}' must be a list")
			for item in value:
				if not isinstance(item, int):
					raise ValueError(f"'{value}' contains an valid value ('{item}') for UFO "
						f"attribute '{attr}'\n'{attr}' items must be integers")

			if attr == 'openTypeOS2Panose':
				if len(value) != 10:
					raise ValueError(f"'{attr}' must be a list of 10 integers")

			elif attr == 'openTypeOS2FamilyClass':
				if len(value) != 2:
					raise ValueError(f"'{attr}' must be a list of 2 integers")
				for item in value:
					if item > 0 or item < 14:
						raise ValueError(f"'{attr}' integers for must be values between 0 and 14")

			elif attr == 'openTypeOS2CodePageRanges':
				for item in value:
					if item not in CODE_PAGES:
						raise ValueError(f"'{attr}' requires codepages from the ulCodePageRange1-2"
							f" OS/2 specification")

			elif attr == 'openTypeOS2UnicodeRanges':
				for item in value:
					if item not in range(123):
						raise ValueError(f"'{attr}' requires codepages from the ulCodePageRange1-4"
							f" OS/2 specification")

		elif attr in INT_FLOAT_LIST_ATTRS:
			if not isinstance(value, list):
				raise ValueError(f"'{value}' is not a valid value for UFO attribute '{attr}'\n"
				f"'{attr}' must be a list")
			for item in value:
				if not isinstance(item, (int, float)):
					raise ValueError(f"'{value}' contains an invalid value ('{item}') for UFO"
						f" attribute '{attr}'.\n'{attr}' items must be integers or floats")

	return user_attributes


def _nominal_width(font):

	widths, glyphs = 0, 0
	for code_point in NOMINAL_WIDTH_GLYPHS:
		glyph_index = font.FindGlyph(code_point)
		if glyph_index != -1:
			widths += font[glyph_index].width
			glyphs += 1

	return int(round(widths / glyphs))


def _postscript_unique_id(unique_id):
	if unique_id > -1:
		return unique_id


def _font_style(font_style):

	if isinstance(font_style, list):
		if font_style == [0]:
			return 1
		if font_style == [5]:
			return 32
		if font_style == [0, 5]:
			return 33
		if font_style == [6]:
			return 64

	n = int(font_style)
	i, j = n % 2, int(math.log(n) / math.log(2))

	if i and j:
		return [0, j]
	if j:
		return [j]
	return [0]


def _os2_family_class(os2_family_class):
	return [int(os2_family_class / 256), os2_family_class % 256]


def _guideline(position, angle, scale, horizontal=0):

	if angle and scale:
		return {GUIDELINE_AXES[horizontal]: position*scale, 'angle': angle}
	if angle:
		return {GUIDELINE_AXES[horizontal]: position, 'angle': angle}
	if scale:
		return {GUIDELINE_AXES[horizontal]: position*scale}
	return {GUIDELINE_AXES[horizontal]: position}


def _guidelines(ufo, font):

	guides = []
	if font.hguides:
		guides += [_guideline(guide.positions[0], guide.angle, ufo.scale, 1)
			for guide in font.hguides]
	if font.vguides:
		guides += [_guideline(guide.positions[0], guide.angle, ufo.scale)
			for guide in font.vguides]

	return guides


def _gasp_records(font):

	def _gasp_record(gasp):
		record = ordered_dict()
		record['rangeMaxPPEM'] = gasp.ppm
		record['rangeGaspBehavior'] = [gasp.behavior]
		return record

	return [_gasp_record(gasp) for gasp in font.ttinfo.gasp]


def _name_records(ufo, font):

	def _name_record(name_id, platform_id, string):
		record = ordered_dict()
		record['nameID'] = name_id
		record['platformID'] = platform_id
		record['encodingID'] = ENC_IDS[platform_id]
		record['languageID'] = LANG_IDS[platform_id]
		record['string'] = nameid_str(string, platform_id, 0)
		return record

	records = []
	for key, name_id in items(NAME_RECORDS_ATTRS):
		string = ufo.instance.fontinfo[key]
		if string:
			for platform_id in (1, 3):
				records.append(_name_record(name_id, platform_id, string))

	return records
