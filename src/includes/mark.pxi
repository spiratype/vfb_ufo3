# MARK

cdef extern from '<math.h>' nogil:
	double nearbyint(double x)

cdef extern from '<fenv.h>' nogil:
	const int FE_TONEAREST
	int fesetround(int mode)
	int fegetround()

cdef int FE_MODE = fegetround()

cdef double UFO_SCALE = 1.0

ctypedef struct cPoint:
	long x, y

cdef inline cPoint int_anchor_coords(double anchor_x, double anchor_y) nogil:
	cdef:
		cPoint point
	fesetround(FE_TONEAREST)
	point.x = <long>nearbyint(anchor_x * UFO_SCALE)
	point.y = <long>nearbyint(anchor_y * UFO_SCALE)
	fesetround(FE_MODE)
	return point

def mark_class(parent, anchor):
	coords = int_anchor_coords(anchor.x, anchor.y)
	anchor_name = py_unicode(anchor.name[1:])
	return f'\tmarkClass {parent} <anchor {coords.x} {coords.y}> @{anchor_name};'

def mark_base(base, anchor):
	coords = int_anchor_coords(anchor.x, anchor.y)
	anchor_name = py_unicode(anchor.name)
	return f'\tpos base {base} <anchor {coords.x} {coords.y}> mark @{anchor_name};'
