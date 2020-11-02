// glif.cpp

#define FMT_HEADER_ONLY
#include <fmt/format.h>
#include <fmt/compile.h>

#include <cmath>
#include <cstddef>
#include <cstdint>
#include <cstring>
#include <ctime>
#include <fstream>
#include <string>
#include <unordered_map>
#include <vector>

#include <omp.h>
#include <zlib.h>

#include "glif.hpp"
#include "mark.hpp"
#include "string.cpp"
#include "sha512.cpp"
#include "archive.cpp"

struct cpp_point {
  float x = 0.0;
  float y = 0.0;
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
    return fmt::format(FMT_COMPILE("\t<anchor {}/>\n"), attrs_str(this->attrs()));
    }
  };

struct cpp_contour_point : public cpp_point {
  std::string name;
  int type = 0;
  int alignment = 0;
  cpp_contour_point() {}
  cpp_contour_point(float x, float y) {
    this->x = x;
    this->y = y;
    }
  cpp_contour_point(float x, float y, int type, int alignment=0) {
    this->x = x;
    this->y = y;
    this->type = type;
    this->alignment = alignment;
    }
  cpp_contour_point(float x, float y, int type, int alignment, std::string &name) {
    this->x = x;
    this->y = y;
    this->type = type;
    this->alignment = alignment;
    this->name = name;
    }
  cpp_contour_point(float x, float y, int type, int alignment, int hintset_index) {
    this->x = x;
    this->y = y;
    this->type = type;
    this->alignment = alignment;
    this->name = fmt::format(FMT_COMPILE("hintSet{:04}"), hintset_index);
    }
  std::vector<std::string> attrs() const {
    if (not this->type)
      return {
        attr("x", number_str(this->x)),
        attr("y", number_str(this->y)),
        };
    if (not this->name.empty()) {
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
    return fmt::format(FMT_COMPILE("\t\t\t<point {}/>\n"), attrs_str(this->attrs()));
    }
  };

struct cpp_component {
  std::string base;
  cpp_point offset;
  cpp_point scale;
  size_t index = 0;
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
    return fmt::format(FMT_COMPILE("\t\t<component {}/>\n"), attrs_str(this->attrs()));
    }
  };

struct cpp_hint {
  float width = 0.0;
  float position = 0.0;
  bool vertical = false;
  bool ghost = false;
  cpp_hint() {}
  cpp_hint(float width, float position, bool vertical, bool ghost) {
    this->width = width;
    this->position = position;
    this->vertical = vertical;
    this->ghost = ghost;
    }
  void scale(float scale) {
    this->position *= scale;
    if (not this->ghost)
      this->width *= scale;
    }
  std::vector<std::string> attrs() const {
    return {
      attr("pos", number_str(this->position)),
      attr("width", number_str(this->width)),
      };
    }
  std::string repr() const {
    return fmt::format(FMT_COMPILE("\t\t\t\t\t\t\t<string>{} {} {}</string>\n"),
      this->vertical ? "vstem" : "hstem",
      number_str(this->width),
      number_str(this->position)
      );
    }
  std::string repr2() const {
    return fmt::format(FMT_COMPILE("\t\t\t\t\t<{} {}/>\n"),
      this->vertical ? "vstem" : "hstem", attrs_str(this->attrs()));
    }
  };

struct cpp_hint_replacement {
  int type = 0;
  size_t index = 0;
  cpp_hint_replacement() {}
  cpp_hint_replacement(int type, size_t index) {
    this->type = type;
    this->index = index;
    }
  };

struct cpp_glif {
  std::string name;
  std::string path;
  std::vector<long> code_points;
  std::vector<cpp_anchor> anchors;
  std::vector<cpp_component> components;
  std::vector<cpp_hint> vhints;
  std::vector<cpp_hint> hhints;
  std::vector<cpp_hint_replacement> hint_replacements;
  cpp_contours contours;
  int mark;
  float width;
  size_t index;
  size_t len_points;
  bool omit;
  bool base;
  cpp_glif() {}
  cpp_glif(
      const std::string &name,
      const std::string &path,
      int mark,
      float width,
      size_t index,
      size_t len_points,
      bool omit,
      bool base
      ) {
    this->name = name;
    this->path = path;
    this->mark = mark;
    this->width = width;
    this->index = index;
    this->len_points = len_points;
    this->omit = omit;
    this->base = base;
    }
  void scale(float scale);
  size_t size() const;
  std::string repr(auto &ufo) const;
  std::string hint_id() const;
  std::string hints_repr(auto hint_type) const;
  std::string hints_public_repr(std::string &hints_repr, std::string &hintsets_str) const;
  std::string hints_adobe_v1_repr(std::string &hints_repr, std::string &hintsets_str) const;
  std::string hints_adobe_v2_repr(std::string &hints_repr, std::string &hintsets_str) const;
  void build_contours(auto &ufo) const;
  void write(auto &ufo) const;
  };

std::string contour_repr(const auto &contour) {
  return fmt::format(FMT_COMPILE("\t\t<contour>\n{}\t\t</contour>\n"), items_repr(contour));
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
    return fmt::format(FMT_COMPILE("\t<unicode hex=\"{:04X}\"/>\n"), code_point);
  return fmt::format(FMT_COMPILE("\t<unicode hex=\"{:05X}\"/>\n"), code_point);
  }

static const cpp_point NO_SCALE(0.0, 0.0);
static const cpp_point NO_OFFSET(0.0, 0.0);

std::string add_contours(auto &ufo, const auto &component) {

  std::string repr;
  cpp_contours contours;

  if (component.offset == NO_OFFSET and component.scale == NO_SCALE) {
    if (ufo.completed_contours.find(component.index) == ufo.completed_contours.end()) {
      contours = *ufo.contours[component.index];
      repr = contours_repr(contours);
      ufo.completed_contours[component.index] = repr;
      return repr;
      }
    return ufo.completed_contours[component.index];
    }

  contours = *ufo.contours[component.index];
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

  return contours_repr(contours);
  }

void cpp_glif::scale(float scale) {
  if (this->anchors.size())
    for (auto &anchor : this->anchors)
      anchor.scale(scale);
  if (this->components.size())
    for (auto &component : this->components)
      component.offset.scale(scale);
  if (this->contours.size())
    for (auto &contour : this->contours)
      for (auto &point : contour)
        point.scale(scale);
  if (this->vhints.size())
    for (auto &hint : this->vhints)
      hint.scale(scale);
  if (this->hhints.size())
    for (auto &hint : this->hhints)
      hint.scale(scale);
  }

size_t cpp_glif::size() const {
  return this->code_points.size() +
    this->anchors.size() +
    this->components.size() +
    this->len_points +
    this->vhints.size() +
    this->hhints.size() +
    this->hint_replacements.size();
  }

std::string cpp_glif::hint_id() const {
  std::string id;

  id.reserve((this->len_points * 10) + 20);
  id += fmt::format(FMT_COMPILE("w'{}"), number_str(this->width));
  for (const auto &contour : this->contours) {
    if (contour.size() < 2)
      continue;
    for (const auto &point : contour)
      id += fmt::format(FMT_COMPILE("{}{},{}"), POINT_TYPES[point.type][0], number_str(point.x), number_str(point.y));
    }
  if (id.size() > 128)
    return sha512::sha512_hash(id);
  return id;
  }

std::string cpp_glif::hints_repr(auto hint_type) const {

  std::string hints_repr;
  std::string hintsets_str;
  size_t n = (hint_replacements.size() ? hint_replacements.size() : vhints.size() + vhints.size()) * 50;

  hintsets_str.reserve(n);
  hints_repr.reserve(n + 600);

  if (hint_type == 1)
    return this->hints_adobe_v1_repr(hints_repr, hintsets_str);
  if (hint_type == 2)
    return this->hints_adobe_v2_repr(hints_repr, hintsets_str);
  return this->hints_public_repr(hints_repr, hintsets_str);
  }

void hintsets_repr(std::string &repr, const auto &hint_replacements, auto &vhints, auto &hhints) {
  for (const auto &hint_replacement : hint_replacements) {
    if (hint_replacement.type == 255) {
      if (not repr.empty())
        repr += "\t\t\t\t\t\t</array>\n";
      repr += fmt::format(FMT_COMPILE(
        "\t\t\t\t\t\t<key>pointTag</key>\n"
        "\t\t\t\t\t\t<string>hintSet{:04}</string>\n"
        "\t\t\t\t\t\t<key>stems</key>\n"
        "\t\t\t\t\t\t<array>\n"),
        hint_replacement.index);
      }
    else if (hint_replacement.type == 1)
      repr += hhints[hint_replacement.index].repr();
    else
      repr += vhints[hint_replacement.index].repr();
    }
  }

std::string cpp_glif::hints_public_repr(std::string &hints_repr, std::string &hintsets_str) const {

  hints_repr += fmt::format(FMT_COMPILE(
    "\t\t\t<key>public.postscript.hints</key>\n"
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
    "\t\t\t\t\t\t<array>\n"),
    this->hint_id());

  if (this->hint_replacements.empty()) {
    if (this->hhints.size())
      hintsets_str += items_repr(this->hhints);
    if (this->vhints.size())
      hintsets_str += items_repr(this->vhints);
    }
  else
    hintsets_repr(hintsets_str, this->hint_replacements, this->vhints, this->hhints);

  hints_repr += hintsets_str;
  hints_repr += "\t\t\t\t\t\t</array>\n"
    "\t\t\t\t\t</dict>\n"
    "\t\t\t\t</array>\n"
    "\t\t\t</dict>\n";
  return hints_repr;
  }

std::string cpp_glif::hints_adobe_v1_repr(std::string &hints_repr, std::string &hintsets_str) const {

  hints_repr += "\t\t\t<key>com.adobe.type.autohint</key>\n"
    "\t\t\t<data>\n"
    "\t\t\t<hintSetList>\n"
    "\t\t\t\t<hintset pointTag=\"hintSet0000\">\n";

  if (this->hint_replacements.empty()) {
    if (this->hhints.size())
      for (const auto &hint : this->hhints)
        hintsets_str += hint.repr2();
    if (this->vhints.size())
      for (const auto &hint : this->vhints)
        hintsets_str += hint.repr2();
    }
  else {
    for (const auto &hint_replacement : this->hint_replacements) {
      if (hint_replacement.type == 255) {
        if (not hintsets_str.empty())
          hintsets_str += "\t\t\t\t</hintset>\n";
        hintsets_str += fmt::format(FMT_COMPILE("\t\t\t\t<hintset pointTag=\"hintSet{:04}\">\n"),
          hint_replacement.index);
        }
      else if (hint_replacement.type == 1)
        hintsets_str += this->hhints[hint_replacement.index].repr2();
      else
        hintsets_str += this->vhints[hint_replacement.index].repr2();
      }
    }

  hints_repr += hintsets_str;
  hints_repr += "\t\t\t\t</hintset>\n"
    "\t\t\t</hintSetList>\n"
    "\t\t\t</data>\n";
  return hints_repr;
  }

std::string cpp_glif::hints_adobe_v2_repr(std::string &hints_repr, std::string &hintsets_str) const {

  hints_repr += "\t\t\t<key>com.adobe.type.autohint.v2</key>\n"
    "\t\t\t<dict>\n"
    "\t\t\t\t<key>hintSetList</key>\n"
    "\t\t\t\t<array>\n"
    "\t\t\t\t\t<dict>\n"
    "\t\t\t\t\t\t<key>pointTag</key>\n"
    "\t\t\t\t\t\t<string>hintSet0000</string>\n"
    "\t\t\t\t\t\t<key>stems</key>\n"
    "\t\t\t\t\t\t<array>\n";

  if (this->hint_replacements.empty()) {
    if (this->hhints.size())
      hintsets_str += items_repr(this->hhints);
    if (this->vhints.size())
      hintsets_str += items_repr(this->vhints);
    }
  else
    hintsets_repr(hintsets_str, this->hint_replacements, this->vhints, this->hhints);

  hints_repr += hintsets_str;
  hints_repr += "\t\t\t\t\t\t</array>\n"
    "\t\t\t\t\t</dict>\n"
    "\t\t\t\t</array>\n"
    "\t\t\t</dict>\n";
  return hints_repr;
  }

void cpp_glif::build_contours(auto &ufo) const {
  ufo.completed_contours[this->index] = contours_repr(this->contours);
  }

std::string cpp_glif::repr(auto &ufo) const {

  std::string text;
  bool has_components = this->components.size();
  bool has_contours = this->contours.size();
  bool has_mark = this->mark > 0;
  bool has_hints = this->vhints.size() or this->hhints.size();

  text.reserve(this->size() * 120);
  text += fmt::format(FMT_COMPILE(
    "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n"
    "<glyph name=\"{}\" format=\"2\">\n"
    "\t<advance width=\"{}\"/>\n"),
    this->name, number_str(this->width));

  if (this->code_points.size())
    for (const auto &code_point : this->code_points)
      text += unicode_repr(code_point);

  if (this->anchors.size())
    text += items_repr(this->anchors);

  if (has_components or has_contours)
    text += "\t<outline>\n";

  if (has_components and ufo.optimize)
    for (const auto &component : this->components)
      text += add_contours(ufo, component);
  else if (has_components)
    text += items_repr(this->components);

  if (has_contours)
    text += contours_repr(this->contours, this->len_points);

  if (has_components or has_contours)
    text += "\t</outline>\n";

  if (has_mark or has_hints)
    text += "\t<lib>\n\t\t<dict>\n";

  if (has_mark)
    text += fmt::format(FMT_COMPILE("\t\t\t<key>public.markColor</key>\n"
      "\t\t\t<string>{}</string>\n"), MARK_COLORS[this->mark]);

  if (has_hints)
    text += this->hints_repr(ufo.hint_type);

  if (has_mark or has_hints)
    text += "\t\t</dict>\n\t</lib>\n";

  text += "</glyph>\n";
  text.shrink_to_fit();

  return text;
  }

void cpp_glif::write(auto &ufo) const {
  std::ofstream file(this->path);
  file << this->repr(ufo);
  file.close();
  }

void write_glifs(auto &ufo) {
  #pragma omp parallel for
  for (const auto &glif : ufo.glifs)
    if (not glif.omit)
      glif.write(ufo);
  }

// int main() {}
