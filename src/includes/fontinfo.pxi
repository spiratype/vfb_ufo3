# fontinfo.pxi

@cython.final
cdef class fontinfo_dict(dict):

	def __init__(self):
		for key in FONTINFO_ATTRS:
			PyDict_SetItem(self, key, None)

	def __reduce__(self):
		return self.__class__

	def update(self, other):
		for key, value in items(other):
			if key in self:
				PyDict_SetItem(self, key, value)

	def items(self):
		return ((key, self[key]) for key in FONTINFO_ATTRS)

# GLYPH SETS

NOMINAL_WIDTH_GLYPHS = (
	0x2E, 0x2C, 0x21, 0x3F, 0x3A, 0x3B, 0x20, 0x30, 0x31, 0x32, 0x33, 0x34, 0x35,
	0x36, 0x37, 0x38, 0x39, 0x41, 0x42, 0x43, 0x44, 0x45, 0x46, 0x47, 0x48, 0x49,
	0x4A, 0x4B, 0x4C, 0x4D, 0x4E, 0x4F, 0x50, 0x51, 0x52, 0x53, 0x54, 0x55, 0x56,
	0x57, 0x58, 0x59, 0x5A, 0x61, 0x62, 0x63, 0x64, 0x65, 0x66, 0x67, 0x68, 0x69,
	0x6A, 0x6B, 0x6C, 0x6D, 0x6E, 0x6F, 0x70, 0x71, 0x72, 0x73, 0x74, 0x75, 0x76,
	0x77, 0x78, 0x79, 0x7A,
	)

# CODE PAGES

CODE_PAGES = {
	0, 1, 2, 3, 4, 5, 6, 7, 8, 16, 17, 18, 19, 20, 21, 48, 49,
	50, 51, 52, 53, 54, 55, 56, 57, 58, 59, 60, 61, 62, 63,
	}

WIDTHS = {
	'Ultra-condensed': 1,
	'Extra-condensed': 2,
	'Condensed': 3,
	'Semi-condensed': 4,
	'Medium (normal)': 5,
	'Semi-expanded': 6,
	'Expanded': 7,
	'Extra-expanded': 8,
	'Ultra-expanded': 9,
	}

FL_WIDTHS = {
	'Ultra-condensed': 1,
	'Extra-condensed': 2,
	'Condensed': 3,
	'Semi-condensed': 4,
	'Medium (normal)': 5,
	'Normal': 5,
	'Semi-expanded': 6,
	'Expanded': 7,
	'Extra-expanded': 8,
	'Ultra-expanded': 9,
	}

REV_FL_WIDTHS = {value: key.encode('cp1252')  for key, value in items(WIDTHS)}

WEIGHTS = {
	'UltraLight': 100,
	'ExtraLight': 200,
	'Light': 300,
	'Regular': 400,
	'Medium': 500,
	'SemiBold': 600,
	'Bold': 700,
	'ExtraBold': 800,
	'Black': 900,
	'ExtraBlack': 1000,
	}

WEIGHT_CODES = {
	'All (Multiple Master)': 200,
	'Thin': 200,
	'UltraLight': 100,
	'ExtraLight': 200,
	'Light': 300,
	'Book': 400,
	'Regular': 400,
	'Normal': 400,
	'Medium': 500,
	'DemiBold': 600,
	'SemiBold': 600,
	'Bold': 700,
	'ExtraBold': 800,
	'Black': 900,
	'Heavy': 900,
	'Ultra': 900,
	'UltraBlack': 900,
	'Fat': 1000,
	'ExtraBlack': 1000,
	}

# UFO CONFIGURABLE ATTRIBUTE SETS

CONFIGURABLE_ATTRS = {
	'ascender',
	'capHeight',
	'copyright',
	'descender',
	'familyName',
	'italicAngle',
	'note',
	'openTypeHeadFlags',
	'openTypeHheaAscender',
	'openTypeHheaCaretOffset',
	'openTypeHheaCaretSlopeRise',
	'openTypeHheaCaretSlopeRun',
	'openTypeHheaDescender',
	'openTypeHheaLineGap',
	'openTypeNameCompatibleFullName',
	'openTypeNameDescription',
	'openTypeNameDesigner',
	'openTypeNameDesignerURL',
	'openTypeNameLicense',
	'openTypeNameLicenseURL',
	'openTypeNameManufacturer',
	'openTypeNameManufacturerURL',
	'openTypeNamePreferredFamilyName',
	'openTypeNamePreferredSubfamilyName',
	'openTypeNameSampleText',
	'openTypeNameUniqueID',
	'openTypeNameVersion',
	'openTypeNameWWSFamilyName',
	'openTypeNameWWSSubfamilyName',
	'openTypeOS2CodePageRanges',
	'openTypeOS2FamilyClass',
	'openTypeOS2Panose',
	'openTypeOS2Selection',
	'openTypeOS2StrikeoutPosition',
	'openTypeOS2StrikeoutSize',
	'openTypeOS2SubscriptXOffset',
	'openTypeOS2SubscriptXSize',
	'openTypeOS2SubscriptYOffset',
	'openTypeOS2SubscriptYSize',
	'openTypeOS2SuperscriptXOffset',
	'openTypeOS2SuperscriptXSize',
	'openTypeOS2SuperscriptYOffset',
	'openTypeOS2SuperscriptYSize',
	'openTypeOS2Type',
	'openTypeOS2TypoAscender',
	'openTypeOS2TypoDescender',
	'openTypeOS2TypoLineGap',
	'openTypeOS2UnicodeRanges',
	'openTypeOS2VendorID',
	'openTypeOS2WeightClass',
	'openTypeOS2WidthClass',
	'openTypeOS2WinAscent',
	'openTypeOS2WinDescent',
	'postscriptBlueFuzz',
	'postscriptBlueScale',
	'postscriptBlueShift',
	'postscriptBlueValues',
	'postscriptDefaultCharacter',
	'postscriptFamilyBlues',
	'postscriptFamilyOtherBlues',
	'postscriptFontName',
	'postscriptForceBold',
	'postscriptFullName',
	'postscriptIsFixedPitch',
	'postscriptOtherBlues',
	'postscriptSlantAngle',
	'postscriptStemSnapH',
	'postscriptStemSnapV',
	'postscriptUnderlinePosition',
	'postscriptUnderlineThickness',
	'postscriptUniqueID',
	'postscriptWeightName',
	'postscriptWindowsCharacterSet',
	'styleMapFamilyName',
	'styleMapStyleName',
	'styleName',
	'trademark',
	'unitsPerEm',
	'versionMajor',
	'versionMinor',
	'xHeight',
	}

STRING_ATTRS = {
	'copyright',
	'familyName',
	'note',
	'openTypeNameCompatibleFullName',
	'openTypeNameDescription',
	'openTypeNameDesigner',
	'openTypeNameDesignerURL',
	'openTypeNameLicenseURL',
	'openTypeNameManufacturer',
	'openTypeNameManufacturerURL',
	'openTypeNamePreferredFamilyName',
	'openTypeNamePreferredSubfamilyName',
	'openTypeNameSampleText',
	'openTypeNameUniqueID',
	'openTypeNameVersion',
	'openTypeOS2VendorID',
	'postscriptDefaultCharacter',
	'postscriptFontName',
	'postscriptFullName',
	'postscriptWeightName',
	'styleMapFamilyName',
	'styleMapStyleName',
	'styleName',
	'trademark',
	}

NAME_RECORDS_ATTRS = {
	'copyright': 0, # font.copyright 0
	'familyName': 1, # font.family_name 1
	'styleName': 2, # font.style_name 2
	'openTypeNameUniqueID': 3, # font.tt_u_id 3
	'postscriptFullName': 4, # font.full_name 4
	'postscriptFontName': 6, # font.font_name 6
	'trademark': 7, # font.trademark 7
	'openTypeNameManufacturer': 8, # font.source 8
	'openTypeNameDesigner': 9, # font.designer 9
	'openTypeNameDescription': 10, # font.notice 10
	'openTypeNameManufacturerURL': 11, # font.vendor_url 11
	'openTypeNameDesignerURL': 12, # font.designer_url 12
	'openTypeNameLicense': 13, # font.license 13
	'openTypeNameLicenseURL': 14, # font.license_url 14
	'openTypeNamePreferredFamilyName': 16, # font.pref_family_name 16
	'openTypeNamePreferredSubfamilyName': 17, # font.pref_style_name 17
	}

INT_ATTRS = {
	'openTypeHheaCaretSlopeRise',
	'openTypeHheaCaretSlopeRun',
	'openTypeOS2WeightClass',
	'openTypeOS2WidthClass',
	'postscriptUniqueID',
	'versionMajor',
	'versionMinor',
	}

FLOAT_ATTRS = {
	'italicAngle',
	'postscriptSlantAngle',
	}

INT_FLOAT_ATTRS = {
	'ascender',
	'capHeight',
	'descender',
	'openTypeHeadLowestRecPPEM',
	'openTypeHheaAscender',
	'openTypeHheaCaretOffset',
	'openTypeHheaDescender',
	'openTypeHheaLineGap',
	'openTypeOS2StrikeoutPosition',
	'openTypeOS2StrikeoutSize',
	'openTypeOS2SubscriptXOffset',
	'openTypeOS2SubscriptXSize',
	'openTypeOS2SubscriptYOffset',
	'openTypeOS2SubscriptYSize',
	'openTypeOS2SuperscriptXOffset',
	'openTypeOS2SuperscriptXSize',
	'openTypeOS2SuperscriptYOffset',
	'openTypeOS2SuperscriptYSize',
	'openTypeOS2TypoAscender',
	'openTypeOS2TypoDescender',
	'openTypeOS2TypoLineGap',
	'openTypeOS2WinAscent',
	'openTypeOS2WinDescent',
	'postscriptBlueFuzz',
	'postscriptBlueShift',
	'postscriptDefaultWidthX',
	'postscriptNominalWidthX',
	'postscriptUnderlinePosition',
	'postscriptUnderlineThickness',
	'unitsPerEm',
	'xHeight',
	}

NUM_ATTRS = INT_ATTRS | FLOAT_ATTRS | INT_FLOAT_ATTRS

BOOL_ATTRS = {
	'postscriptIsFixedPitch',
	'postscriptForceBold',
	}

INT_LIST_ATTRS = {
	'openTypeHeadFlags',
	'openTypeOS2CodePageRanges',
	'openTypeOS2FamilyClass',
	'openTypeOS2Panose',
	'openTypeOS2Selection',
	'openTypeOS2Type',
	'openTypeOS2UnicodeRanges',
	'postscriptWindowsCharacterSet',
	}

INT_FLOAT_LIST_ATTRS = {
	'postscriptBlueValues',
	'postscriptFamilyBlues',
	'postscriptFamilyOtherBlues',
	'postscriptOtherBlues',
	'postscriptStemSnapH',
	'postscriptStemSnapV',
	}

DICT_LIST_ATTRS = {
	'guidelines',
	'openTypeGaspRangeRecords',
	'openTypeNameRecords',
	}

LIST_ATTRS = INT_LIST_ATTRS | INT_FLOAT_LIST_ATTRS | DICT_LIST_ATTRS

SCALABLE_ATTRS = {
	'ascender',
	'capHeight',
	'descender',
	'openTypeHheaAscender',
	'openTypeHheaDescender',
	'openTypeHheaLineGap',
	'openTypeOS2StrikeoutPosition',
	'openTypeOS2StrikeoutPosition',
	'openTypeOS2StrikeoutSize',
	'openTypeOS2SubscriptXOffset',
	'openTypeOS2SubscriptXSize',
	'openTypeOS2SubscriptYOffset',
	'openTypeOS2SubscriptYSize',
	'openTypeOS2SuperscriptXOffset',
	'openTypeOS2SuperscriptXSize',
	'openTypeOS2SuperscriptYOffset',
	'openTypeOS2SuperscriptYSize',
	'openTypeOS2TypoAscender',
	'openTypeOS2TypoDescender',
	'openTypeOS2TypoLineGap',
	'openTypeOS2WinAscent',
	'openTypeOS2WinDescent',
	'postscriptBlueValues',
	'postscriptOtherBlues',
	'postscriptNominalWidthX',
	'postscriptUnderlinePosition',
	'postscriptUnderlineThickness',
	'guidelines',
	'xHeight',
	}

LAYERED_ATTRS = {
	'ascender',
	'capHeight',
	'descender',
	'postscriptBlueFuzz',
	'postscriptBlueScale',
	'postscriptBlueShift',
	'postscriptBlueValues',
	'postscriptDefaultWidthX',
	'postscriptFamilyBlues',
	'postscriptFamilyOtherBlues',
	'postscriptForceBold',
	'postscriptOtherBlues',
	'postscriptStemSnapH',
	'postscriptStemSnapV',
	'xHeight',
	}

FL_STYLES = {
	1: 'italic',
	32: 'bold',
	33: 'bold italic',
	64: 'regular',
	}

REV_FL_STYLES = reverse_dict(FL_STYLES)

GUIDELINE_AXES = {0: 'y', 1: 'x'}

FONTINFO_ATTRS = (
	'ascender',
	'descender',
	'capHeight',
	'xHeight',
	'guidelines',
	'copyright',
	'familyName',
	'italicAngle',
	'styleMapFamilyName',
	'styleMapStyleName',
	'styleName',
	'trademark',
	'unitsPerEm',
	'versionMajor',
	'versionMinor',
	'note',
	'openTypeHeadCreated',
	'openTypeHeadFlags',
	'openTypeHeadLowestRecPPEM',
	'openTypeHheaAscender',
	'openTypeHheaCaretOffset',
	'openTypeHheaCaretSlopeRise',
	'openTypeHheaCaretSlopeRun',
	'openTypeHheaDescender',
	'openTypeHheaLineGap',
	'openTypeNameCompatibleFullName',
	'openTypeNameDescription',
	'openTypeNameDesigner',
	'openTypeNameDesignerURL',
	'openTypeGaspRangeRecords',
	'openTypeNameLicense',
	'openTypeNameLicenseURL',
	'openTypeNameManufacturer',
	'openTypeNameManufacturerURL',
	'openTypeNamePreferredFamilyName',
	'openTypeNamePreferredSubfamilyName',
	'openTypeNameRecords',
	'openTypeNameSampleText',
	'openTypeNameUniqueID',
	'openTypeNameVersion',
	'openTypeNameWWSFamilyName',
	'openTypeNameWWSSubfamilyName',
	'openTypeOS2CodePageRanges',
	'openTypeOS2FamilyClass',
	'openTypeOS2Panose',
	'openTypeOS2Selection',
	'openTypeOS2StrikeoutPosition',
	'openTypeOS2StrikeoutSize',
	'openTypeOS2SubscriptXOffset',
	'openTypeOS2SubscriptXSize',
	'openTypeOS2SubscriptYOffset',
	'openTypeOS2SubscriptYSize',
	'openTypeOS2SuperscriptXOffset',
	'openTypeOS2SuperscriptXSize',
	'openTypeOS2SuperscriptYOffset',
	'openTypeOS2SuperscriptYSize',
	'openTypeOS2Type',
	'openTypeOS2TypoAscender',
	'openTypeOS2TypoDescender',
	'openTypeOS2TypoLineGap',
	'openTypeOS2UnicodeRanges',
	'openTypeOS2VendorID',
	'openTypeOS2WeightClass',
	'openTypeOS2WidthClass',
	'openTypeOS2WinAscent',
	'openTypeOS2WinDescent',
	'openTypeVheaCaretOffset',
	'openTypeVheaCaretSlopeRise',
	'openTypeVheaCaretSlopeRun',
	'openTypeVheaVertTypoAscender',
	'openTypeVheaVertTypoDescender',
	'openTypeVheaVertTypoLineGap',
	'postscriptBlueFuzz',
	'postscriptBlueScale',
	'postscriptBlueShift',
	'postscriptBlueValues',
	'postscriptDefaultCharacter',
	'postscriptDefaultWidthX',
	'postscriptFamilyBlues',
	'postscriptFamilyOtherBlues',
	'postscriptFontName',
	'postscriptForceBold',
	'postscriptFullName',
	'postscriptIsFixedPitch',
	'postscriptNominalWidthX',
	'postscriptOtherBlues',
	'postscriptSlantAngle',
	'postscriptStemSnapH',
	'postscriptStemSnapV',
	'postscriptUnderlinePosition',
	'postscriptUnderlineThickness',
	'postscriptUniqueID',
	'postscriptWeightName',
	'postscriptWindowsCharacterSet',
	)
