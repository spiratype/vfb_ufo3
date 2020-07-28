# plist.pxd

from libcpp cimport bool as bint
from libcpp.string cimport string
from libcpp.vector cimport vector

cdef extern from 'includes/cpp/files.cpp' nogil:
	cppclass cpp_file
	ctypedef vector[string] cpp_files

	void add_file(cpp_files, string, string)
	void write_files(cpp_files)
