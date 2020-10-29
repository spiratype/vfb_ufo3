# vfb.pxd

from libcpp.string cimport string
from libcpp_vector cimport vector

cdef class c_master_glif:

  cdef public:
    string name
    string glif_name
    int mark
    vector[long] code_points
    bint omit
    bint base
