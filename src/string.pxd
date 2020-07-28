
from libc.math cimport nearbyint

cdef inline unicode cp1252_unicode_str(bytes bytes_str):
	return bytes_str.decode('cp1252', 'ignore')

cdef inline bytes cp1252_bytes_str(unicode unicode_str):
	return unicode_str.encode('cp1252', 'ignore')

cdef inline bytes cp1252_ascii_bytes_str(bytes cp1252_bytes):
	return cp1252_bytes.decode('cp1252').encode('ascii')

cdef inline bytes cp1252_utf8_bytes_str(bytes cp1252_bytes):
	return cp1252_bytes.decode('cp1252').encode('utf_8')

cdef inline bytes file_bytes_str(unicode unicode_str):
	try:
		return unicode_str.encode('ascii')
	except UnicodeError:
		return unicode_str.encode('utf_8')

cdef inline bytes ascii_bytes_str(unicode unicode_str):
	return unicode_str.encode('ascii')

cdef inline bytes utf8_bytes_str(unicode unicode_str):
	return unicode_str.encode('utf_8')

cdef inline unicode uni_name(code_point):

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
		return f'uni{code_point:04X}'
	return f'u{code_point:05X}'


cdef inline unicode hex_code_point(code_point):

	'''
	convert integer to a zero-filled, uppercase hexadecimal value string
	without leading 0x prefix

	>>> hex_code_point(182)
	00B6
	>>> hex_code_point(80)
	0050
	'''

	if code_point <= 0xffff:
		return f'{code_point:04X}'
	return f'{code_point:05X}'


cdef inline unicode float_str(n, precision):

	'''
	return float to `precision` decimal places

	>>> number_str(4.053154, 2)
	4.05
	>>> number_str(4.053154, 1)
	4.1
	'''

	return f'{n:.{precision}}'

cdef inline unicode number_str(double n):

	'''
	return str(int) if int(number) ≈ number

	>>> number_str(4.0)
	4
	>>> number_str(4.05)
	4.1
	'''

	cdef double k = nearbyint(n)
	if k == n:
		return str(<long>k)
	return f'{n:.1f}'
