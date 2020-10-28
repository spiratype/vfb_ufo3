// path.cpp

#pragma once

#include <filesystem>

std::string os_path_normpath(const std::string &path) {
  return std::filesystem::path(path).make_preferred().string();
  }
