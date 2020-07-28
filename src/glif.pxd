# glif.pxd

from libcpp cimport bool as bint
from libcpp.string cimport string
from libcpp.vector cimport vector
from libcpp.unordered_map cimport unordered_map

cdef extern from 'includes/cpp/glif.cpp' nogil:
	cppclass cpp_anchor
	cppclass cpp_component

	cppclass cpp_contour_point:
		cpp_contour_point(float, float, int, int)

	cppclass cpp_glif:
		string path
		size_t index
		size_t points_count
		size_t anchors_count
		size_t components_count
		bint omit
		cpp_glif()

	ctypedef vector[cpp_contour_point] cpp_contour
	ctypedef vector[cpp_contour] cpp_contours
	ctypedef vector[cpp_anchor] cpp_anchors
	ctypedef vector[cpp_component] cpp_components
	ctypedef vector[cpp_glif] cpp_glifs
	ctypedef unordered_map[size_t, cpp_anchors] cpp_anchor_lib
	ctypedef unordered_map[size_t, cpp_components] cpp_component_lib
	ctypedef unordered_map[size_t, cpp_contours] cpp_contour_lib
	ctypedef unordered_map[size_t, string] cpp_completed_contour_lib

	void add_anchor(cpp_anchors, string, float, float)
	void add_component(cpp_components, string, size_t, float, float, float, float)
	void add_contour_point(cpp_contour, float, float, int, int)
	void add_contour_point(cpp_contour, float, float, int)
	void add_glif(cpp_glifs, string, string, vector[long], int, float, size_t, size_t, size_t, size_t, bint, bint, bint)

	string build_glif(cpp_glif, cpp_anchor_lib, cpp_component_lib, cpp_contour_lib, cpp_completed_contour_lib, bint)
	void write_glif_files(cpp_glifs, cpp_anchor_lib, cpp_component_lib, cpp_contour_lib, cpp_completed_contour_lib)
