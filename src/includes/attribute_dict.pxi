# attribute_dict.pxi

cimport cython

from cpython.dict cimport PyDict_SetItem

@cython.final
cdef class attribute_dict(dict):

	def __cinit__(self, args=None):
		if args:
			self.update(args)

	def __setattr__(self, key, value):
		PyDict_SetItem(self, key, value)

	def __getattr__(self, key):
		return self[key]

	def __reduce__(self):
		return self.__class__

	def update(self, args):
		for key, value in args:
			PyDict_SetItem(self, key, value)
		return self

	def items(self):
		return ((key, self[key]) for key in self)

	def keys(self):
		return (key for key in self)
