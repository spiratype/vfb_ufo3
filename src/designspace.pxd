# designspace.pxd

from libcpp.string cimport string

cdef class c_designspace:

  cdef public:
    string path
    string text
    list rules
    list axes
    list sources
    list instances
