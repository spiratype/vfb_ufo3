# io.pxd

from libcpp.string cimport string

cdef extern from 'includes/cpp/file.cpp' nogil:
	cppclass cpp_file:
		cpp_file(string, string)

	void write_file(cpp_file)
