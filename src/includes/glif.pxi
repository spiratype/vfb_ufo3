# GLIF

from libcpp cimport bool as bint
from libcpp.string cimport string
from libcpp.vector cimport vector
from libcpp.unordered_map cimport unordered_map

cimport cython

import os

cdef extern from 'includes/cpp/glif.hpp' nogil:
	cppclass cpp_point:
		double x
		double y
		cpp_point()
		cpp_point(double x, double y)

	cppclass cpp_anchor:
		string name
		double x
		double y
		cpp_anchor()
		cpp_anchor(string name, double x, double y)

	cppclass cpp_contour_point:
		double x
		double y
		int type
		int alignment
		cpp_contour_point()
		cpp_contour_point(double x, double y, int type, int alignment)
		void scale(cpp_point &scale)
		void offset(cpp_point &offset)
		void scale_offset(cpp_point &scale, cpp_point &offset)

	ctypedef vector[cpp_contour_point] cpp_contour
	ctypedef vector[cpp_contour] cpp_contours

	cppclass cpp_component:
		string base
		size_t index
		cpp_point offset
		cpp_point scale
		cpp_component()
		cpp_component(string base, size_t index, double offset_x, double offset_y, double scale_x, double scale_y)

	cppclass cpp_glif:
		string name
		string path
		string text
		double width
		size_t index
		int mark
		vector[string] unicodes
		bint omit
		bint base
		bint has_anchors
		bint has_components
		bint has_contours
		bint optimize
		cpp_glif()
		cpp_glif(
			string &name,
			string &path,
			vector[string] &unicodes,
			int mark,
			double width,
			size_t index,
			bint omit,
			bint base,
			bint has_anchors,
			bint has_components,
			bint has_contours,
			bint optimize,
			)

	ctypedef vector[cpp_anchor] cpp_anchors
	ctypedef vector[cpp_component] cpp_components
	ctypedef vector[cpp_glif] cpp_glifs
	ctypedef unordered_map[size_t, cpp_anchors] cpp_anchor_lib
	ctypedef unordered_map[size_t, cpp_components] cpp_component_lib
	ctypedef unordered_map[size_t, cpp_contours] cpp_contour_lib

	string build_glif(
		cpp_glif &glif,
		cpp_anchor_lib &anchor_lib,
		cpp_component_lib &component_lib,
		cpp_contour_lib &contour_lib,
		bint ufoz,
		)
	void write_glif_files(
		cpp_glifs &glifs,
		cpp_anchor_lib &anchor_lib,
		cpp_component_lib &component_lib,
		cpp_contour_lib &contour_lib,
		bint ufoz,
		)


cdef double SCALE = 1.0

POINT_TYPES = {
	0: '',
	1: 'curve',
	2: 'qcurve',
	3: 'line',
	4: 'off',
	5: 'move',
	}
