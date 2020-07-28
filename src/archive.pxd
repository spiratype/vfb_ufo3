# archive.pxd

from libcpp cimport bool as bint
from libcpp.unordered_map cimport unordered_map
from libcpp.string cimport string

cdef extern from 'includes/cpp/zip.cpp' nogil:
	void write_archive(string, unordered_map[string, string], bint)
