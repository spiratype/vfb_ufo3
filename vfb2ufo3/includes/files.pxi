# files.pxi

cdef extern from 'includes/cpp/files.cpp' nogil:
  cppclass cpp_file

  void add_file(cpp_files, string, string)
  void write_files(vector[cpp_file])
