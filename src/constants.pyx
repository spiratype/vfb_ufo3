# coding: future_fstrings
from __future__ import absolute_import, division, print_function, unicode_literals

from vfb2ufo.future import *

# XML

XML_DECLARATION = '<?xml version="1.0" encoding="UTF-8"?>\n'
PLIST_DOCTYPE = ('<!DOCTYPE plist PUBLIC "-//Apple Computer//DTD PLIST 1.0//EN"'
	' "http://www.apple.com/DTDs/PropertyList-1.0.dtd">\n')

# FL FILE

FL_ENC_HEADER = ('%%FONTLAB ENCODING: 1252; MS Windows 1252 Western (ANSI)\n'
	'%%GROUP:Type 1 World Microsoft\n')
FLC_HEADER = '%%FONTLAB CLASSES\n'
FLC_GROUP_MARKER = '%%CLASS'
FLC_GLYPHS_MARKER = '%%GLYPHS '
FLC_KERNING_MARKER = '%%KERNING'
FLC_END_MARKER = '%%END\n'

# DESIGNSPACE

AXIS_TAGS = {
	'Italic': 'ital',
	'OpticalSize': 'opsz',
	'Serif': 'serf',
	'Slant': 'slnt',
	'Width': 'wdth',
	'Weight': 'wght',
	}

# GLYPH SETS

NOMINAL_WIDTH_GLYPH_SET = (
	'period', 'comma', 'exclam', 'question', 'colon',
	'semicolon', 'space', 'zero', 'one', 'two', 'three',
	'four', 'five', 'six', 'seven', 'eight', 'nine',
	'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M',
	'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z',
	'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l', 'm',
	'n', 'o', 'p', 'q', 'r', 's', 't', 'u', 'v', 'w', 'x', 'y', 'z',
	)

# CODEPAGES

WIN_1252 = (
	0x00, None, 0x02, None, None, None, None, None,
	None, None, 0x09, 0x0a, None, None, 0x0d, None,
	None, None, None, None, None, None, None, None,
	0x20, 0x21, 0x22, 0x23, 0x24, 0x25, 0x26, 0x27,
	0x28, 0x29, 0x2a, 0x2b, 0x2c, 0x2d, 0x2e, 0x2f,
	0x30, 0x31, 0x32, 0x33, 0x34, 0x35, 0x36, 0x37,
	0x38, 0x39, 0x3a, 0x3b, 0x3c, 0x3d, 0x3e, 0x3f,
	0x40, 0x41, 0x42, 0x43, 0x44, 0x45, 0x46, 0x47,
	0x48, 0x49, 0x4a, 0x4b, 0x4c, 0x4d, 0x4e, 0x4f,
	0x50, 0x51, 0x52, 0x53, 0x54, 0x55, 0x56, 0x57,
	0x58, 0x59, 0x5a, 0x5b, 0x5c, 0x5d, 0x5e, 0x5f,
	0x60, 0x61, 0x62, 0x63, 0x64, 0x65, 0x66, 0x67,
	0x68, 0x69, 0x6a, 0x6b, 0x6c, 0x6d, 0x6e, 0x6f,
	0x70, 0x71, 0x72, 0x73, 0x74, 0x75, 0x76, 0x77,
	0x78, 0x79, 0x7a, 0x7b, 0x7c, 0x7d, 0x7e, None,
	0x20ac, None, 0x201a, 0x0192, 0x201e, 0x2026, 0x2020, 0x2021,
	0x02c6, 0x2030, 0x0160, 0x2039, 0x0152, None, 0x017d, None,
	None, 0x2018, 0x2019, 0x201c, 0x201d, 0x2022, 0x2013, 0x2014,
	0x02dc, 0x2122, 0x0161, 0x203a, 0x0153, None, 0x017e, 0x0178,
	0xa0, 0xa1, 0xa2, 0xa3, 0xa4, 0xa5, 0xa6, 0xa7,
	0xa8, 0xa9, 0xaa, 0xab, 0xac, 0xad, 0xae, 0xaf,
	0xb0, 0xb1, 0xb2, 0xb3, 0xb4, 0xb5, 0xb6, 0xb7,
	0xb8, 0xb9, 0xba, 0xbb, 0xbc, 0xbd, 0xbe, 0xbf,
	0xc0, 0xc1, 0xc2, 0xc3, 0xc4, 0xc5, 0xc6, 0xc7,
	0xc8, 0xc9, 0xca, 0xcb, 0xcc, 0xcd, 0xce, 0xcf,
	0xd0, 0xd1, 0xd2, 0xd3, 0xd4, 0xd5, 0xd6, 0xd7,
	0xd8, 0xd9, 0xda, 0xdb, 0xdc, 0xdd, 0xde, 0xdf,
	0xe0, 0xe1, 0xe2, 0xe3, 0xe4, 0xe5, 0xe6, 0xe7,
	0xe8, 0xe9, 0xea, 0xeb, 0xec, 0xed, 0xee, 0xef,
	0xf0, 0xf1, 0xf2, 0xf3, 0xf4, 0xf5, 0xf6, 0xf7,
	0xf8, 0xf9, 0xfa, 0xfb, 0xfc, 0xfd, 0xfe, 0xff,
	)

MACOS_ROMAN = (
	0x00, None, 0x02, None, None, None, None, None,
	None, None, 0x09, 0x0a, None, None, 0x0d, None,
	None, None, None, None, None, None, None, None,
	0x20, 0x21, 0x22, 0x23, 0x24, 0x25, 0x26, 0x27,
	0x28, 0x29, 0x2a, 0x2b, 0x2c, 0x2d, 0x2e, 0x2f,
	0x30, 0x31, 0x32, 0x33, 0x34, 0x35, 0x36, 0x37,
	0x38, 0x39, 0x3a, 0x3b, 0x3c, 0x3d, 0x3e, 0x3f,
	0x40, 0x41, 0x42, 0x43, 0x44, 0x45, 0x46, 0x47,
	0x48, 0x49, 0x4a, 0x4b, 0x4c, 0x4d, 0x4e, 0x4f,
	0x50, 0x51, 0x52, 0x53, 0x54, 0x55, 0x56, 0x57,
	0x58, 0x59, 0x5a, 0x5b, 0x5c, 0x5d, 0x5e, 0x5f,
	0x60, 0x61, 0x62, 0x63, 0x64, 0x65, 0x66, 0x67,
	0x68, 0x69, 0x6a, 0x6b, 0x6c, 0x6d, 0x6e, 0x6f,
	0x70, 0x71, 0x72, 0x73, 0x74, 0x75, 0x76, 0x77,
	0x78, 0x79, 0x7a, 0x7b, 0x7c, 0x7d, 0x7e, None,
	0xc4, 0xc5, 0xc7, 0xc9, 0xd1, 0xd6, 0xdc, 0xe1,
	0xe0, 0xe2, 0xe4, 0xe3, 0xe5, 0xe7, 0xe9, 0xe8,
	0xea, 0xeb, 0xed, 0xec, 0xee, 0xef, 0xf1, 0xf3,
	0xf2, 0xf4, 0xf6, 0xf5, 0xfa, 0xf9, 0xfb, 0xfc,
	0x2020, 0xb0, 0xa2, 0xa3, 0xa7, 0x2022, 0xb6, 0xdf,
	0xae, 0xa9, 0x2122, 0xb4, 0xa8, 0x2260, 0xc6, 0xd8,
	0x221e, 0xb1, 0x2264, 0x2265, 0xa5, 0xb5, 0x2202, 0x2211,
	0x220f, 0x03c0, 0x222b, 0xaa, 0xba, 0x03a9, 0xe6, 0xf8,
	0xbf, 0xa1, 0xac, 0x221a, 0x0192, 0x2248, 0x2206, 0xab,
	0xbb, 0x2026, 0xa0, 0xc0, 0xc3, 0xd5, 0x0152, 0x0153,
	0x2013, 0x2014, 0x201c, 0x201d, 0x2018, 0x2019, 0xf7, 0x25ca,
	0xff, 0x0178, 0x2044, 0x20ac, 0x2039, 0x203a, 0xfb01, 0xfb02,
	0x2021, 0xb7, 0x201a, 0x201e, 0x2030, 0xc2, 0xca, 0xc1,
	0xcb, 0xc8, 0xcd, 0xce, 0xcf, 0xcc, 0xd3, 0xd4,
	0xf8ff, 0xd2, 0xda, 0xdb, 0xd9, 0x0131, 0x02c6, 0x02dc,
	0xaf, 0x02d8, 0x02d9, 0x02da, 0xb8, 0x02dd, 0x02db, 0x02c7,
	)

UNICODE_RANGES = set(range(123))

CODEPAGES = {
	0: 1252,
	1: 1250,
	2: 1251,
	3: 1253,
	4: 1254,
	5: 1255,
	6: 1256,
	7: 1257,
	8: 1258,
	16: 874,
	17: 932,
	18: 936,
	19: 949,
	20: 950,
	21: 1361,
	48: 869,
	49: 866,
	50: 865,
	51: 864,
	52: 863,
	53: 862,
	54: 861,
	55: 860,
	56: 857,
	57: 855,
	58: 852,
	59: 775,
	60: 737,
	61: 708,
	62: 850,
	63: 437,
	}

# FONTLAB CONSTANTS

FL_TIME_CONSTANT = 2212075696

FL_WIN_CHARSET = {
	0: 1,
	1: 2,
	2: 3,
	77: 4,
	128: 5,
	129: 6,
	130: 7,
	134: 8,
	136: 9,
	161: 10,
	162: 11,
	163: 12,
	177: 13,
	178: 14,
	186: 15,
	200: 16,
	204: 17,
	222: 18,
	238: 19,
	255: 20,
	}

REVERSED_FL_WIN_CHARSET = {value: key for key, value in items(FL_WIN_CHARSET)}

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

REVERSED_WIDTHS = {value: key for key, value in items(WIDTHS)}

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

REVERSED_WEIGHTS = {value: key for key, value in items(WEIGHTS)}

# UFO CONFIGURABLE ATTRIBUTE SETS

CONFIGURABLE_ATTRIBUTES = {
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
	'openTypeNameDesignerURL', 'openTypeNameLicense',
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
	'openTypeOS2Panose', 'openTypeOS2Selection',
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

STRING_ATTRIBUTES = {
	'copyright',
	'familyName',
	'note',
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

INT_ATTRIBUTES = {
	'ascender',
	'capHeight',
	'descender',
	'openTypeHeadLowestRecPPEM',
	'openTypeHheaAscender',
	'openTypeHheaCaretOffset',
	'openTypeHheaCaretSlopeRise',
	'openTypeHheaCaretSlopeRun',
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
	'openTypeOS2WeightClass',
	'openTypeOS2WidthClass',
	'openTypeOS2WinAscent',
	'openTypeOS2WinDescent',
	'postscriptUniqueID',
	'unitsPerEm',
	'versionMajor',
	'versionMinor',
	'xHeight',
	}

FLOAT_ATTRIBUTES = {
	'italicAngle',
	'postscriptSlantAngle',
	}

INT_FLOAT_ATTRIBUTES = {
	'postscriptBlueFuzz',
	'postscriptBlueShift',
	'postscriptDefaultWidthX',
	'postscriptNominalWidthX',
	'postscriptUnderlinePosition',
	'postscriptUnderlineThickness',
	}

BOOL_ATTRIBUTES = {
	'postscriptIsFixedPitch',
	'postscriptForceBold',
	}

INT_LIST_ATTRIBUTES = {
	'openTypeHeadFlags',
	'openTypeOS2CodePageRanges',
	'openTypeOS2FamilyClass',
	'openTypeOS2Panose',
	'openTypeOS2Selection',
	'openTypeOS2Type',
	'openTypeOS2UnicodeRanges',
	'postscriptWindowsCharacterSet',
	}

INT_FLOAT_LIST_ATTRIBUTES = {
	'postscriptBlueValues',
	'postscriptFamilyBlues',
	'postscriptFamilyOtherBlues',
	'postscriptOtherBlues',
	'postscriptStemSnapH',
	'postscriptStemSnapV',
	}

FL_STYLES = {
	1: 'Italic',
	32: 'Bold',
	33: 'Bold Italic',
	64: 'Regular',
	}

REVERSED_FL_STYLES = {value: key for key, value in items(FL_STYLES)}

WIDTHS = {
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

PS_WINDOWS_CHARSET = {
	1: 'ANSI',
	2: 'Default',
	3: 'Symbol',
	4: 'Macintosh',
	5: 'Shift JIS',
	6: 'Hangul',
	7: 'Hangul (Johab)',
	8: 'GB2312',
	9: 'Chinese BIG5',
	10: 'Greek',
	11: 'Turkish',
	12: 'Vietnamese',
	13: 'Hebrew',
	14: 'Arabic',
	15: 'Baltic',
	16: 'Bitstream',
	17: 'Cyrillic',
	18: 'Thai',
	19: 'Eastern European',
	20: 'OEM',
	}

# LANGUAGES

OT_LANGUAGES = {
	'ABA': 'Abaza',
	'ABK': 'Abkhazian',
	'ACH': 'Acholi',
	'ACR': 'Achi',
	'ADY': 'Adyghe',
	'AFK': 'Afrikaans',
	'AFR': 'Afar',
	'AGW': 'Agaw',
	'AIO': 'Aiton',
	'AKA': 'Akan',
	'ALS': 'Alsatian',
	'ALT': 'Altai',
	'AMH': 'Amharic',
	'ANG': 'Anglo-Saxon',
	'APPH': 'Phonetic transcription—Americanist conventions',
	'ARA': 'Arabic',
	'ARG': 'Aragonese',
	'ARI': 'Aari',
	'ARK': 'Rakhine',
	'ASM': 'Assamese',
	'AST': 'Asturian',
	'ATH': 'Athapaskan',
	'AVR': 'Avar',
	'AWA': 'Awadhi',
	'AYM': 'Aymara',
	'AZB': 'Torki',
	'AZE': 'Azerbaijani',
	'BAD': 'Badaga',
	'BAD0': 'Banda',
	'BAG': 'Baghelkhandi',
	'BAL': 'Balkar',
	'BAN': 'Balinese',
	'BAR': 'Bavarian',
	'BAU': 'Baulé',
	'BBC': 'Batak Toba',
	'BBR': 'Berber',
	'BCH': 'Bench',
	'BCR': 'Bible Cree',
	'BDY': 'Bandjalang',
	'BEL': 'Belarussian',
	'BEM': 'Bemba',
	'BEN': 'Bengali',
	'BGC': 'Haryanvi',
	'BGQ': 'Bagri',
	'BGR': 'Bulgarian',
	'BHI': 'Bhili',
	'BHO': 'Bhojpuri',
	'BIK': 'Bikol',
	'BIL': 'Bilen',
	'BIS': 'Bislama',
	'BJJ': 'Kanauji',
	'BKF': 'Blackfoot',
	'BLI': 'Baluchi',
	'BLK': "Pa'o Karen",
	'BLN': 'Balante',
	'BLT': 'Balti',
	'BMB': 'Bambara (Bamanankan)',
	'BML': 'Bamileke',
	'BOS': 'Bosnian',
	'BPY': 'Bishnupriya Manipuri',
	'BRE': 'Breton',
	'BRH': 'Brahui',
	'BRI': 'Braj Bhasha',
	'BRM': 'Burmese',
	'BRX': 'Bodo',
	'BSH': 'Bashkir',
	'BSK': 'Burushaski',
	'BTI': 'Beti',
	'BTS': 'Batak Simalungun',
	'BUG': 'Bugis',
	'BYV': 'Medumba',
	'CAK': 'Kaqchikel',
	'CAT': 'Catalan',
	'CBK': 'Zamboanga Chavacano',
	'CCHN': 'Chinantec',
	'CEB': 'Cebuano',
	'CHE': 'Chechen',
	'CHG': 'Chaha Gurage',
	'CHH': 'Chattisgarhi',
	'CHI': 'Chichewa (Chewa, Nyanja)',
	'CHK': 'Chukchi',
	'CHK0': 'Chuukese',
	'CHO': 'Choctaw',
	'CHP': 'Chipewyan',
	'CHR': 'Cherokee',
	'CHA': 'Chamorro',
	'CHU': 'Chuvash',
	'CHY': 'Cheyenne',
	'CGG': 'Chiga',
	'CJA': 'Western Cham',
	'CJM': 'Eastern Cham',
	'CMR': 'Comorian',
	'COP': 'Coptic',
	'COR': 'Cornish',
	'COS': 'Corsican',
	'CPP': 'Creoles',
	'CRE': 'Cree',
	'CRR': 'Carrier',
	'CRT': 'Crimean Tatar',
	'CSB': 'Kashubian',
	'CSL': 'Church Slavonic',
	'CSY': 'Czech',
	'CTG': 'Chittagonian',
	'CUK': 'San Blas Kuna',
	'DAN': 'Danish',
	'DAR': 'Dargwa',
	'DAX': 'Dayi',
	'DCR': 'Woods Cree',
	'DEU': 'German',
	'DGO': 'Dogri',
	'DGR': 'Dogri',
	'DHG': 'Dhangu',
	'DHV': 'Divehi (Dhivehi, Maldivian)', # (deprecated)
	'DIQ': 'Dimli',
	'DIV': 'Divehi (Dhivehi, Maldivian)',
	'DJR': 'Zarma',
	'DJR0': 'Djambarrpuyngu',
	'DNG': 'Dangme',
	'DNJ': 'Dan',
	'DNK': 'Dinka',
	'DRI': 'Dari',
	'DUJ': 'Dhuwal',
	'DUN': 'Dungan',
	'DZN': 'Dzongkha',
	'EBI': 'Ebira',
	'ECR': 'Eastern Cree',
	'EDO': 'Edo',
	'EFI': 'Efik',
	'ELL': 'Greek',
	'EMK': 'Eastern Maninkakan',
	'ENG': 'English',
	'ERZ': 'Erzya',
	'ESP': 'Spanish',
	'ESU': 'Central Yupik',
	'ETI': 'Estonian',
	'EUQ': 'Basque',
	'EVK': 'Evenki',
	'EVN': 'Even',
	'EWE': 'Ewe',
	'FAN': 'French Antillean',
	'FAN0': 'Fang',
	'FAR': 'Persian',
	'FAT': 'Fanti',
	'FIN': 'Finnish',
	'FJI': 'Fijian',
	'FLE': 'Dutch (Flemish)',
	'FMP': "Fe'fe'",
	'FNE': 'Forest Nenets',
	'FON': 'Fon',
	'FOS': 'Faroese',
	'FRA': 'French',
	'FRC': 'Cajun French',
	'FRI': 'Frisian',
	'FRL': 'Friulian',
	'FRP': 'Arpitan',
	'FTA': 'Futa',
	'FUL': 'Fulah',
	'FUV': 'Nigerian Fulfulde',
	'GAD': 'Ga',
	'GAE': 'Scottish Gaelic (Gaelic)',
	'GAG': 'Gagauz',
	'GAL': 'Galician',
	'GAR': 'Garshuni',
	'GAW': 'Garhwali',
	'GEZ': "Ge'ez",
	'GIH': 'Githabul',
	'GIL': 'Gilyak',
	'GIL0': 'Kiribati (Gilbertese)',
	'GKP': 'Kpelle (Guinea)',
	'GLK': 'Gilaki',
	'GMZ': 'Gumuz',
	'GNN': 'Gumatj',
	'GOG': 'Gogo',
	'GON': 'Gondi',
	'GRN': 'Greenlandic',
	'GRO': 'Garo',
	'GUA': 'Guarani',
	'GUC': 'Wayuu',
	'GUF': 'Gupapuyngu',
	'GUJ': 'Gujarati',
	'GUZ': 'Gusii',
	'HAI': 'Haitian (Haitian Creole)',
	'HAL': 'Halam',
	'HAR': 'Harauti',
	'HAU': 'Hausa',
	'HAW': 'Hawaiian',
	'HAY': 'Haya',
	'HAZ': 'Hazaragi',
	'HBN': 'Hammer-Banna',
	'HER': 'Herero',
	'HIL': 'Hiligaynon',
	'HIN': 'Hindi',
	'HMA': 'High Mari',
	'HMN': 'Hmong',
	'HMO': 'Hiri Motu',
	'HND': 'Hindko',
	'HO': 'Ho',
	'HRI': 'Harari',
	'HRV': 'Croatian',
	'HUN': 'Hungarian',
	'HYE': 'Armenian',
	'HYE0': 'Armenian East',
	'IBA': 'Iban',
	'IBB': 'Ibibio',
	'IBO': 'Igbo',
	'IJO': 'Ijo languages',
	'IDO': 'Ido',
	'ILE': 'Interlingue',
	'ILO': 'Ilokano',
	'INA': 'Interlingua',
	'IND': 'Indonesian',
	'ING': 'Ingush',
	'INU': 'Inuktitut',
	'IPK': 'Inupiat',
	'IPPH': 'Phonetic transcription—IPA conventions',
	'IRI': 'Irish',
	'IRT': 'Irish Traditional',
	'ISL': 'Icelandic',
	'ISM': 'Inari Sami',
	'ITA': 'Italian',
	'IWR': 'Hebrew',
	'JAM': 'Jamaican Creole',
	'JAN': 'Japanese',
	'JAV': 'Javanese',
	'JBO': 'Lojban',
	'JCT': 'Krymchak',
	'JII': 'Yiddish',
	'JUD': 'Ladino',
	'JUL': 'Jula',
	'KAB': 'Kabardian',
	'KAB0': 'Kabyle',
	'KAC': 'Kachchi',
	'KAL': 'Kalenjin',
	'KAN': 'Kannada',
	'KAR': 'Karachay',
	'KAT': 'Georgian',
	'KAZ': 'Kazakh',
	'KDE': 'Makonde',
	'KEA': 'Kabuverdianu (Crioulo)',
	'KEB': 'Kebena',
	'KEK': 'Kekchi',
	'KGE': 'Khutsuri Georgian',
	'KHA': 'Khakass',
	'KHK': 'Khanty-Kazim',
	'KHM': 'Khmer',
	'KHS': 'Khanty-Shurishkar',
	'KHT': 'Khamti Shan',
	'KHV': 'Khanty-Vakhi',
	'KHW': 'Khowar',
	'KIK': 'Kikuyu (Gikuyu)',
	'KIR': 'Kirghiz (Kyrgyz)',
	'KIS': 'Kisii',
	'KIU': 'Kirmanjki',
	'KJD': 'Southern Kiwai',
	'KJP': 'Eastern Pwo Karen',
	'KKN': 'Kokni',
	'KLM': 'Kalmyk',
	'KMB': 'Kamba',
	'KMN': 'Kumaoni',
	'KMO': 'Komo',
	'KMS': 'Komso',
	'KMZ': 'Khorasani Turkic',
	'KNR': 'Kanuri',
	'KOD': 'Kodagu',
	'KOH': 'Korean Old Hangul',
	'KOK': 'Konkani',
	'KON': 'Kikongo',
	'KOM': 'Komi',
	'KON0': 'Kongo',
	'KOP': 'Komi-Permyak',
	'KOR': 'Korean',
	'KOS': 'Kosraean',
	'KOZ': 'Komi-Zyrian',
	'KPL': 'Kpelle',
	'KRI': 'Krio',
	'KRK': 'Karakalpak',
	'KRL': 'Karelian',
	'KRM': 'Karaim',
	'KRN': 'Karen',
	'KRT': 'Koorete',
	'KSH': 'Kashmiri',
	'KSH0': 'Ripuarian',
	'KSI': 'Khasi',
	'KSM': 'Kildin Sami',
	'KSW': 'S’gaw Karen',
	'KUA': 'Kuanyama',
	'KUI': 'Kui',
	'KUL': 'Kulvi',
	'KUM': 'Kumyk',
	'KUR': 'Kurdish',
	'KUU': 'Kurukh',
	'KUY': 'Kuy',
	'KYK': 'Koryak',
	'KYU': 'Western Kayah',
	'LAD': 'Ladin',
	'LAH': 'Lahuli',
	'LAK': 'Lak',
	'LAM': 'Lambani',
	'LAO': 'Lao',
	'LAT': 'Latin',
	'LAZ': 'Laz',
	'LCR': 'L-Cree',
	'LDK': 'Ladakhi',
	'LEZ': 'Lezgi',
	'LIJ': 'Ligurian',
	'LIM': 'Limburgish',
	'LIN': 'Lingala',
	'LIS': 'Lisu',
	'LJP': 'Lampung',
	'LKI': 'Laki',
	'LMA': 'Low Mari',
	'LMB': 'Limbu',
	'LMO': 'Lombard',
	'LMW': 'Lomwe',
	'LOM': 'Loma',
	'LRC': 'Luri',
	'LSB': 'Lower Sorbian',
	'LSM': 'Lule Sami',
	'LTH': 'Lithuanian',
	'LTZ': 'Luxembourgish',
	'LUA': 'Luba-Lulua',
	'LUB': 'Luba-Katanga',
	'LUG': 'Ganda',
	'LUH': 'Luyia',
	'LUO': 'Luo',
	'LVI': 'Latvian',
	'MAD': 'Madura',
	'MAG': 'Magahi',
	'MAH': 'Marshallese',
	'MAJ': 'Majang',
	'MAK': 'Makhuwa',
	'MAL': 'Malayalam',
	'MAM': 'Mam',
	'MAN': 'Mansi',
	'MAP': 'Mapudungun',
	'MAR': 'Marathi',
	'MAW': 'Marwari',
	'MBN': 'Mbundu',
	'MBO': 'Mbo',
	'MCH': 'Manchu',
	'MCR': 'Moose Cree',
	'MDE': 'Mende',
	'MDR': 'Mandar',
	'MEN': "Me'en",
	'MER': 'Meru',
	'MFE': 'Morisyen',
	'MIN': 'Minangkabau',
	'MIZ': 'Mizo',
	'MKD': 'Macedonian',
	'MKR': 'Makasar',
	'MKW': 'Kituba',
	'MLE': 'Male',
	'MLG': 'Malagasy',
	'MLN': 'Malinke',
	'MLR': 'Malayalam Reformed',
	'MLY': 'Malay',
	'MND': 'Mandinka',
	'MNG': 'Mongolian',
	'MNI': 'Manipuri',
	'MNK': 'Maninka',
	'MNX': 'Manx',
	'MOH': 'Mohawk',
	'MOK': 'Moksha',
	'MOL': 'Moldavian',
	'MON': 'Mon',
	'MOR': 'Moroccan',
	'MOS': 'Mossi',
	'MRI': 'Maori',
	'MTH': 'Maithili',
	'MTS': 'Maltese',
	'MUN': 'Mundari',
	'MUS': 'Muscogee',
	'MWL': 'Mirandese',
	'MWW': 'Hmong Daw',
	'MYN': 'Mayan',
	'MZN': 'Mazanderani',
	'NAG': 'Naga-Assamese',
	'NAH': 'Nahuatl',
	'NAN': 'Nanai',
	'NAP': 'Neapolitan',
	'NAS': 'Naskapi',
	'NAU': 'Nauruan',
	'NAV': 'Navajo',
	'NCR': 'N-Cree',
	'NDB': 'Ndebele',
	'NDC': 'Ndau',
	'NDG': 'Ndonga',
	'NDS': 'Low Saxon',
	'NEP': 'Nepali',
	'NEW': 'Newari',
	'NGA': 'Ngbaka',
	'NGR': 'Nagari',
	'NHC': 'Norway House Cree',
	'NIS': 'Nisi',
	'NIU': 'Niuean',
	'NKL': 'Nyankole',
	'NKO': "N'Ko",
	'NLD': 'Dutch',
	'NOE': 'Nimadi',
	'NOG': 'Nogai',
	'NOR': 'Norwegian',
	'NOV': 'Novial',
	'NSM': 'Northern Sami',
	'NSO': 'Sotho, Northern',
	'NTA': 'Northern Tai',
	'NTO': 'Esperanto',
	'NYM': 'Nyamwezi',
	'NYN': 'Norwegian Nynorsk (Nynorsk, Norwegian)',
	'NZA': 'Mbembe Tigon',
	'OCI': 'Occitan',
	'OCR': 'Oji-Cree',
	'OJB': 'Ojibway',
	'ORI': 'Odia (formerly Oriya)',
	'ORO': 'Oromo',
	'OSS': 'Ossetian',
	'PAA': 'Palestinian Aramaic',
	'PAG': 'Pangasinan',
	'PAL': 'Pali',
	'PAM': 'Pampangan',
	'PAN': 'Punjabi',
	'PAP': 'Palpa',
	'PAP0': 'Papiamentu',
	'PAS': 'Pashto',
	'PAU': 'Palauan',
	'PCC': 'Bouyei',
	'PCD': 'Picard',
	'PDC': 'Pennsylvania German',
	'PGR': 'Polytonic Greek',
	'PHK': 'Phake',
	'PIH': 'Norfolk',
	'PIL': 'Filipino',
	'PLG': 'Palaung',
	'PLK': 'Polish',
	'PMS': 'Piemontese',
	'PNB': 'Western Panjabi',
	'POH': 'Pocomchi',
	'PON': 'Pohnpeian',
	'PRO': 'Provencal',
	'PTG': 'Portuguese',
	'PWO': 'Western Pwo Karen',
	'QIN': 'Chin',
	'QUC': 'K’iche’',
	'QUH': 'Quechua (Bolivia)',
	'QUZ': 'Quechua',
	'QVI': 'Quechua (Ecuador)',
	'QWH': 'Quechua (Peru)',
	'RAJ': 'Rajasthani',
	'RAR': 'Rarotongan',
	'RBU': 'Russian Buriat',
	'RCR': 'R-Cree',
	'REJ': 'Rejang',
	'RIA': 'Riang',
	'RIF': 'Tarifit',
	'RIT': 'Ritarungo',
	'RKW': 'Arakwal',
	'RMS': 'Romansh',
	'RMY': 'Vlax Romani',
	'ROM': 'Romanian',
	'ROY': 'Romany',
	'RSY': 'Rusyn',
	'RTM': 'Rotuman',
	'RUA': 'Kinyarwanda',
	'RUN': 'Rundi',
	'RUP': 'Aromanian',
	'RUS': 'Russian',
	'SAD': 'Sadri',
	'SAN': 'Sanskrit',
	'SAS': 'Sasak',
	'SAT': 'Santali',
	'SAY': 'Sayisi',
	'SCN': 'Sicilian',
	'SCO': 'Scots',
	'SEK': 'Sekota',
	'SEL': 'Selkup',
	'SGA': 'Old Irish',
	'SGO': 'Sango',
	'SGS': 'Samogitian',
	'SHI': 'Tachelhit',
	'SHN': 'Shan',
	'SIB': 'Sibe',
	'SID': 'Sidamo',
	'SIG': 'Silte Gurage',
	'SKS': 'Skolt Sami',
	'SKY': 'Slovak',
	'SCS': 'North Slavey',
	'SLA': 'Slavey',
	'SLV': 'Slovenian',
	'SML': 'Somali',
	'SMO': 'Samoan',
	'SNA': 'Sena',
	'SNA0': 'Shona',
	'SND': 'Sindhi',
	'SNH': 'Sinhala (Sinhalese)',
	'SNK': 'Soninke',
	'SOG': 'Sodo Gurage',
	'SOP': 'Songe',
	'SOT': 'Sotho, Southern',
	'SQI': 'Albanian',
	'SRB': 'Serbian',
	'SRD': 'Sardinian',
	'SRK': 'Saraiki',
	'SRR': 'Serer',
	'SSL': 'South Slavey',
	'SSM': 'Southern Sami',
	'STQ': 'Saterland Frisian',
	'SUK': 'Sukuma',
	'SUN': 'Sundanese',
	'SUR': 'Suri',
	'SVA': 'Svan',
	'SVE': 'Swedish',
	'SWA': 'Swadaya Aramaic',
	'SWK': 'Swahili',
	'SWZ': 'Swati',
	'SXT': 'Sutu',
	'SXU': 'Upper Saxon',
	'SYL': 'Sylheti',
	'SYR': 'Syriac',
	'SYRE': "Syriac, Estrangela script-variant (equivalent to ISO 15924 'Syre')",
	'SYRJ': "Syriac, Western script-variant (equivalent to ISO 15924 'Syrj')",
	'SYRN': "Syriac, Eastern script-variant (equivalent to ISO 15924 'Syrn')",
	'SZL': 'Silesian',
	'TAB': 'Tabasaran',
	'TAJ': 'Tajiki',
	'TAM': 'Tamil',
	'TAT': 'Tatar',
	'TCR': 'TH-Cree',
	'TDD': 'Dehong Dai',
	'TEL': 'Telugu',
	'TET': 'Tetum',
	'TGL': 'Tagalog',
	'TGN': 'Tongan',
	'TGR': 'Tigre',
	'TGY': 'Tigrinya',
	'THA': 'Thai',
	'THT': 'Tahitian',
	'TIB': 'Tibetan',
	'TIV': 'Tiv',
	'TKM': 'Turkmen',
	'TMH': 'Tamashek',
	'TMN': 'Temne',
	'TNA': 'Tswana',
	'TNE': 'Tundra Nenets',
	'TNG': 'Tonga',
	'TOD': 'Todo',
	'TOD0': 'Toma',
	'TPI': 'Tok Pisin',
	'TRK': 'Turkish',
	'TSG': 'Tsonga',
	'TUA': 'Turoyo Aramaic',
	'TUM': 'Tulu',
	'TUL': 'Tumbuka',
	'TUV': 'Tuvin',
	'TVL': 'Tuvalu',
	'TWI': 'Twi',
	'TYZ': 'Tày',
	'TZM': 'Tamazight',
	'TZO': 'Tzotzil',
	'UDM': 'Udmurt',
	'UKR': 'Ukrainian',
	'UMB': 'Umbundu',
	'URD': 'Urdu',
	'USB': 'Upper Sorbian',
	'UYG': 'Uyghur',
	'UZB': 'Uzbek',
	'VEC': 'Venetian',
	'VEN': 'Venda',
	'VIT': 'Vietnamese',
	'VOL': 'Volapük',
	'VRO': 'Võro',
	'WA': 'Wa',
	'WAG': 'Wagdi',
	'WAR': 'Waray-Waray',
	'WCR': 'West-Cree',
	'WEL': 'Welsh',
	'WLN': 'Walloon',
	'WLF': 'Wolof',
	'WTM': 'Mewati',
	'XBD': 'Lü',
	'XHS': 'Xhosa',
	'XJB': 'Minjangbal',
	'XOG': 'Soga',
	'XPE': 'Kpelle (Liberia)',
	'YAK': 'Sakha',
	'YAO': 'Yao',
	'YAP': 'Yapese',
	'YBA': 'Yoruba',
	'YCR': 'Y-Cree',
	'YIC': 'Yi Classic',
	'YIM': 'Yi Modern',
	'ZEA': 'Zealandic',
	'ZGH': 'Standard Morrocan Tamazigh',
	'ZHA': 'Zhuang',
	'ZHH': 'Chinese, Hong Kong SAR',
	'ZHP': 'Chinese Phonetic',
	'ZHS': 'Chinese Simplified',
	'ZHT': 'Chinese Traditional',
	'ZND': 'Zande',
	'ZUL': 'Zulu',
	'ZZA': 'Zazaki',
	}

# SCRIPTS

OT_SCRIPTS = {
	'adlm': 'Adlam',
	'ahom': 'Ahom',
	'hluw': 'Anatolian Hieroglyphs',
	'arab': 'Arabic',
	'armn': 'Armenian',
	'avst': 'Avestan',
	'bali': 'Balinese',
	'bamu': 'Bamum',
	'bass': 'Bassa Vah',
	'batk': 'Batak',
	'beng': 'Bengali',
	'bng2': 'Bengali v.2',
	'bhks': 'Bhaiksuki',
	'bopo': 'Bopomofo',
	'brah': 'Brahmi',
	'brai': 'Braille',
	'bugi': 'Buginese',
	'buhd': 'Buhid',
	'byzm': 'Byzantine Music',
	'cans': 'Canadian Syllabics',
	'cari': 'Carian',
	'aghb': 'Caucasian Albanian',
	'cakm': 'Chakma',
	'cham': 'Cham',
	'cher': 'Cherokee',
	'hani': 'CJK Ideographic',
	'copt': 'Coptic',
	'cprt': 'Cypriot Syllabary',
	'cyrl': 'Cyrillic',
	'DFLT': 'Default',
	'dsrt': 'Deseret',
	'deva': 'Devanagari',
	'dev2': 'Devanagari v.2',
	'dupl': 'Duployan',
	'egyp': 'Egyptian Hieroglyphs',
	'elba': 'Elbasan',
	'ethi': 'Ethiopic',
	'geor': 'Georgian',
	'glag': 'Glagolitic',
	'goth': 'Gothic',
	'gran': 'Grantha',
	'grek': 'Greek',
	'gujr': 'Gujarati',
	'gjr2': 'Gujarati v.2',
	'guru': 'Gurmukhi',
	'gur2': 'Gurmukhi v.2',
	'hang': 'Hangul',
	'jamo': 'Hangul Jamo',
	'hano': 'Hanunoo',
	'hatr': 'Hatran',
	'hebr': 'Hebrew',
	'armi': 'Imperial Aramaic',
	'phli': 'Inscriptional Pahlavi',
	'prti': 'Inscriptional Parthian',
	'java': 'Javanese',
	'kthi': 'Kaithi',
	'knda': 'Kannada',
	'knd2': 'Kannada v.2',
	'kana': 'Katakana',
	'kali': 'Kayah Li',
	'khar': 'Kharosthi',
	'khmr': 'Khmer',
	'khoj': 'Khojki',
	'sind': 'Khudawadi',
	'lao': 'Lao',
	'latn': 'Latin',
	'lepc': 'Lepcha',
	'limb': 'Limbu',
	'lina': 'Linear A',
	'linb': 'Linear B',
	'lisu': 'Lisu (Fraser)',
	'lyci': 'Lycian',
	'lydi': 'Lydian',
	'mahj': 'Mahajani',
	'mlym': 'Malayalam',
	'mlm2': 'Malayalam v.2',
	'mand': 'Mandaic, Mandaean',
	'mani': 'Manichaean',
	'marc': 'Marchen',
	'math': 'Mathematical Alphanumeric Symbols',
	'mtei': 'Meitei Mayek (Meithei, Meetei)',
	'mend': 'Mende Kikakui',
	'merc': 'Meroitic Cursive',
	'mero': 'Meroitic Hieroglyphs',
	'plrd': 'Miao',
	'modi': 'Modi',
	'mong': 'Mongolian',
	'mroo': 'Mro',
	'mult': 'Multani',
	'musc': 'Musical Symbols',
	'mymr': 'Myanmar',
	'mym2': 'Myanmar v.2',
	'nbat': 'Nabataean',
	'newa': 'Newa',
	'talu': 'New Tai Lue',
	'nko': "N'Ko",
	'orya': 'Odia (formerly Oriya)',
	'ory2': 'Odia v.2 (formerly Oriya v.2)',
	'ogam': 'Ogham',
	'olck': 'Ol Chiki',
	'ital': 'Old Italic',
	'hung': 'Old Hungarian',
	'narb': 'Old North Arabian',
	'perm': 'Old Permic',
	'xpeo': 'Old Persian Cuneiform',
	'sarb': 'Old South Arabian',
	'orkh': 'Old Turkic, Orkhon Runic',
	'osge': 'Osage',
	'osma': 'Osmanya',
	'hmng': 'Pahawh Hmong',
	'palm': 'Palmyrene',
	'pauc': 'Pau Cin Hau',
	'phag': 'Phags-pa',
	'phnx': 'Phoenician',
	'phlp': 'Psalter Pahlavi',
	'rjng': 'Rejang',
	'runr': 'Runic',
	'samr': 'Samaritan',
	'saur': 'Saurashtra',
	'shrd': 'Sharada',
	'shaw': 'Shavian',
	'sidd': 'Siddham',
	'sgnw': 'Sign Writing',
	'sinh': 'Sinhala',
	'sora': 'Sora Sompeng',
	'xsux': 'Sumero-Akkadian Cuneiform',
	'sund': 'Sundanese',
	'sylo': 'Syloti Nagri',
	'syrc': 'Syriac',
	'tglg': 'Tagalog',
	'tagb': 'Tagbanwa',
	'tale': 'Tai Le',
	'lana': 'Tai Tham (Lanna)',
	'tavt': 'Tai Viet',
	'takr': 'Takri',
	'taml': 'Tamil',
	'tml2': 'Tamil v.2',
	'tang': 'Tangut',
	'telu': 'Telugu',
	'tel2': 'Telugu v.2',
	'thaa': 'Thaana',
	'thai': 'Thai',
	'tibt': 'Tibetan',
	'tfng': 'Tifinagh',
	'tirh': 'Tirhuta',
	'ugar': 'Ugaritic Cuneiform',
	'vai': 'Vai',
	'wara': 'Warang Citi',
	'yi': 'Yi'
	}

# FEATURES

OT_FEATURES = {
	'aalt': 'Access All Alternates',
	'abvf': 'Above-base Forms',
	'abvm': 'Above-base Mark Positioning',
	'abvs': 'Above-base Substitutions',
	'afrc': 'Alternative Fractions',
	'akhn': 'Akhands',
	'blwf': 'Below-base Forms',
	'blwm': 'Below-base Mark Positioning',
	'blws': 'Below-base Substitutions',
	'calt': 'Contextual Alternates',
	'case': 'Case-Sensitive Forms',
	'ccmp': 'Glyph Composition / Decomposition',
	'cfar': 'Conjunct Form After Ro',
	'cjct': 'Conjunct Forms',
	'clig': 'Contextual Ligatures',
	'cpct': 'Centered CJK Punctuation',
	'cpsp': 'Capital Spacing',
	'cswh': 'Contextual Swash',
	'curs': 'Cursive Positioning',
	'c2pc': 'Petite Capitals From Capitals',
	'c2sc': 'Small Capitals From Capitals',
	'dist': 'Distances',
	'dlig': 'Discretionary Ligatures',
	'dnom': 'Denominators',
	'dtls': 'Dotless Forms',
	'expt': 'Expert Forms',
	'falt': 'Final Glyph on Line Alternates',
	'fin2': 'Terminal Forms #2',
	'fin3': 'Terminal Forms #3',
	'fina': 'Terminal Forms',
	'flac': 'Flattened accent forms',
	'frac': 'Fractions',
	'fwid': 'Full Widths',
	'half': 'Half Forms',
	'haln': 'Halant Forms',
	'halt': 'Alternate Half Widths',
	'hist': 'Historical Forms',
	'hkna': 'Horizontal Kana Alternates',
	'hlig': 'Historical Ligatures',
	'hngl': 'Hangul',
	'hojo': 'Hojo Kanji Forms (JIS X 0212-1990 Kanji Forms)',
	'hwid': 'Half Widths',
	'init': 'Initial Forms',
	'isol': 'Isolated Forms',
	'ital': 'Italics',
	'jalt': 'Justification Alternates',
	'jp78': 'JIS78 Forms',
	'jp83': 'JIS83 Forms',
	'jp90': 'JIS90 Forms',
	'jp04': 'JIS2004 Forms',
	'kern': 'Kerning',
	'lfbd': 'Left Bounds',
	'liga': 'Standard Ligatures',
	'ljmo': 'Leading Jamo Forms',
	'lnum': 'Lining Figures',
	'locl': 'Localized Forms',
	'ltra': 'Left-to-right alternates',
	'ltrm': 'Left-to-right mirrored forms',
	'mark': 'Mark to Base Positioning',
	'med2': 'Medial Forms #2',
	'medi': 'Medial Forms',
	'mgrk': 'Mathematical Greek',
	'mkmk': 'Mark to Mark Positioning',
	'mset': 'Mark Positioning via Substitution',
	'nalt': 'Alternate Annotation Forms',
	'nlck': 'NLC Kanji Forms',
	'nukt': 'Nukta Forms',
	'numr': 'Numerators',
	'onum': 'Oldstyle Figures',
	'opbd': 'Optical Bounds',
	'ordn': 'Ordinals',
	'ornm': 'Ornaments',
	'palt': 'Proportional Alternate Widths',
	'pcap': 'Petite Capitals',
	'pkna': 'Proportional Kana',
	'pnum': 'Proportional Figures',
	'pref': 'Pre-Base Forms',
	'pres': 'Pre-base Substitutions',
	'pstf': 'Post-base Forms',
	'psts': 'Post-base Substitutions',
	'pwid': 'Proportional Widths',
	'qwid': 'Quarter Widths',
	'rand': 'Randomize',
	'rclt': 'Required Contextual Alternates',
	'rkrf': 'Rakar Forms',
	'rlig': 'Required Ligatures',
	'rphf': 'Reph Forms',
	'rtbd': 'Right Bounds',
	'rtla': 'Right-to-left alternates',
	'rtlm': 'Right-to-left mirrored forms',
	'ruby': 'Ruby Notation Forms',
	'rvrn': 'Required Variation Alternates',
	'salt': 'Stylistic Alternates',
	'sinf': 'Scientific Inferiors',
	'size': 'Optical size',
	'smcp': 'Small Capitals',
	'smpl': 'Simplified Forms',
	'ss01': 'Stylistic Set 1',
	'ss02': 'Stylistic Set 2',
	'ss03': 'Stylistic Set 3',
	'ss04': 'Stylistic Set 4',
	'ss05': 'Stylistic Set 5',
	'ss06': 'Stylistic Set 6',
	'ss07': 'Stylistic Set 7',
	'ss08': 'Stylistic Set 8',
	'ss09': 'Stylistic Set 9',
	'ss10': 'Stylistic Set 10',
	'ss11': 'Stylistic Set 11',
	'ss12': 'Stylistic Set 12',
	'ss13': 'Stylistic Set 13',
	'ss14': 'Stylistic Set 14',
	'ss15': 'Stylistic Set 15',
	'ss16': 'Stylistic Set 16',
	'ss17': 'Stylistic Set 17',
	'ss18': 'Stylistic Set 18',
	'ss19': 'Stylistic Set 19',
	'ss20': 'Stylistic Set 20',
	'ssty': 'Math script style alternates',
	'stch': 'Stretching Glyph Decomposition',
	'subs': 'Subscript',
	'sups': 'Superscript',
	'swsh': 'Swash',
	'titl': 'Titling',
	'tjmo': 'Trailing Jamo Forms',
	'tnam': 'Traditional Name Forms',
	'tnum': 'Tabular Figures',
	'trad': 'Traditional Forms',
	'twid': 'Third Widths',
	'unic': 'Unicase',
	'valt': 'Alternate Vertical Metrics',
	'vatu': 'Vattu Variants',
	'vert': 'Vertical Writing',
	'vhal': 'Alternate Vertical Half Metrics',
	'vjmo': 'Vowel Jamo Forms',
	'vkna': 'Vertical Kana Alternates',
	'vkrn': 'Vertical Kerning',
	'vpal': 'Proportional Alternate Vertical Metrics',
	'vrt2': 'Vertical Alternates and Rotation',
	'vrtr': 'Vertical Alternates for Rotation',
	'zero': 'Slashed Zero',
	'cv01': 'Character Variant 1',
	'cv02': 'Character Variant 2',
	'cv03': 'Character Variant 3',
	'cv04': 'Character Variant 4',
	'cv05': 'Character Variant 5',
	'cv06': 'Character Variant 6',
	'cv07': 'Character Variant 7',
	'cv08': 'Character Variant 8',
	'cv09': 'Character Variant 9',
	'cv10': 'Character Variant 10',
	'cv11': 'Character Variant 11',
	'cv12': 'Character Variant 12',
	'cv13': 'Character Variant 13',
	'cv14': 'Character Variant 14',
	'cv15': 'Character Variant 15',
	'cv16': 'Character Variant 16',
	'cv17': 'Character Variant 17',
	'cv18': 'Character Variant 18',
	'cv19': 'Character Variant 19',
	'cv20': 'Character Variant 20',
	'cv21': 'Character Variant 21',
	'cv22': 'Character Variant 22',
	'cv23': 'Character Variant 23',
	'cv24': 'Character Variant 24',
	'cv25': 'Character Variant 25',
	'cv26': 'Character Variant 26',
	'cv27': 'Character Variant 27',
	'cv28': 'Character Variant 28',
	'cv29': 'Character Variant 29',
	'cv30': 'Character Variant 30',
	'cv31': 'Character Variant 31',
	'cv32': 'Character Variant 32',
	'cv33': 'Character Variant 33',
	'cv34': 'Character Variant 34',
	'cv35': 'Character Variant 35',
	'cv36': 'Character Variant 36',
	'cv37': 'Character Variant 37',
	'cv38': 'Character Variant 38',
	'cv39': 'Character Variant 39',
	'cv40': 'Character Variant 40',
	'cv41': 'Character Variant 41',
	'cv42': 'Character Variant 42',
	'cv43': 'Character Variant 43',
	'cv44': 'Character Variant 44',
	'cv45': 'Character Variant 45',
	'cv46': 'Character Variant 46',
	'cv47': 'Character Variant 47',
	'cv48': 'Character Variant 48',
	'cv49': 'Character Variant 49',
	'cv50': 'Character Variant 50',
	'cv51': 'Character Variant 51',
	'cv52': 'Character Variant 52',
	'cv53': 'Character Variant 53',
	'cv54': 'Character Variant 54',
	'cv55': 'Character Variant 55',
	'cv56': 'Character Variant 56',
	'cv57': 'Character Variant 57',
	'cv58': 'Character Variant 58',
	'cv59': 'Character Variant 59',
	'cv60': 'Character Variant 60',
	'cv61': 'Character Variant 61',
	'cv62': 'Character Variant 62',
	'cv63': 'Character Variant 63',
	'cv64': 'Character Variant 64',
	'cv65': 'Character Variant 65',
	'cv66': 'Character Variant 66',
	'cv67': 'Character Variant 67',
	'cv68': 'Character Variant 68',
	'cv69': 'Character Variant 69',
	'cv70': 'Character Variant 70',
	'cv71': 'Character Variant 71',
	'cv72': 'Character Variant 72',
	'cv73': 'Character Variant 73',
	'cv74': 'Character Variant 74',
	'cv75': 'Character Variant 75',
	'cv76': 'Character Variant 76',
	'cv77': 'Character Variant 77',
	'cv78': 'Character Variant 78',
	'cv79': 'Character Variant 79',
	'cv80': 'Character Variant 80',
	'cv81': 'Character Variant 81',
	'cv82': 'Character Variant 82',
	'cv83': 'Character Variant 83',
	'cv84': 'Character Variant 84',
	'cv85': 'Character Variant 85',
	'cv86': 'Character Variant 86',
	'cv87': 'Character Variant 87',
	'cv88': 'Character Variant 88',
	'cv89': 'Character Variant 89',
	'cv90': 'Character Variant 90',
	'cv91': 'Character Variant 91',
	'cv92': 'Character Variant 92',
	'cv93': 'Character Variant 93',
	'cv94': 'Character Variant 94',
	'cv95': 'Character Variant 95',
	'cv96': 'Character Variant 96',
	'cv97': 'Character Variant 97',
	'cv98': 'Character Variant 98',
	'cv99': 'Character Variant 99'
	}
