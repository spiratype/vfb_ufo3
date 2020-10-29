# glif.pxd

from libcpp.string cimport string
from libcpp_unordered_map cimport unordered_map
from libcpp_vector cimport vector

cdef class c_archive:

  cdef:
    string filename
    bint compress
    unordered_map[string, string] files

cdef extern from 'includes/cpp/glif.cpp' nogil:
  cdef void write_archive(string, unordered_map[string, string], bint)

  cdef cppclass cpp_hint
  cdef cppclass cpp_hint_replacement
  cdef cppclass cpp_anchor
  cdef cppclass cpp_component

  cdef cppclass cpp_contour_point:
    string name
    int type
    size_t index
    cpp_contour_point()
    cpp_contour_point(float, float)
    cpp_contour_point(float, float, int)
    cpp_contour_point(float, float, int, int)
    cpp_contour_point(float, float, int, int, int)
    cpp_contour_point(float, float, int, int, string)

  ctypedef vector[cpp_contour_point] cpp_contour
  ctypedef vector[cpp_contour] cpp_contours

  cdef cppclass cpp_ufo:
    vector[cpp_glif] glifs
    unordered_map[size_t, cpp_contours*] contours
    int hint_type
    bint optimize
    bint ufoz
    void reserve(size_t)

  cdef cppclass cpp_glif:
    string path
    vector[long] code_points
    vector[cpp_anchor] anchors
    vector[cpp_component] components
    vector[cpp_hint] vhints
    vector[cpp_hint] hhints
    vector[cpp_hint_replacement] hint_replacements
    vector[cpp_contour] contours
    size_t index
    size_t len_hint_replacements
    cpp_glif()
    cpp_glif(string, string, int, float, size_t, size_t, bint, bint)
    void scale(float)
    string repr(...)

  cdef void write_glifs(...)
