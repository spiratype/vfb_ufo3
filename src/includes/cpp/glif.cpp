// glif.cpp

#define FMT_HEADER_ONLY
#include <fmt/format.h>

#include <cmath>
#include <fstream>
#include <string>
#include <unordered_map>
#include <vector>
#include <omp.h>

#include "string.cpp"
#include "mark.cpp"

static const std::vector<std::string> POINT_TYPES = {
	"",
	"curve",
	"qcurve",
	"line",
	"off"
	};

class cpp_point;
class cpp_anchor;
class cpp_contour_point;
class cpp_component;
class cpp_glif;

typedef std::vector<cpp_anchor> cpp_anchors;
typedef std::vector<cpp_component> cpp_components;
typedef std::vector<cpp_contour_point> cpp_contour;
typedef std::vector<cpp_contour> cpp_contours;

void write_file(const std::string &path, const std::string &text) {
	std::ofstream f(path);
	f << text;
	f.close();
	}

std::string items_repr(const auto &items, const int avg_len=80) {
	std::string repr;
	repr.reserve(items.size() * avg_len);
	for (const auto &item : items)
		repr += item.repr();
	return repr;
	}

class cpp_point {
	public:
	float x;
	float y;
	cpp_point() {}
	cpp_point(float x, float y) {
		this->x = x;
		this->y = y;
		}
	bool operator==(const cpp_point other) const {
		return (this->x == other.x and this->y == other.y);
		}
	bool operator!=(const cpp_point other) const {
		return (this->x != other.x or this->y != other.y);
		}
	};

class cpp_anchor {
	private:
	std::string name;
	float x;
	float y;
	public:
	cpp_anchor() {}
	cpp_anchor(std::string name, float x, float y) {
		this->name = name;
		this->x = x;
		this->y = y;
		}
	std::vector<std::string> attrs() const {
		return {
			attr("name", this->name),
			attr("x", number_str(this->x)),
			attr("y", number_str(this->y)),
			};
		}
	std::string repr() const {
		return fmt::format("\t<anchor {}/>\n", attrs_str(this->attrs()));
		}
	};

class cpp_contour_point {
	private:
	float x;
	float y;
	int type;
	int alignment;
	public:
	cpp_contour_point() {}
	cpp_contour_point(float x, float y, int type, int alignment) {
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
		this->scale(scale);
		this->offset(offset);
		}
	std::vector<std::string> attrs() const {
		if (this->type == 4)
			return {
				attr("x", number_str(this->x)),
				attr("y", number_str(this->y)),
				};
		if (this->alignment > 0)
			return {
				attr("x", number_str(this->x)),
				attr("y", number_str(this->y)),
				attr("type", POINT_TYPES[this->type]),
				attr("smooth", "yes"),
				};
		return {
				attr("x", number_str(this->x)),
				attr("y", number_str(this->y)),
				attr("type", POINT_TYPES[this->type]),
				};
		}
	std::string repr() const {
		return fmt::format("\t\t\t<point {}/>\n", attrs_str(this->attrs()));
		}
	};

class cpp_component {
	private:
	std::string base;
	public:
	size_t index;
	cpp_point offset;
	cpp_point scale;
	cpp_component() {}
	cpp_component(std::string base, size_t index, float offset_x, float offset_y, float scale_x, float scale_y) {
		this->base = base;
		this->index = index;
		this->offset = cpp_point(offset_x, offset_y);
		this->scale = cpp_point(scale_x, scale_y);
		}
	std::vector<std::string> attrs() const {
		return {
			attr("base", this->base),
			attr("xOffset", number_str(this->offset.x)),
			attr("yOffset", number_str(this->offset.y)),
			attr("xScale", float_str(this->scale.x, 2)),
			attr("yScale", float_str(this->scale.y, 2)),
			};
		}
	std::string repr() const {
		return fmt::format("\t\t<component {}/>\n", attrs_str(this->attrs()));
		}
	};

class cpp_glif {
	public:
	std::string name;
	std::string path;
	std::vector<long> code_points;
	int mark;
	float width;
	size_t index;
	size_t points_count;
	size_t anchors_count;
	size_t components_count;
	bool optimize;
	bool omit;
	bool base;
	cpp_glif() {}
	cpp_glif(
		std::string &name,
		std::string &path,
		std::vector<long> &code_points,
		int mark,
		float width,
		size_t index,
		size_t points_count,
		size_t anchors_count,
		size_t components_count,
		bool optimize,
		bool omit,
		bool base
		) {
		this->name = name;
		this->path = path;
		this->code_points = code_points;
		if (mark >= 255)
			mark = 254;
		this->mark = mark;
		this->width = width;
		this->index = index;
		this->points_count = points_count;
		this->anchors_count = anchors_count;
		this->components_count = components_count;
		this->optimize = optimize;
		this->omit = omit;
		this->base = base;
		}
	size_t len() const {
		return (this->code_points.size() + this->anchors_count + this->components_count + this->points_count);
		}
	};

std::string contour_repr(const auto &contour) {
	return fmt::format("\t\t<contour>\n{}\t\t</contour>\n", items_repr(contour));
	}

std::string contours_repr(const auto &contours) {
	std::string repr;
	int i = 0;
	for (const auto &contour : contours)
		i += contour.size();
	repr.reserve(i * 80);
	for (const auto &contour : contours)
		repr += contour_repr(contour);
	return repr;
	}

std::string unicode_repr(const long &code_point) {
	if (code_point <= 0xffff)
		return fmt::format("\t<unicode hex=\"{:04X}\"/>\n", code_point);
	return fmt::format("\t<unicode hex=\"{:05X}\"/>\n", code_point);
	}

static const cpp_point NO_SCALE = cpp_point(0.0, 0.0);
static const cpp_point NO_OFFSET = cpp_point(0.0, 0.0);

typedef std::vector<cpp_glif> cpp_glifs;
typedef std::unordered_map<size_t, cpp_anchors> cpp_anchor_lib;
typedef std::unordered_map<size_t, cpp_components> cpp_component_lib;
typedef std::unordered_map<size_t, cpp_contours> cpp_contour_lib;
typedef std::unordered_map<size_t, std::string> cpp_completed_contour_lib;

std::string add_contours(auto &contour_lib, auto &completed_contour_lib, auto &component) {

	std::string repr;
	cpp_contours contours(contour_lib[component.index]);

	if (component.offset == NO_OFFSET and component.scale == NO_SCALE) {
		if (completed_contour_lib.find(component.index) == completed_contour_lib.end()) {
			repr = contours_repr(contours);
			completed_contour_lib[component.index] = repr;
			}
		else
			repr = completed_contour_lib[component.index];
		}
	else if (component.offset != NO_OFFSET and component.scale != NO_SCALE)
		for (auto &contour : contours)
			for (auto &point : contour)
				point.scale_offset(component.scale, component.offset);
	else if (component.offset != NO_OFFSET)
		for (auto &contour : contours)
			for (auto &point : contour)
				point.offset(component.offset);
	else
		for (auto &contour : contours)
			for (auto &point : contour)
				point.scale(component.scale);

	if (repr.empty())
		repr = contours_repr(contours);

	return repr;
	}

std::string build_glif(const auto &glif, auto &anchor_lib, auto &component_lib, auto &contour_lib, auto &completed_contour_lib, bool ufoz=false) {

	std::string text;
	std::string mark;
	text.reserve(glif.len() * 120);

	text += fmt::format(
		"<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n"
		"<glyph name=\"{}\" format=\"2\">\n"
		"\t<advance width=\"{}\"/>\n",
		glif.name, number_str(glif.width));

	if (!glif.code_points.empty())
		for (const auto &code_point : glif.code_points)
			text += unicode_repr(code_point);

	if (glif.anchors_count)
		text += items_repr(anchor_lib[glif.index]);

	if (glif.components_count or glif.points_count)
		text += "\t<outline>\n";

	if (glif.components_count) {
		if (!glif.optimize)
			text += items_repr(component_lib[glif.index]);
		else
			for (auto &component : component_lib[glif.index])
				text += add_contours(contour_lib, completed_contour_lib, component);
		}

	if (glif.points_count)
		text += contours_repr(contour_lib[glif.index]);

	if (glif.components_count or glif.points_count)
		text += "\t</outline>\n";

	if (glif.mark > 0)
		mark = MARK_COLORS[glif.mark];

	if (!mark.empty())
		text += fmt::format(
			"\t<lib>\n"
			"\t\t<dict>\n"
			"\t\t\t<key>public.markColor</key>\n"
			"\t\t\t<string>{}</string>\n"
			"\t\t</dict>\n"
			"\t</lib>\n",
			mark);

	text += "</glyph>\n";
	text.shrink_to_fit();

	if (!ufoz)
		write_file(glif.path, text);

	return text;
	}

void add_anchor(auto &anchors, auto &name, float x, float y) {
	anchors.emplace_back(name, x, y);
	}

void add_component(auto &components, auto &base, size_t index, float offset_x, float offset_y, float scale_x, float scale_y) {
	components.emplace_back(base, index, offset_x, offset_y, scale_x, scale_y);
	}

void add_contour_point(auto &contour, float x, float y, int type, int alignment=0) {
	contour.emplace_back(x, y, type, alignment);
	}

void add_glif(auto &glifs, auto &name, auto &path, auto &code_points, int mark, float width, size_t index, size_t points_count, size_t anchors_count, size_t components_count, bool optimize, bool omit, bool base) {
	glifs.emplace_back(name, path, code_points, mark, width, index, points_count, anchors_count, components_count, optimize, omit, base);
	}

void write_glif_files(const auto &glifs, auto &anchor_lib, auto &component_lib, auto &contour_lib, auto &completed_contour_lib) {
	#pragma omp parallel for default(shared)
	for (const auto &glif : glifs)
		if (!glif.omit)
			build_glif(glif, anchor_lib, component_lib, contour_lib, completed_contour_lib);
	}
