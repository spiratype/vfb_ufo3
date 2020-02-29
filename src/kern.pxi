# KERN

cdef inline long pair_calc(int n_glyphs) nogil:

	'''
	find the number of possible pairs for a number of glyphs

	>>> pair_calc(20)
	190
	>>> pair_calc(10)
	45
	>>> pair_calc(5)
	10
	>>> pair_calc(4)
	6
	'''

	cdef:
		int n_pairs = n_glyphs

	n_pairs *= n_glyphs - 1
	n_pairs /= 2

	return n_pairs
