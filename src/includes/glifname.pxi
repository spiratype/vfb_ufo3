# GLIFNAME

import re

GLIFNAMES = {
	b'.notdef': '_notdef.glif',
	b'space': 'space.glif',
	b'A': 'A_.glif',
	b'AE': 'A_E_.glif',
	b'A_A': 'A__A_.glif',
	b'Aacute': 'A_acute.glif',
	b'Acircumflex': 'A_circumflex.glif',
	b'Adieresis': 'A_dieresis.glif',
	b'Agrave': 'A_grave.glif',
	b'Alpha': 'A_lpha.glif',
	b'Alphatonos': 'A_lphatonos.glif',
	b'Aring': 'A_ring.glif',
	b'Atilde': 'A_tilde.glif',
	b'B': 'B_.glif',
	b'Beta': 'B_eta.glif',
	b'C': 'C_.glif',
	b'Cacute': 'C_acute.glif',
	b'Ccaron': 'C_caron.glif',
	b'Ccedilla': 'C_cedilla.glif',
	b'Ccircumflex': 'C_circumflex.glif',
	b'Chi': 'C_hi.glif',
	b'D': 'D_.glif',
	b'Dcroat': 'D_croat.glif',
	b'E': 'E_.glif',
	b'Eacute': 'E_acute.glif',
	b'Ecircumflex': 'E_circumflex.glif',
	b'Edieresis': 'E_dieresis.glif',
	b'Egrave': 'E_grave.glif',
	b'Eng': 'E_ng.glif',
	b'Epsilon': 'E_psilon.glif',
	b'Epsilontonos': 'E_psilontonos.glif',
	b'Eta': 'E_ta.glif',
	b'Etatonos': 'E_tatonos.glif',
	b'Eth': 'E_th.glif',
	b'Euro': 'E_uro.glif',
	b'Euro.sc': 'E_uro.sc.glif',
	b'Euro.smcp': 'E_uro.smcp.glif',
	b'F': 'F_.glif',
	b'G': 'G_.glif',
	b'Gamma': 'G_amma.glif',
	b'Gbreve': 'G_breve.glif',
	b'Gtilde': 'G_tilde.glif',
	b'H': 'H_.glif',
	b'Hbar': 'H_bar.glif',
	b'I': 'I_.glif',
	b'IJ': 'I_J_.glif',
	b'IJacute': 'I_J_acute.glif',
	b'Iacute': 'I_acute.glif',
	b'Icircumflex': 'I_circumflex.glif',
	b'Idieresis': 'I_dieresis.glif',
	b'Idotaccent': 'I_dotaccent.glif',
	b'Igrave': 'I_grave.glif',
	b'Iota': 'I_ota.glif',
	b'Iotadieresis': 'I_otadieresis.glif',
	b'Iotatonos': 'I_otatonos.glif',
	b'Itilde': 'I_tilde.glif',
	b'J': 'J_.glif',
	b'Jacute': 'J_acute.glif',
	b'Jcaron': 'J_caron.glif',
	b'K': 'K_.glif',
	b'K_A': 'K__A_.glif',
	b'Kappa': 'K_appa.glif',
	b'Kappa_Lambda': 'K_appa_L_ambda.glif',
	b'Kcircumflex': 'K_circumflex.glif',
	b'L': 'L_.glif',
	b'L_A': 'L__A_.glif',
	b'Lambda': 'L_ambda.glif',
	b'Lambda_Lambda': 'L_ambda_L_ambda.glif',
	b'Lslash': 'L_slash.glif',
	b'M': 'M_.glif',
	b'Mcircumflex': 'M_circumflex.glif',
	b'Mdieresis': 'M_dieresis.glif',
	b'Mu': 'M_u.glif',
	b'N': 'N_.glif',
	b'Ncircumflex': 'N_circumflex.glif',
	b'Ntilde': 'N_tilde.glif',
	b'Nu': 'N_u.glif',
	b'O': 'O_.glif',
	b'OE': 'O_E_.glif',
	b'Oacute': 'O_acute.glif',
	b'Ocircumflex': 'O_circumflex.glif',
	b'Odieresis': 'O_dieresis.glif',
	b'Ograve': 'O_grave.glif',
	b'Omegatonos': 'O_megatonos.glif',
	b'Omicron': 'O_micron.glif',
	b'Omicrontonos': 'O_microntonos.glif',
	b'Oslash': 'O_slash.glif',
	b'Otilde': 'O_tilde.glif',
	b'P': 'P_.glif',
	b'Phi': 'P_hi.glif',
	b'Pi': 'P_i.glif',
	b'Psi': 'P_si.glif',
	b'Q': 'Q_.glif',
	b'R': 'R_.glif',
	b'R_A': 'R__A_.glif',
	b'Rho': 'R_ho.glif',
	b'S': 'S_.glif',
	b'Scaron': 'S_caron.glif',
	b'Scedilla': 'S_cedilla.glif',
	b'Sigma': 'S_igma.glif',
	b'T': 'T_.glif',
	b'T_h': 'T__h.glif',
	b'Tau': 'T_au.glif',
	b'Tbar': 'T_bar.glif',
	b'Theta': 'T_heta.glif',
	b'Thorn': 'T_horn.glif',
	b'U': 'U_.glif',
	b'Uacute': 'U_acute.glif',
	b'Ucircumflex': 'U_circumflex.glif',
	b'Udieresis': 'U_dieresis.glif',
	b'Ugrave': 'U_grave.glif',
	b'Upsilon': 'U_psilon.glif',
	b'Upsilondieresis': 'U_psilondieresis.glif',
	b'Upsilontonos': 'U_psilontonos.glif',
	b'V': 'V_.glif',
	b'W': 'W_.glif',
	b'X': 'X_.glif',
	b'Xi': 'X_i.glif',
	b'Xmacron': 'X_macron.glif',
	b'Y': 'Y_.glif',
	b'Yacute': 'Y_acute.glif',
	b'Ydieresis': 'Y_dieresis.glif',
	b'Z': 'Z_.glif',
	b'Zcaron': 'Z_caron.glif',
	b'Zdieresis': 'Z_dieresis.glif',
	b'Zeta': 'Z_eta.glif',
	}

INVALID_CHARACTERS = {
	'“', '*', '+', '/', ':', '<', '>', '?', '[', ']', '|',
	'\t', '&', '\r', '\\', '\x00', '\x01', '\x02', '\x03',
	'\x04', '\x05', '\x06', '\x07', '\x08', '\x0b', '\x0c',
	'\x0e', '\x0f', '\x10', '\x11', '\x12', '\x13', '\x14',
	'\x15', '\x16', '\x17', '\x18', '\x19', '\x1a', '\x1b',
	'\x1c', '\x1d', '\x1e', '\x1f', '\x7f',
	}

INVALID_NAMES = {
	'lpt1', 'lpt2', 'lpt3', 'a:-z:', 'com1', 'com2', 'com3',
	'com4', 'con', 'prn', 'aux', 'nul', 'clock$',
	}

BYTES_INVALID_NAMES = {py_bytes(name) for name in INVALID_NAMES}

class GlyphNameError(Exception):
	def __init__(self, name):
		message = py_bytes(
			f"{name!r} contains at least 1 invalid character.\n"
			f"Glyph should be renamed or 'fdk_release' set to False\n"
			f"Valid Type 1 spec glyph name character set:\n"
			f"A-Z, a-z, 0-9, '.' (period), and '_' (underscore)."
			)
		super(GlyphNameError, self).__init__(message)

class GlyphUnicodeError(Exception):
	def __init__(self, message):
		super(GlyphUnicodeError, self).__init__(py_bytes(message))

def GlyphNameWarning(name):
	message = (
		f'  GlyphNameWarning: {name!r} contains at least 1 non-ASCII character.\n'
		f'  Valid production glyph name character set:\n'
		f'  A-Z, a-z, 0-9, and [_ . - + * : ~ ^ !]'
		)
	print(message)

REGEX_PRODUCTION = re.compile('[A-Za-z_\-\+\*\:\~\^\!][A-Za-z0-9_.\-\+\*\:\~\^\!]* *$')
REGEX_RELEASE = re.compile('[A-Za-z_][A-Za-z0-9_.]* *$')
REGEX_EARLY_MATCH = re.compile('[a-z0-9]* *$')

def glifname(bytes_glyph_name, release_mode, omit):

	'''
	return valid glyph name and glif filename from glyph name

	FontLab does not allow for duplicate glyph names; however, glyph names
	containing non-ASCII characters can be entered

	>>> glif_name("a")
	a.glif
	>>> glif_name("A")
	A_.glif
	'''

	if bytes_glyph_name in BYTES_INVALID_NAMES:
		return f'_{bytes_glyph_name}.glif'

	try:
		glyph_name = bytes_glyph_name.decode('ascii')
	except UnicodeError:
		if release_mode:
			raise GlyphNameError(bytes_glyph_name)
		GlyphNameWarning(bytes_glyph_name)
		glyph_name = py_unicode(bytes_glyph_name)

	if re.match(REGEX_EARLY_MATCH, glyph_name):
		return f'{glyph_name[:250]}.glif'

	if not omit:
		glyph_name = check_glyph_name(glyph_name, release_mode)

	if glyph_name.startswith('.'):
		glyph_name = f'_{glyph_name[1:]}'

	if '.' in glyph_name:
		glyph_name_list = glyph_name.split('.')
		for i, name in enumerate(glyph_name_list):
			if name in INVALID_NAMES:
				glyph_name = replace_invalid_name(glyph_name_list[:], i, name)
				break

	filename = ''
	for character in glyph_name:
		if character in INVALID_CHARACTERS:
			filename += '_'
		elif character.isupper():
			filename += character + '_'
		else:
			filename += character

	return f'{"".join(filename)[:250]}.glif'

def replace_invalid_name(name_list, index, name):

	name_list[index] = '_' + name
	for i, name in enumerate(name_list):
		if name in INVALID_NAMES:
			replace_invalid_name(name_list[:], i, name)

	return '.'.join(name_list)

def check_glyph_name(glyph_name, release_mode):

	if release_mode:
		if re.match(REGEX_RELEASE, glyph_name):
			return glyph_name
		raise GlyphNameError(glyph_name)

	if re.match(REGEX_PRODUCTION, glyph_name):
		return glyph_name

	GlyphNameWarning(glyph_name)
	return glyph_name
