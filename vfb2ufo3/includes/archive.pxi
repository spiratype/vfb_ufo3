# archive.pxi

@cython.final
cdef class c_archive:

  def __init__(self, string &filename, bint compress):
    self.filename = filename
    self.compress = compress

  def __reduce__(self):
    return self.__class__

  def __setitem__(self, string &arc_name, string &text):
    self.files.emplace(arc_name, move(text))

  def reserve(self, size_t n):
    self.files.reserve(n)

  def write(self):
    write_archive(self.filename, self.files, self.compress)
