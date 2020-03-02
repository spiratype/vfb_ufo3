// glif.hpp

#include <cfenv>
#include <cmath>
#include <iomanip>
#include <omp.h>
#include <sstream>
#include <string>
#include <thread>
#include <unordered_map>
#include <vector>

#include "io.hpp"
#include "string.hpp"
#include "srgb.hpp"
#include "mark.hpp"

const std::string XML_PROLOG = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n";

std::unordered_map<int, std::string> POINT_TYPES = {
	{0, ""},
	{1, "curve"},
	{2, "qcurve"},
	{3, "line"},
	{4, "off"},
	{5, "move"},
	};

class cpp_point;
class cpp_anchor;
class cpp_contour_point;
class cpp_component;
class cpp_glif;

typedef std::vector<cpp_contour_point> cpp_contour;
typedef std::vector<cpp_contour> cpp_contours;

std::string items_repr(auto &items) {
	std::stringstream items_stream;
	for (auto &item : items)
		items_stream << item.repr();
	return items_stream.str();
	}

class cpp_point {
	public:
		double x;
		double y;
		cpp_point() {};
		cpp_point(double x, double y) {
			this->x = x;
			this->y = y;
			}
		bool operator==(const cpp_point& other) const {
			return std::tie(x, y) == std::tie(other.x, other.y);
			}
		bool operator!=(const cpp_point& other) const {
			return std::tie(x, y) != std::tie(other.x, other.y);
			}
	};

class cpp_anchor {
	private:
		std::string name;
		double x;
		double y;
	public:
		cpp_anchor() {};
		cpp_anchor(std::string name, double x, double y) {
			this->name = name;
			this->x = x;
			this->y = y;
			}
		std::vector<std::string> attrs() {
			std::vector<std::string> attrs = {
				attr("name", this->name),
				attr("x", number_str(this->x)),
				attr("y", number_str(this->y)),
				};
			return attrs;
			}
		std::string repr() {
			return "\t<anchor " + attrs_str(this->attrs()) + "/>\n";
			}
	};

class cpp_contour_point {
	private:
		double x;
		double y;
		int type;
		int alignment;
	public:
		cpp_contour_point() {};
		cpp_contour_point(double x, double y, int type, int alignment) {
			this->x = x;
			this->y = y;
			this->type = type;
			this->alignment = alignment;
			}
		void scale(cpp_point &scale) {
			this->x *= scale.x;
			this->y *= scale.y;
			}
		void offset(cpp_point &offset) {
			this->x += offset.x;
			this->y += offset.y;
			}
		void scale_offset(cpp_point &scale, cpp_point &offset) {
			this->x += offset.x;
			this->y += offset.y;
			this->x *= scale.x;
			this->y *= scale.y;
			}
		std::vector<std::string> attrs() {
			std::vector<std::string> attrs;
			if (this->type == 4) {
				attrs = {
					attr("x", number_str(this->x)),
					attr("y", number_str(this->y)),
					};
				}
			else if (this->alignment != 0) {
				attrs = {
					attr("x", number_str(this->x)),
					attr("y", number_str(this->y)),
					attr("type", POINT_TYPES[this->type]),
					attr("smooth", "yes"),
					};
				}
			else {
				attrs = {
					attr("x", number_str(this->x)),
					attr("y", number_str(this->y)),
					attr("type", POINT_TYPES[this->type]),
					};
				}
			return attrs;
			}
		std::string repr() {
			return "\t\t\t<point " + attrs_str(this->attrs()) + "/>\n";
			}
	};

class cpp_component {
	private:
		std::string base;
	public:
		size_t index;
		cpp_point offset;
		cpp_point scale;
		cpp_component() {};
		cpp_component(std::string base, size_t index, double offset_x, double offset_y, double scale_x, double scale_y) {
			this->base = base;
			this->index = index;
			this->offset = cpp_point(offset_x, offset_y);
			this->scale = cpp_point(scale_x, scale_y);
			}
		std::vector<std::string> attrs() {
			std::vector<std::string> attrs = {
				attr("base", this->base),
				attr("xOffset", number_str(this->offset.x)),
				attr("yOffset", number_str(this->offset.y)),
				attr("xScale", float_str(this->scale.x, 2)),
				attr("yScale", float_str(this->scale.y, 2)),
				};
			return attrs;
			}
		std::string repr() {
			return "\t\t<component " + attrs_str(this->attrs()) + "/>\n";
			}
	};

class cpp_glif {
	public:
		std::string name;
		std::string path;
		std::string text;
		double width;
		size_t index;
		int mark;
		std::vector<std::string> unicodes;
		bool omit;
		bool base;
		bool has_anchors;
		bool has_components;
		bool has_contours;
		bool optimize;
		cpp_glif() {};
		cpp_glif(
			std::string &name,
			std::string &path,
			std::vector<std::string> &unicodes,
			int mark,
			double width,
			size_t index,
			bool omit,
			bool base,
			bool has_anchors,
			bool has_components,
			bool has_contours,
			bool optimize
			) {
			this->name = name;
			this->path = path;
			this->unicodes = unicodes;
			this->mark = mark;
			this->width = width;
			this->index = index;
			this->omit = omit;
			this->base = base;
			this->has_anchors = has_anchors;
			this->has_components = has_components;
			this->has_contours = has_contours;
			this->optimize = optimize;
			}
	};

std::string contours_repr(auto &contours) {
	std::stringstream contours_stream;
	for (auto &contour : contours)
		contours_stream << contour_repr(contour);
	return contours_stream.str();
	}

std::string contour_repr(auto &contour) {
	return "\t\t<contour>\n" + items_repr(contour) + "\t\t</contour>\n";
	}

std::string unicode_repr(auto &code_point) {
	return "\t<unicode hex=\"" + code_point + "\"/>\n";
	}

const cpp_point NO_SCALE = cpp_point(0.0, 0.0);
const cpp_point NO_OFFSET = cpp_point(0.0, 0.0);

typedef std::vector<cpp_anchor> cpp_anchors;
typedef std::vector<cpp_component> cpp_components;
typedef std::vector<cpp_glif> cpp_glifs;
typedef std::unordered_map<size_t, cpp_anchors> cpp_anchor_lib;
typedef std::unordered_map<size_t, cpp_components> cpp_component_lib;
typedef std::unordered_map<size_t, cpp_contours> cpp_contour_lib;

void add_contours(cpp_contour_lib &contour_lib, cpp_component &component, std::stringstream &text_stream) {

	cpp_contours contours(contour_lib[component.index]);
	if (component.offset != NO_OFFSET and component.scale != NO_SCALE) {
		for (auto &contour : contours)
			for (auto &point : contour)
				point.scale_offset(component.scale, component.offset);
		}
	else if (component.offset != NO_OFFSET) {
		for (auto &contour : contours)
			for (auto &point : contour)
				point.offset(component.offset);
		}
	else if (component.scale != NO_SCALE) {
		for (auto &contour : contours)
			for (auto &point : contour)
				point.scale(component.scale);
		}
	text_stream << contours_repr(contours);
	}

std::string build_glif(auto &glif, auto &anchor_lib, auto &component_lib, auto &contour_lib, bool ufoz) {
	std::stringstream text_stream;
	text_stream << XML_PROLOG <<
		"<glyph name=\"" << glif.name << "\" format=\"2\">\n" <<
		"\t<advance width=\"" << number_str(glif.width) << "\"/>\n";
	if (!glif.unicodes.empty()) {
		for (auto &code_point : glif.unicodes)
			text_stream << unicode_repr(code_point);
		}
	if (glif.has_anchors) {
		cpp_anchors anchors(anchor_lib[glif.index]);
		text_stream << items_repr(anchors);
		}
	if (glif.has_components or glif.has_contours) {
		text_stream << "\t<outline>\n";
		}
	if (glif.has_components and !glif.optimize) {
		cpp_components components(component_lib[glif.index]);
		text_stream << items_repr(components);
		}
	if (glif.optimize and glif.has_components) {
		cpp_components components(component_lib[glif.index]);
		for (auto &component : components) {
			add_contours(contour_lib, component, text_stream);
			}
		}
	if (glif.has_contours) {
		cpp_contours contours(contour_lib[glif.index]);
		text_stream << contours_repr(contours);
		}
	if (glif.has_components or glif.has_contours) {
		text_stream << "\t</outline>\n";
		}
	if (glif.mark > 0 and glif.mark < 256) {
		if (glif.mark == 255) {
			glif.mark = 254;
			}
		text_stream <<
			"\t<lib>\n"
			"\t\t<dict>\n"
			"\t\t\t<key>public.markColor</key>\n"
			"\t\t\t<string>" + MARK_COLORS[glif.mark] + "</string>\n"
			"\t\t</dict>\n"
			"\t</lib>\n";
		}
	text_stream << "</glyph>\n";
	const std::string text = text_stream.str();
	if (!ufoz) {
		write_file(glif.path.c_str(), text.c_str(), text.size());
		}
	return text;
	}

void write_glif_files(auto &glifs, auto &anchor_lib, auto &component_lib, auto &contour_lib, bool ufoz) {
	std::fesetround(FE_TONEAREST);
	#pragma omp parallel for schedule(dynamic) num_threads(std::thread::hardware_concurrency())
	for (auto &glif : glifs)
		if (!glif.omit) build_glif(glif, anchor_lib, component_lib, contour_lib, ufoz);
	}
