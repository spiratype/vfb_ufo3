# STRING

cdef extern from '<math.h>' nogil:
	long lround(double x)

def file_str(unicode_str):

	try:
		return unicode_str.encode('ascii')
	except UnicodeError:
		return unicode_str.encode('utf_8')


def uni_name(code_point):

	'''
	convert hex string or integer into a glyph name

	hex values of 0x0000 through 0xffff which correspond to character code points
	in the BMP are prefixed with 'uni'; larger code points are prefixed with 'u'

	>>> glyph_uni_name(0x00ac)
	uni00AC
	>>> glyph_uni_name(0x1f657)
	u1F657
	'''

	if code_point <= 0xffff:
		return 'uni%04X' % code_point
	return 'u%05X' % code_point


def hex_code_point(code_point):

	'''
	convert integer to a zero-filled, uppercase hexadecimal value string
	without leading 0x prefix

	>>> hex_code_point(182)
	00B6
	>>> hex_code_point(80)
	0050
	'''

	if code_point <= 0xffff:
		return '%04X' % code_point
	return '%05X' % code_point


def number_str(double n):

	'''
	return int if int(number) ≈ number

	>>> number_str(4.0)
	4
	>>> number_str(4.05)
	4.1
	'''

	cdef:
		long k
		bint a = 0

	with nogil:
		k = lround(n)
		if k == n:
			a = 1

	if a:
		return str(k)
	return '%.1f' % n
