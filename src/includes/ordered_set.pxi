# ordered_set.pxi

@cython.final
cdef class ordered_set(set):

	cdef list mapping

	def __cinit__(self, other=None):
		self.mapping = []
		if isinstance(other, list):
			self.update(other)

	def __bool__(self):
		return bool(self.mapping)

	def __iter__(self):
		return (key for key in self.mapping)

	def __reduce__(self):
		return self.__class__

	def add(self, key):
		if key not in self:
			self.mapping.append(key)
		PySet_Add(self, key)

	def update(self, other):
		for key in other:
			self.add(key)
