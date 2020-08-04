# files.pxi

cdef extern from 'includes/cpp/files.cpp' nogil:
  cppclass cpp_file
  ctypedef vector[cpp_file] cpp_files

  void add_file(cpp_files, string, string)
  void write_files(cpp_files)
