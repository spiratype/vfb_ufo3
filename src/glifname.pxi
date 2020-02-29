# GLIFNAME

import re

GLIFNAMES = {
	'A': 'A_.glif',
	'AE': 'A_E_.glif',
	'A_A': 'A__A_.glif',
	'Aacute': 'A_acute.glif',
	'Acircumflex': 'A_circumflex.glif',
	'Adieresis': 'A_dieresis.glif',
	'Agrave': 'A_grave.glif',
	'Alpha': 'A_lpha.glif',
	'Alphatonos': 'A_lphatonos.glif',
	'Aring': 'A_ring.glif',
	'Atilde': 'A_tilde.glif',
	'B': 'B_.glif',
	'Beta': 'B_eta.glif',
	'C': 'C_.glif',
	'Cacute': 'C_acute.glif',
	'Ccaron': 'C_caron.glif',
	'Ccedilla': 'C_cedilla.glif',
	'Ccircumflex': 'C_circumflex.glif',
	'Chi': 'C_hi.glif',
	'D': 'D_.glif',
	'Dcroat': 'D_croat.glif',
	'E': 'E_.glif',
	'Eacute': 'E_acute.glif',
	'Ecircumflex': 'E_circumflex.glif',
	'Edieresis': 'E_dieresis.glif',
	'Egrave': 'E_grave.glif',
	'Eng': 'E_ng.glif',
	'Epsilon': 'E_psilon.glif',
	'Epsilontonos': 'E_psilontonos.glif',
	'Eta': 'E_ta.glif',
	'Etatonos': 'E_tatonos.glif',
	'Eth': 'E_th.glif',
	'Euro': 'E_uro.glif',
	'Euro.sc': 'E_uro.sc.glif',
	'Euro.smcp': 'E_uro.smcp.glif',
	'F': 'F_.glif',
	'G': 'G_.glif',
	'Gamma': 'G_amma.glif',
	'Gbreve': 'G_breve.glif',
	'Gtilde': 'G_tilde.glif',
	'H': 'H_.glif',
	'Hbar': 'H_bar.glif',
	'I': 'I_.glif',
	'IJ': 'I_J_.glif',
	'IJacute': 'I_J_acute.glif',
	'Iacute': 'I_acute.glif',
	'Icircumflex': 'I_circumflex.glif',
	'Idieresis': 'I_dieresis.glif',
	'Idotaccent': 'I_dotaccent.glif',
	'Igrave': 'I_grave.glif',
	'Iota': 'I_ota.glif',
	'Iotadieresis': 'I_otadieresis.glif',
	'Iotatonos': 'I_otatonos.glif',
	'Itilde': 'I_tilde.glif',
	'J': 'J_.glif',
	'Jacute': 'J_acute.glif',
	'Jcaron': 'J_caron.glif',
	'K': 'K_.glif',
	'K_A': 'K__A_.glif',
	'Kappa': 'K_appa.glif',
	'Kappa_Lambda': 'K_appa_L_ambda.glif',
	'Kcircumflex': 'K_circumflex.glif',
	'L': 'L_.glif',
	'L_A': 'L__A_.glif',
	'Lambda': 'L_ambda.glif',
	'Lambda_Lambda': 'L_ambda_L_ambda.glif',
	'Lslash': 'L_slash.glif',
	'M': 'M_.glif',
	'Mcircumflex': 'M_circumflex.glif',
	'Mdieresis': 'M_dieresis.glif',
	'Mu': 'M_u.glif',
	'N': 'N_.glif',
	'Ncircumflex': 'N_circumflex.glif',
	'Ntilde': 'N_tilde.glif',
	'Nu': 'N_u.glif',
	'O': 'O_.glif',
	'OE': 'O_E_.glif',
	'Oacute': 'O_acute.glif',
	'Ocircumflex': 'O_circumflex.glif',
	'Odieresis': 'O_dieresis.glif',
	'Ograve': 'O_grave.glif',
	'Omegatonos': 'O_megatonos.glif',
	'Omicron': 'O_micron.glif',
	'Omicrontonos': 'O_microntonos.glif',
	'Oslash': 'O_slash.glif',
	'Otilde': 'O_tilde.glif',
	'P': 'P_.glif',
	'Phi': 'P_hi.glif',
	'Pi': 'P_i.glif',
	'Psi': 'P_si.glif',
	'Q': 'Q_.glif',
	'R': 'R_.glif',
	'R_A': 'R__A_.glif',
	'Rho': 'R_ho.glif',
	'S': 'S_.glif',
	'Scaron': 'S_caron.glif',
	'Scedilla': 'S_cedilla.glif',
	'Sigma': 'S_igma.glif',
	'T': 'T_.glif',
	'T_h': 'T__h.glif',
	'Tau': 'T_au.glif',
	'Tbar': 'T_bar.glif',
	'Theta': 'T_heta.glif',
	'Thorn': 'T_horn.glif',
	'U': 'U_.glif',
	'Uacute': 'U_acute.glif',
	'Ucircumflex': 'U_circumflex.glif',
	'Udieresis': 'U_dieresis.glif',
	'Ugrave': 'U_grave.glif',
	'Upsilon': 'U_psilon.glif',
	'Upsilondieresis': 'U_psilondieresis.glif',
	'Upsilontonos': 'U_psilontonos.glif',
	'V': 'V_.glif',
	'W': 'W_.glif',
	'X': 'X_.glif',
	'Xi': 'X_i.glif',
	'Xmacron': 'X_macron.glif',
	'Y': 'Y_.glif',
	'Yacute': 'Y_acute.glif',
	'Ydieresis': 'Y_dieresis.glif',
	'Z': 'Z_.glif',
	'Zcaron': 'Z_caron.glif',
	'Zdieresis': 'Z_dieresis.glif',
	'Zeta': 'Z_eta.glif',
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
		message = (
			f"'{name}' contains at least 1 invalid character.\n"
			f"Glyph should be renamed or 'fdk_release' set to False\n"
			f"Valid Type 1 spec glyph name character set:\n"
			f"A-Z, a-z, 0-9, '.' (period), and '_' (underscore)."
			)
		super(GlyphNameError, self).__init__(message)

class GlyphUnicodeError(Exception):
	def __init__(self, message):
		super(GlyphUnicodeError, self).__init__(message)

def GlyphNameWarning(name):
	message = (
		f"  GlyphNameWarning: '{name}' contains at least 1 non-ASCII character.\n"
		f"  Valid production glyph name character set:\n"
		f"  A-Z, a-z, 0-9, and [_ . - + * : ~ ^ !]"
		)
	print(message)

REGEX_PRODUCTION = re.compile(
	'[A-Za-z_\-\+\*\:\~\^\!][A-Za-z0-9_.\-\+\*\:\~\^\!]* *$'
	)
REGEX_RELEASE = re.compile(
	'[A-Za-z_][A-Za-z0-9_.]* *$'
	)
REGEX_EARLY_MATCH = re.compile(
	'[a-z0-9]* *$'
	)

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

	if b'.notdef' == bytes_glyph_name:
		return '_notdef.glif'

	if bytes_glyph_name in BYTES_INVALID_NAMES:
		return f'_{bytes_glyph_name}.glif'

	try:
		glyph_name = bytes_glyph_name.decode('ascii')
	except UnicodeError:
		if release_mode:
			raise GlyphNameError(bytes_glyph_name)
		GlyphNameWarning(bytes_glyph_name)

	if re.match(REGEX_EARLY_MATCH, glyph_name):
		return f'{glyph_name[:250]}.glif'

	if not omit:
		glyph_name = check_glyph_name(glyph_name, release_mode)

	if '.' in glyph_name[0]:
		glyph_name = '_' + glyph_name[1:]

	if '.' in glyph_name:
		glyph_name_list = glyph_name.split('.')
		for i, name in enumerate(glyph_name_list):
			if name in INVALID_NAMES:
				glyph_name = replace_invalid_name(glyph_name_list[:], i, name)
				break

	filename = []
	for char in glyph_name:
		if char in INVALID_CHARACTERS:
			filename.append('_')
		elif char.isupper():
			filename += [char, '_']
		else:
			filename.append(char)

	return f"{''.join(filename)[:250]}.glif"

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
