# archive.pxi

@cython.final
cdef class c_archive:

	cdef:
		unordered_map[string, string] files
		string filename
		bint compress

	def __cinit__(self, bytes filename, bint compress):
		self.filename = filename
		self.compress = compress

	def __setitem__(self, bytes arc_name, string text):
		self.files[arc_name] = text

	def __reduce__(self):
		return self.__class__

	def reserve(self, size_t n):
		self.files.reserve(n)

	def write(self):
		write_archive(self.filename, self.files, self.compress)
