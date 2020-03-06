# MARK

cdef extern from '<math.h>' nogil:
	double nearbyint(double x)

cdef extern from '<fenv.h>' nogil:
	const int FE_TONEAREST
	int fesetround(int mode)
	int fegetround()

cdef int FE_MODE = fegetround()

cdef double SCALE = 1.0

cdef inline (long, long) int_anchor_coords(double x, double y) nogil:
	return <long>nearbyint(x * SCALE), <long>nearbyint(y * SCALE)

def mark_class(parent, anchor):
	x, y = int_anchor_coords(anchor.x, anchor.y)
	return f'\tmarkClass {parent} <anchor {x} {y}> @{py_unicode(anchor.name[1:])};'

def mark_base(base, anchor):
	x, y = int_anchor_coords(anchor.x, anchor.y)
	return f'\tpos base {base} <anchor {x} {y}> mark @{py_unicode(anchor.name)};'
