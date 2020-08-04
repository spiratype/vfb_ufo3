# archive.pxi

cdef extern from 'includes/cpp/archive.cpp' nogil:
	void write_archive(string, unordered_map[string, string], bint)

@cython.final
cdef class c_archive:

	cdef:
		string filename
		bint compress
		unordered_map[string, string] files

	def __cinit__(self, string &filename, bint compress):
		self.filename = filename
		self.compress = compress

	def __setitem__(self, string &arc_name, string &text):
		self.files[arc_name] = text

	def __reduce__(self):
		return self.__class__

	def reserve(self, size_t n):
		self.files.reserve(n)

	def write(self):
		write_archive(self.filename, self.files, self.compress)
