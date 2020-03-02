# STRING

cdef extern from '<math.h>' nogil:
	double nearbyint(double x)

cdef extern from '<fenv.h>' nogil:
	const int FE_TONEAREST
	int fesetround(int mode)
	int fegetround()

cdef int FE_MODE = fegetround()

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

	return 'uni%04X' % code_point if code_point <= 0xffff else 'u%05X' % code_point


cdef inline bytes hex_code_point(code_point):

	'''
	convert integer to a zero-filled, uppercase hexadecimal value string
	without leading 0x prefix

	>>> hex_code_point(182)
	00B6
	>>> hex_code_point(80)
	0050
	'''

	return b'%04X' % code_point if code_point <= 0xffff else b'%05X' % code_point


cdef inline number_str(double n):

	'''
	return str(int) if int(number) ≈ number

	>>> number_str(4.0)
	4
	>>> number_str(4.05)
	4.1
	'''

	cdef:
		double k
		bint a

	with nogil:
		k = nearbyint(n)
		a = 1 if k == n else 0

	return str(<long>k) if a else '%.1f' % n

cdef inline float_str(double n, unsigned int precision):

	'''
	return float to `precision` decimal places

	>>> number_str(4.053154, 2)
	4.05
	>>> number_str(4.053154, 1)
	4.1
	'''

	return f'{n:.{precision}}'

