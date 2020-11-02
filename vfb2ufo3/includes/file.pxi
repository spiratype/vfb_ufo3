# file.pxi

cdef extern from 'src/file.cpp' nogil:
  string read_file(string)
  void write_file(string, string)
