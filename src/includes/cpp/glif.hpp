// glif.hpp

#pragma once

static const std::vector<std::string> POINT_TYPES = {
  " ", // offcurve
  "curve",
  "qcurve",
  "line"
  };

static const std::vector<std::string> HINT_TYPES = {
  "",
  "com.adobe.type.autohint",
  "com.adobe.type.autohint.v2",
  "public.postscript.hints",
  };

struct cpp_anchor;
struct cpp_contour_point;
struct cpp_component;
struct cpp_hint;
struct cpp_hint_replacement;
struct cpp_glif;

typedef std::vector<cpp_contour_point> cpp_contour;
typedef std::vector<cpp_contour> cpp_contours;

struct cpp_ufo {
  std::vector<cpp_glif> glifs;
  std::unordered_map<size_t, cpp_contours*> contours;
  std::unordered_map<size_t, std::string> completed_contours;
  int hint_type;
  bool optimize;
  bool ufoz;
  void reserve(size_t n) {
    this->glifs.reserve(n);
    this->contours.reserve(n);
    this->completed_contours.reserve(n);
    }
  };
