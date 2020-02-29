# NAMEID

import unicodedata

ENC_IDS = {1: 0, 3: 1}
LANG_IDS = {1: 0, 3: 0x0409}

def ascii_bytes(string):
	string = unicodedata.normalize('NFKD', string)
	return string.encode('ascii', 'ignore')

def ascii_unicode(string):
	string = unicodedata.normalize('NFKD', string)
	return string.encode('ascii', 'ignore').decode('ascii')

def nameid_str(string, platform_id, fontlab):

	"""
	format nameid string for features.fea 'name' table

	>>> nameid_string('© A Font Company', 3, 0)
	'\00a9 A Font Company'
	>>> nameid_string('© A Font Company', 1, 0)
	'\a9 A Font Company'
	>>> nameid_string('Joachim Müller-Lancé', 3, 0)
	'Joachim M\00fcller-Lanc\00e9'
	>>> nameid_string('Joachim Müller-Lancé', 3, 1)
	'Joachim M/00fcller-Lanc/00e9'
	>>> nameid_string('Joachim Müller-Lancé', 1, 0)
	'Joachim M\fcller-Lanc\e9'

	non-ASCII characters must be represented as a backslash-escaped character
	sequence

	in all cases, the double quote (") and backslash (\) characters must be
	represented as backslashed character sequences

	for Windows, non-ASCII characters are composed of a 4-digit backslash-escaped
	character sequence

	for Macintosh, non-ASCII character codes in the range 128-255 (e.g. ©, ø, ÿ)
	will be represented as a 2-digit backslash-escaped character sequence

	rather than ignoring characters outside of each platforms' restricted
	character set, the nearest ASCII replacement will be substituted if the
	original character cannot be represented within the sequence length
	requirements stated above

	the returned unicode string will be composed entirely of ASCII characters

	NOTE:
	although FontLab allows for non-ASCII characters as inputs, characters
	outside of the CP1252 code page are stored as either the nearest likely
	character or a '?'

	non-ASCII characters should be entered as described above, with a forward
	slash (/) in place of the backslash (\)

	https://adobe-type-tools.github.io/afdko/OpenTypeFeatureFileSpecification.html#9.e
	"""

	# macintosh platform id 1
	# microsoft platform id 3

	if platform_id == 1:
		enc_filter = 'mac_roman'
		repl_char = '\\'
	if platform_id == 3:
		enc_filter = 'utf_8'
		repl_char = '\\00'

	new_string = string.encode(enc_filter, 'ignore').decode(enc_filter)
	if len(new_string) != len(string):
		new_string = ascii_unicode(new_string)

	if '\\' in new_string:
		new_string = new_string.replace('\\', '\\x5c')
	if '"' in string:
		new_string = new_string.replace('"', '\\x22')

	new_string = new_string.encode('ascii', 'backslashreplace').decode('ascii')
	new_string = new_string.replace('\\x', repl_char).replace('\\u', '\\')

	if fontlab:
		return new_string.replace('\\', '/')
	return new_string
