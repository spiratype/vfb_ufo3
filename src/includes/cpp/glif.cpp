// glif.cpp

#define FMT_HEADER_ONLY
#include <fmt/format.h>

#include <cmath>
#include <cstdint>
#include <cstring>
#include <fstream>
#include <sstream>
#include <string>
#include <unordered_map>
#include <vector>
#include <omp.h>

#include "glif.hpp"
#include "string.cpp"
#include "mark.cpp"
#include "sha512/SHA512.cpp"

void cpp_ufo::reserve(size_t n, size_t n_code_points, size_t n_anchors, size_t n_components, size_t n_contours) {
	this->glifs.reserve(n);
	this->code_points.reserve(n_code_points);
	this->anchors.reserve(n_anchors);
	this->components.reserve(n_components);
	this->contours.reserve(n_contours);
	this->completed_contours.reserve(n);
	}

void cpp_ufo::hints_reserve(size_t n_vhints, size_t n_hhints, size_t n_hint_replacements) {
	this->vhints.reserve(n_vhints);
	this->hhints.reserve(n_hhints);
	this->hint_replacements.reserve(n_hint_replacements);
	}

void write_file(const std::string &path, const std::string &text) {
	std::ofstream fs(path);
	fs.write(text.c_str(), text.size());
	fs.close();
	}

std::string items_repr(const auto &items, int avg_len=80) {
	std::string repr;
	repr.reserve(items.size() * avg_len);
	for (const auto &item : items)
		repr += item.repr();
	return repr;
	}

struct cpp_point {
	float x;
	float y;
	cpp_point() {}
	cpp_point(float x, float y) {
		this->x = x;
		this->y = y;
		}
	void scale(const float scale) {
		this->x *= scale;
		this->y *= scale;
		}
	void scale(const cpp_point &scale) {
		this->x *= scale.x;
		this->y *= scale.y;
		}
	void offset(const cpp_point &offset) {
		this->x += offset.x;
		this->y += offset.y;
		}
	void scale_offset(const cpp_point &scale, const cpp_point &offset) {
		this->scale(scale);
		this->offset(offset);
		}
	inline bool operator ==(const cpp_point &other) const {
		return (this->x == other.x and this->y == other.y);
		}
	inline bool operator !=(const cpp_point &other) const {
		return (this->x != other.x or this->y != other.y);
		}
	};

struct cpp_anchor : public cpp_point {
	std::string name;
	cpp_anchor() {}
	cpp_anchor(const std::string &name, float x, float y) {
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

struct cpp_contour_point : public cpp_point {
	std::string name;
	int type;
	int alignment;
	cpp_contour_point() {}
	cpp_contour_point(float x, float y) {
		this->x = x;
		this->y = y;
		this->type = 0;
		this->alignment = 0;
		}
	cpp_contour_point(float x, float y, int type, int alignment=0) {
		this->x = x;
		this->y = y;
		this->type = type;
		this->alignment = alignment;
		}
	cpp_contour_point(float x, float y, int type, const std::string &name) {
		this->x = x;
		this->y = y;
		this->type = type;
		this->alignment = 0;
		this->name = name;
		}
	cpp_contour_point(float x, float y, int type, int alignment, const std::string &name) {
		this->x = x;
		this->y = y;
		this->type = type;
		this->alignment = alignment;
		this->name = name;
		}
	std::vector<std::string> attrs() const {
		if (!this->type)
			return {
				attr("x", number_str(this->x)),
				attr("y", number_str(this->y)),
				};
		if (!this->name.empty()) {
			if (this->alignment > 0)
				return {
					attr("x", number_str(this->x)),
					attr("y", number_str(this->y)),
					attr("type", POINT_TYPES[this->type]),
					attr("smooth", "yes"),
					attr("name", this->name),
					};
			return {
				attr("x", number_str(this->x)),
				attr("y", number_str(this->y)),
				attr("type", POINT_TYPES[this->type]),
				attr("name", this->name),
				};
			}
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

struct cpp_component {
	std::string base;
	cpp_point offset;
	cpp_point scale;
	size_t index;
	cpp_component() {}
	cpp_component(
		const std::string &base,
		size_t index,
		float offset_x,
		float offset_y,
		float scale_x,
		float scale_y
		) {
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

struct cpp_hint {
	float width;
	float position;
	bool vertical;
	cpp_hint() {}
	cpp_hint(float width, float position, bool vertical) {
		this->width = width;
		this->position = position;
		this->vertical = vertical;
		}
	void scale(float scale) {
		this->width *= scale;
		this->position *= scale;
		}
	std::vector<std::string> attrs() const {
		return {
			attr("pos", number_str(this->position)),
			attr("width", number_str(this->width)),
			};
		}
	std::string repr() const {
		return fmt::format("\t\t\t\t\t\t\t<string>{} {} {}</string>\n",
			this->vertical ? "vstem" : "hstem",
			number_str(this->width),
			number_str(this->position)
			);
		}
	std::string repr2() const {
		return fmt::format("\t\t\t\t\t<{} {}/>\n",
			this->vertical ? "vstem" : "hstem", attrs_str(this->attrs()));
		}
	};

struct cpp_hint_replacement {
	int type;
	size_t index;
	cpp_hint_replacement() {}
	cpp_hint_replacement(int type, size_t index) {
		this->type = type;
		this->index = index;
		}
	};

struct cpp_glif {
	std::string name;
	std::string path;
	cpp_code_points* code_points;
	cpp_anchors* anchors;
	cpp_components* components;
	cpp_contours* contours;
	cpp_hints* vhints;
	cpp_hints* hhints;
	cpp_hint_replacements* hint_replacements;
	int mark;
	float width;
	size_t index;
	size_t len_code_points;
	size_t len_anchors;
	size_t len_components;
	size_t len_points;
	size_t len_vhints;
	size_t len_hhints;
	size_t len_hint_replacements;
	bool omit;
	bool base;
	cpp_glif() {}
	cpp_glif(
		const std::string &name,
		const std::string &path,
		cpp_code_points* code_points,
		cpp_anchors* anchors,
		cpp_components* components,
		cpp_contours* contours,
		cpp_hints* vhints,
		cpp_hints* hhints,
		cpp_hint_replacements* hint_replacements,
		int mark,
		float width,
		size_t index,
		size_t len_code_points,
		size_t len_anchors,
		size_t len_components,
		size_t len_points,
		size_t len_vhints,
		size_t len_hhints,
		size_t len_hint_replacements,
		bool omit,
		bool base
		) {
		this->name = name;
		this->path = path;
		this->code_points = code_points;
		this->anchors = anchors;
		this->components = components;
		this->contours = contours;
		this->vhints = vhints;
		this->hhints = hhints;
		this->hint_replacements = hint_replacements;
		this->mark = mark < 255 ? mark : 255;
		this->width = width > 0 ? width : 0;
		this->index = index;
		this->len_code_points = len_code_points;
		this->len_anchors = len_anchors;
		this->len_components = len_components;
		this->len_points = len_points;
		this->len_vhints = len_vhints;
		this->len_hhints = len_hhints;
		this->len_hint_replacements = len_hint_replacements;
		this->omit = omit;
		this->base = base;
		}
	void scale(float scale) {
		if (this->len_anchors)
			for (auto &anchor : *this->anchors)
				anchor.scale(scale);
		if (this->len_components)
			for (auto &component : *this->components)
				component.offset.scale(scale);
		if (this->len_points)
			for (auto &contour : *this->contours)
				for (auto &point : contour)
					point.scale(scale);
		if (this->len_vhints)
			for (auto &hint : *this->vhints)
				hint.scale(scale);
		if (this->len_hhints)
			for (auto &hint : *this->hhints)
				hint.scale(scale);
		}
	size_t len() const {
		return this->len_code_points +
			this->len_anchors +
			this->len_components +
			this->len_points +
			this->len_vhints +
			this->len_hhints +
			this->len_hint_replacements;
		}
	std::string hint_id() const {
		std::string id;
		id.reserve((this->len_points * 10) + 20);
		id += fmt::format("w'{}", number_str(this->width));
		for (const auto &contour : *this->contours) {
			if (contour.size() < 2)
				continue;
			for (const auto &point : contour)
				id += fmt::format("{}{},{}", POINT_TYPES[point.type][0], number_str(point.x), number_str(point.y));
			}
		if (id.size() > 128)
			return sha512::hash(id);
		return id;
		}
	std::string hints_repr(auto hint_type) const;
	std::string hints_ufo3_repr(std::string &hints_repr, std::string &hintsets_str) const;
	std::string hints_adobe_v1_repr(std::string &hints_repr, std::string &hintsets_str) const;
	std::string hints_adobe_v2_repr(std::string &hints_repr, std::string &hintsets_str) const;
	void build_contours(auto &ufo) const;
	std::string build(auto &ufo, bool optimize, bool ufoz=false) const;
	};

std::string contour_repr(const auto &contour) {
	return fmt::format("\t\t<contour>\n{}\t\t</contour>\n", items_repr(contour));
	}

size_t contours_len(const auto &contours) {
	size_t i = 0;
	for (const auto &contour : contours)
		i += contour.size();
	return i;
	}

std::string contours_repr(const auto &contours, size_t n_points) {
	std::string repr;
	repr.reserve(n_points * 80);
	for (const auto &contour : contours)
		repr += contour_repr(contour);
	return repr;
	}

std::string contours_repr(const auto &contours) {
	std::string repr;
	repr.reserve(contours_len(contours) * 80);
	for (const auto &contour : contours)
		repr += contour_repr(contour);
	return repr;
	}

std::string unicode_repr(long code_point) {
	if (code_point <= 0xffff)
		return fmt::format("\t<unicode hex=\"{:04X}\"/>\n", code_point);
	return fmt::format("\t<unicode hex=\"{:05X}\"/>\n", code_point);
	}

static const cpp_point NO_SCALE(0, 0);
static const cpp_point NO_OFFSET(0, 0);

std::string add_contours(auto &ufo, const auto &component) {

	std::string repr;
	cpp_contours contours;

	if (component.offset == NO_OFFSET and component.scale == NO_SCALE) {
		if (ufo.completed_contours.find(component.index) == ufo.completed_contours.end()) {
			contours = ufo.contours[component.index];
			repr = contours_repr(contours);
			ufo.completed_contours[component.index] = repr;
			}
		else
			repr = ufo.completed_contours[component.index];
		}
	else {
		contours = ufo.contours[component.index];
		if (component.offset != NO_OFFSET and component.scale != NO_SCALE)
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

		repr = contours_repr(contours);
		}

	return repr;
	}

std::string cpp_glif::hints_repr(auto hint_type) const {

	std::string hints_repr;
	std::string hintsets_str;
	size_t n = (len_hint_replacements ? len_hint_replacements : len_vhints + len_vhints) * 50;

	hintsets_str.reserve(n);
	hints_repr.reserve(n + 600);

	if (hint_type == 1)
		return this->hints_adobe_v1_repr(hints_repr, hintsets_str);
	if (hint_type == 2)
		return this->hints_adobe_v2_repr(hints_repr, hintsets_str);
	return this->hints_ufo3_repr(hints_repr, hintsets_str);
	}

void hintsets_repr(std::string &repr, auto &hint_replacements, auto &vhints, auto &hhints) {
	for (const auto &replacement : hint_replacements) {
		if (replacement.type == 255) {
			if (!repr.empty())
				repr += "\t\t\t\t\t\t</array>\n";
			repr += fmt::format("\t\t\t\t\t\t<key>pointTag</key>\n"
				"\t\t\t\t\t\t<string>hintSet{:04}</string>\n"
				"\t\t\t\t\t\t<key>stems</key>\n"
				"\t\t\t\t\t\t<array>\n", replacement.index);
			}
		else if (replacement.type == 1)
			repr += hhints[replacement.index].repr();
		else
			repr += vhints[replacement.index].repr();
		}
	}

std::string cpp_glif::hints_ufo3_repr(std::string &hints_repr, std::string &hintsets_str) const {

	cpp_hints vhints;
	cpp_hints hhints;
	if (this->vhints != NULL)
		vhints = *this->vhints;
	if (this->hhints != NULL)
		hhints = *this->hhints;

	hints_repr += fmt::format("\t\t\t<key>public.postscript.hints</key>\n"
		"\t\t\t<dict>\n"
		"\t\t\t\t<key>formatVersion</key>\n"
		"\t\t\t\t<string>1</string>\n"
		"\t\t\t\t<key>id</key>\n"
		"\t\t\t\t<string>{}</string>\n"
		"\t\t\t\t<key>hintSetList</key>\n"
		"\t\t\t\t<array>\n"
		"\t\t\t\t\t<dict>\n"
		"\t\t\t\t\t\t<key>pointTag</key>\n"
		"\t\t\t\t\t\t<string>hintSet0000</string>\n"
		"\t\t\t\t\t\t<key>stems</key>\n"
		"\t\t\t\t\t\t<array>\n", this->hint_id());

	if (this->hint_replacements == NULL) {
		if (this->len_hhints)
			hintsets_str += items_repr(hhints);
		if (this->len_vhints)
			hintsets_str += items_repr(vhints);
		}
	else
		hintsets_repr(hintsets_str, *this->hint_replacements, vhints, hhints);

	hints_repr += hintsets_str;
	hints_repr += "\t\t\t\t\t\t</array>\n"
		"\t\t\t\t\t</dict>\n"
		"\t\t\t\t</array>\n"
		"\t\t\t</dict>\n";
	return hints_repr;
	}

std::string cpp_glif::hints_adobe_v1_repr(std::string &hints_repr, std::string &hintsets_str) const {

	cpp_hints vhints;
	cpp_hints hhints;
	if (this->vhints != NULL)
		vhints = *this->vhints;
	if (this->hhints != NULL)
		hhints = *this->hhints;

	hints_repr += "\t\t\t<key>com.adobe.type.autohint</key>\n"
		"\t\t\t<data>\n"
		"\t\t\t<hintSetList>\n"
		"\t\t\t\t<hintset pointTag=\"hintSet0000\">\n";

	if (this->hint_replacements == NULL) {
		if (this->len_hhints)
			for (const auto &hint : hhints)
				hintsets_str += hint.repr2();
		if (this->len_vhints)
			for (const auto &hint : vhints)
				hintsets_str += hint.repr2();
		}
	else {
		for (const auto &replacement : *this->hint_replacements) {
			if (replacement.type == 255) {
				if (!hintsets_str.empty())
					hintsets_str += "\t\t\t\t</hintset>\n";
				hintsets_str += fmt::format("\t\t\t\t<hintset pointTag=\"hintSet{:04}\">\n",
					replacement.index);
				}
			else if (replacement.type == 1)
				hintsets_str += hhints[replacement.index].repr2();
			else
				hintsets_str += vhints[replacement.index].repr2();
			}
		}

	hints_repr += hintsets_str;
	hints_repr += "\t\t\t\t</hintset>\n"
		"\t\t\t</hintSetList>\n"
		"\t\t\t</data>\n";
	return hints_repr;
	}

std::string cpp_glif::hints_adobe_v2_repr(std::string &hints_repr, std::string &hintsets_str) const {

	cpp_hints vhints;
	cpp_hints hhints;
	if (this->vhints != NULL)
		vhints = *this->vhints;
	if (this->hhints != NULL)
		hhints = *this->hhints;

	hints_repr += "\t\t\t<key>com.adobe.type.autohint.v2</key>\n"
		"\t\t\t<dict>\n"
		"\t\t\t\t<key>hintSetList</key>\n"
		"\t\t\t\t<array>\n"
		"\t\t\t\t\t<dict>\n"
		"\t\t\t\t\t\t<key>pointTag</key>\n"
		"\t\t\t\t\t\t<string>hintSet0000</string>\n"
		"\t\t\t\t\t\t<key>stems</key>\n"
		"\t\t\t\t\t\t<array>\n";

	if (this->hint_replacements == NULL) {
		if (this->len_hhints)
			hintsets_str += items_repr(hhints);
		if (this->len_vhints)
			hintsets_str += items_repr(vhints);
		}
	else
		hintsets_repr(hintsets_str, *this->hint_replacements, vhints, hhints);

	hints_repr += hintsets_str;
	hints_repr += "\t\t\t\t\t\t</array>\n"
		"\t\t\t\t\t</dict>\n"
		"\t\t\t\t</array>\n"
		"\t\t\t</dict>\n";
	return hints_repr;
	}

void cpp_glif::build_contours(auto &ufo) const {
	ufo.completed_contours[this->index] = contours_repr(*this->contours);
	}

std::string cpp_glif::build(auto &ufo, bool optimize, bool ufoz) const {

	std::string text;
	text.reserve(this->len() * 120);

	text += fmt::format(
		"<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n"
		"<glyph name=\"{}\" format=\"2\">\n"
		"\t<advance width=\"{}\"/>\n",
		this->name, number_str(this->width));

	if (this->len_code_points)
		for (const auto &code_point : *this->code_points)
			text += unicode_repr(code_point);

	if (this->len_anchors)
		text += items_repr(*this->anchors);

	if (this->len_components or this->len_points)
		text += "\t<outline>\n";

	if (this->len_components) {
		if (optimize)
			for (const auto &component : *this->components)
				text += add_contours(ufo, component);
		else
			text += items_repr(*this->components);
		}

	if (this->len_points)
		text += contours_repr(*this->contours, this->len_points);

	if (this->len_components or this->len_points)
		text += "\t</outline>\n";

	if (this->mark > 0 or this->len_vhints or this->len_vhints)
		text += "\t<lib>\n\t\t<dict>\n";

	if (this->mark > 0)
		text += fmt::format("\t\t\t<key>public.markColor</key>\n"
			"\t\t\t<string>{}</string>\n", MARK_COLORS[this->mark]);

	if (this->len_vhints or this->len_hhints)
		text += this->hints_repr(ufo.hint_type);

	if (this->mark > 0 or this->len_vhints or this->len_vhints)
		text += "\t\t</dict>\n\t</lib>\n";

	text += "</glyph>\n";
	text.shrink_to_fit();

	if (!ufoz)
		write_file(this->path, text);

	return text;
	}

void write_glifs(auto &ufo, bool optimize) {
	#pragma omp parallel for
	for (const auto &glif : ufo.glifs)
		if (!glif.omit)
			glif.build(ufo, optimize, false);
	}
