# ATTRIBUTE_DICT

cimport cython

cdef extern from 'Python.h':
	int PyDict_SetItem(object, object, object) except -1

@cython.final
cdef class attribute_dict(dict):

	def __cinit__(self, args=None):
		if args:
			self.update(args)

	def __setattr__(self, key, value):
		PyDict_SetItem(self, key, value)

	def __getattr__(self, key):
		return self[key]

	def update(self, args):
		for key, value in args:
			PyDict_SetItem(self, key, value)
		return self

	def items(self):
		return ((key, self[key]) for key in self)

	def keys(self):
		return (key for key in self)

	def __reduce__(self):
		return self.__class__
