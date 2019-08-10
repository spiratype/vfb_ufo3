# MARK

cdef extern from '<math.h>' nogil:
	long lround(double x)

cdef double UFO_SCALE = 1.0

def int_anchor_coords(double anchor_x, double anchor_y):
	cdef:
		long x, y
	with nogil:
		x, y = lround(anchor_x * UFO_SCALE), lround(anchor_y * UFO_SCALE)
	return x, y

def mark_class(parent, anchor):
	x, y = int_anchor_coords(anchor.x, anchor.y)
	anchor_name = py_unicode(anchor.name[1:])
	return f'\tmarkClass {parent} <anchor {x} {y}> @{anchor_name};'

def mark_base(base, anchor):
	x, y = int_anchor_coords(anchor.x, anchor.y)
	anchor_name = py_unicode(anchor.name)
	return f'\tpos base {base} <anchor {x} {y}> mark @{anchor_name};'
