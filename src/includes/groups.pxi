# groups.pxi

PREFIX_1 = 'public.kern1.'
PREFIX_2 = 'public.kern2.'

def KeyGlyphWarning(group, key_glyph):
	print(f"  A key glyph was not found in kerning group '{group}'.\n"
		f"  '{key_glyph}' was marked as the key glyph.")


def FontLabClassWarning(name, glyphs):
	glyphs = "', '".join(glyphs)
	print(f"  Font contains more than 1 FontLab class named '{name}'.'\n"
		f"  glyphs = ['{glyphs}']")


def insert_key_glyph(glyphs, key_glyph):

	'''
	insert key glyph into glyph list

	insert_key_glyph(['A', 'AA', 'AE', 'Aacute', 'Agrave', 'Acircumflex'], 'A')
	>>> "A' AA AE Aacute Agrave Acircumflex"
	insert_key_glyph(['A', 'AA', 'AE', 'Aacute', 'Agrave', 'Acircumflex'], 'AE')
	>>> "A AA AE' Aacute Agrave Acircumflex"
	'''

	_glyphs = glyphs[:]
	index = glyphs.index(key_glyph)
	_glyphs[index] = key_glyph + "'"

	return ' '.join(_glyphs)


def group_key_glyph(glyphs_string, has_key_glyph):

	'''
	key glyph from .flc or current fl.font.classes

	check glyph group for a key glyph
	if no key glyph is found, mark the first glyph as the key glyph

	group_key_glyph("A' AA AE Aacute Agrave Acircumflex", 1)
	>>> (A, ['A', 'AA', 'AE', 'Aacute', 'Agrave', 'Acircumflex'], 0)
	group_key_glyph('A AA AE Aacute Agrave Acircumflex', 0)
	>>> (A, ['A', 'AA', 'AE', 'Aacute', 'Agrave', 'Acircumflex'], 1)
	'''

	if has_key_glyph:
		chunk = glyphs_string.split("'")[0].split()
		key_glyph = chunk[len(chunk) - 1]
		return key_glyph, 0

	glyphs = glyphs_string.split()
	key_glyph = glyphs[0]
	return key_glyph, 1
