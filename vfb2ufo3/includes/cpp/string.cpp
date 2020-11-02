// string.cpp

#pragma once

static inline std::string float_str(float n, int precision=1) {
  return fmt::format(FMT_COMPILE("{:.{}f}"), n, precision);
  }

static std::string number_str(double n) {
  double k = std::nearbyint(n);
  if (std::fabs(n - k) < 0.05)
    return fmt::to_string((int) k);
  return float_str(n);
  }

static inline std::string attr(const std::string &name, const std::string &value) {
  return fmt::format(FMT_COMPILE("{}=\"{}\" "), name, value);
  }

std::string attrs_str(const std::vector<std::string> &attrs) {
  std::string out;
  out.reserve(140);
  for (const auto &str : attrs)
    out += str;
  out.pop_back();
  return out;
  }

std::string items_repr(const auto &items, int avg_len=80) {
  std::string repr;
  repr.reserve(items.size() * avg_len);
  for (const auto &item : items)
    repr += item.repr();
  return repr;
  }
