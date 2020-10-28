# master_glif.pxi

@cython.final
cdef class c_master_glif:

  cdef public:
    string name, glif_name
    int mark
    vector[long] code_points
    bint omit, base

  def __init__(self, bytes name, bytes glif_name, int mark, code_points, bint omit, bint base):
    self.name = name
    self.glif_name = glif_name
    self.mark = mark
    for code_point in code_points:
      self.code_points.push_back(code_point)
    self.omit = omit
    self.base = base
