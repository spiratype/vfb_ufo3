# flc.pxi

FLC_HEADER =               '%%FONTLAB CLASSES'
FLC_GROUP_MARKER =         '%%CLASS'
FLC_GLYPHS_MARKER =        '%%GLYPHS '
FLC_KERNING_MARKER =       '%%KERNING'
FLC_LEFT_KERNING_MARKER =  '%%KERNING L 0'
FLC_RIGHT_KERNING_MARKER = '%%KERNING R 0'
FLC_END_MARKER =           '%%END'

def parse_flc(flc_file):

	'''
	flc_file = """
	%%FONTLAB CLASSES

	%%CLASS _A
	%%GLYPHS  A' Agrave Aacute Acircumflex Atilde
	%%KERNING L 0
	%%END
	"""

	parsed = parse_flc(flc_file)
	>>> {'_A': ('L', "A' Agrave Aacute Acircumflex Atilde")}
	'''

	parsed = {}
	kern_group = 0

	flc_file = flc_file.replace('@', '')
	flc_file = [line for line in flc_file.splitlines() if line]
	for line in flc_file:
		if line.startswith('%%C'):
			kern_group = 0
			name = line.split()[1]
		if line.startswith('%%G'):
			glyphs = line[8:].strip()
		if line.startswith('%%K'):
			kern_group = 1
			kerning_flag = line.split()[1]
		if line.startswith('%%E'):
			if kern_group:
				parsed[name] = [kerning_flag, glyphs]
			else:
				parsed[name] = [None, glyphs]

	return parsed

