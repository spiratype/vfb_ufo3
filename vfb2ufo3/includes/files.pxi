# files.pxi

cdef extern from 'src/files.cpp' nogil:
  cdef cppclass cpp_file

  void add_file(cpp_files, string, string)
  void write_files(vector[cpp_file])
