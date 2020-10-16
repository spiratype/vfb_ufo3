# glif.pxd

from vector cimport vector
from unordered_map cimport unordered_map
from libcpp.string cimport string

cdef extern from 'includes/cpp/glif.cpp' nogil:
	cppclass cpp_hint
	cppclass cpp_hint_replacement
	cppclass cpp_anchor
	cppclass cpp_component

	cppclass cpp_contour_point:
		int type
		string name
		cpp_contour_point()
		cpp_contour_point(float, float)
		cpp_contour_point(float, float, int)
		cpp_contour_point(float, float, int, int)
		cpp_contour_point(float, float, int, string)
		cpp_contour_point(float, float, int, int, string)

	ctypedef vector[long] cpp_code_points
	ctypedef vector[cpp_anchor] cpp_anchors
	ctypedef vector[cpp_component] cpp_components
	ctypedef vector[cpp_hint] cpp_hints
	ctypedef vector[cpp_hint_replacement] cpp_hint_replacements
	ctypedef vector[cpp_contour_point] cpp_contour
	ctypedef vector[cpp_contour] cpp_contours

	cppclass cpp_ufo:
		vector[cpp_glif] glifs
		unordered_map[size_t, cpp_code_points] code_points
		unordered_map[size_t, cpp_anchors] anchors
		unordered_map[size_t, cpp_components] components
		unordered_map[size_t, cpp_hints] vhints
		unordered_map[size_t, cpp_hints] hhints
		unordered_map[size_t, cpp_hint_replacements] hint_replacements
		unordered_map[size_t, cpp_contours] contours
		unordered_map[size_t, string] completed_contours
		int hint_type
		void reserve(size_t, size_t, size_t, size_t, size_t)
		void hints_reserve(size_t, size_t, size_t)

	cppclass cpp_glif:
		string path
		void scale(float)
		string build(...)

	void write_glifs(...)
