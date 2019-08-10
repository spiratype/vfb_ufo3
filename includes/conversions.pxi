# CONVERSIONS

cdef tuple fl_mark_srgb(int fl_mark_color):

	'''
	convert FontLab mark color to sRGB

	>>> fl_mark_srgb(11)
	(0.91, 0.6031881323958155, 0.49000000000000005, 1.0)
	'''

	cdef:
		float hue
		float r, g, b
		# float v = 1., s = .3 # light colors
		float v = .91, s = .42 # dark colors
		int i

	with nogil:
		hue = (<float>fl_mark_color / 255.) * 360.
		i = <int>(hue / 60)
		m = v - s
		f = ((hue % 60) / 360.) * (360. / (280. * m))
		if not i:
			r, g, b = v, m + f, m
		elif i == 1:
			r, g, b = v - f, v, m
		elif i == 2:
			r, g, b = m, v, m + f
		elif i == 3:
			r, g, b = m, v - f, v
		elif i == 4:
			r, g, b = m + f, m, v
		elif i == 5:
			r, g, b = v, m, v - f

	return r, g, b, 1.
