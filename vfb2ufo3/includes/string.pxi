# string.pxi

cdef inline unicode uni_name(long code_point):

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


cdef inline unicode hex_code_point(long code_point):

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
