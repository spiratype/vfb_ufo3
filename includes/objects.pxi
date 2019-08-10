# OBJECTS

cimport cython

cdef extern from 'Python.h':
  int PyDict_SetItem(object o, object key, object val) except -1
  int PySet_Add(object o, object key) except -1

def repr_val(value):
  if isinstance(value, unicode):
    try:
      value = value.encode('cp1252').decode('utf_8')
    except UnicodeError:
      value = repr(value)[1:].decode('cp1252')
  elif isinstance(value, bytes):
    value = value.decode('cp1252')
  if isinstance(value, unicode):
    return value
  return repr(value).decode('cp1252')

def dict_repr(dictionary):
  rep = [f'{repr_val(key)}: {repr_val(value)}' for key, value in dictionary.items()]
  return py_bytes(f"{{{', '.join(rep)}}}")

def set_repr(set):
  return py_bytes(f"set([{', '.join([repr_val(key) for key in set])}])")

@cython.final
cdef class ordered_set(set):

  cdef:
    list mapping

  def __cinit__(self, other=None):
    self.mapping = []
    if isinstance(other, list):
      self.update(other)

  def add(self, key):
    if key not in self:
      self.mapping.append(key)
    PySet_Add(self, key)

  def __bool__(self):
    return bool(self.mapping)

  def update(self, other):
    for key in other:
      self.add(key)

  def __iter__(self):
    return (key for key in self.mapping)

  def __reduce__(self):
    return self.__class__

  def __repr__(self):
    return set_repr(self)

@cython.final
cdef class ordered_dict(dict):

  cdef:
    list mapping

  def __cinit__(self):
    self.mapping = []

  def __setitem__(self, key, value):
    if key not in self:
      self.mapping.append(key)
    PyDict_SetItem(self, key, value)

  def __bool__(self):
    return bool(self.mapping)

  def items(self):
    return ((key, self[key]) for key in self.mapping)

  def __reduce__(self):
    return self.__class__

  def __repr__(self):
    return dict_repr(self)


@cython.final
cdef class attribute_dict(dict):

  def __cinit__(self, args=None):
    if args:
      self.update(args)

  def __setattr__(self, key, value):
    PyDict_SetItem(self, key, value)

  def __getattr__(self, key):
    return self[key]

  def update(self, args):
    for key, value in args:
      PyDict_SetItem(self, key, value)
    return self

  def items(self):
    return ((key, self[key]) for key in self)

  def keys(self):
    return (key for key in self)

  def __reduce__(self):
    return self.__class__

  def __repr__(self):
    return dict_repr(self)
