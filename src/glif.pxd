# glif.pxd

from vector cimport vector
from unordered_map cimport unordered_map
from libcpp.string cimport string
from libcpp.utility cimport pair

cdef extern from 'includes/cpp/glif.cpp' nogil:
  void write_archive(string, unordered_map[string, string], bint)

  cppclass cpp_hint
  cppclass cpp_hint_replacement
  cppclass cpp_anchor
  cppclass cpp_component

  cppclass cpp_contour_point:
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

  cppclass cpp_ufo:
    vector[cpp_glif] glifs
    unordered_map[size_t, cpp_contours*] contours
    unordered_map[size_t, string] completed_contours
    int hint_type
    bint optimize
    bint ufoz
    void reserve(size_t)

  cppclass cpp_glif:
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

  void write_glifs(...)
