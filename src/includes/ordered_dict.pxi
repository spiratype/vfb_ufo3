# ORDERED_DICT

cimport cython

from cpython.dict cimport PyDict_SetItem

@cython.final
cdef class ordered_dict(dict):

	cdef list mapping

	def __cinit__(self):
		self.mapping = []

	def __setitem__(self, key, value):
		if key not in self:
			self.mapping.append(key)
		PyDict_SetItem(self, key, value)

	def __bool__(self):
		return bool(self.mapping)

	def items(self):
		return ((key, self[key]) for key in self.mapping)

	def __reduce__(self):
		return self.__class__
