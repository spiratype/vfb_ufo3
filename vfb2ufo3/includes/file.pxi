# file.pxi

cdef extern from 'includes/cpp/file.cpp' nogil:
  string read_file(string)
  void write_file(string, string)
