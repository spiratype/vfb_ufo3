# ordered_dict.pxi

@cython.final
cdef class ordered_dict(dict):

  cdef list mapping

  def __init__(self):
    self.mapping = []

  def __setitem__(self, key, value):
    if key not in self:
      self.mapping.append(key)
    PyDict_SetItem(self, key, value)

  def __bool__(self):
    return bool(self.mapping)

  def __reduce__(self):
    return self.__class__

  def items(self):
    return ((key, self[key]) for key in self.mapping)
