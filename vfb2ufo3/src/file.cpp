// file.cpp

#pragma once

#include <fstream>
#include <sstream>
#include <string>
#include <vector>

struct cpp_file {
  std::string path;
  std::string data;
  cpp_file(const std::string &path, const std::string &data) {
    this->path = path;
    this->data = data;
    }
  };

void write_file(const std::string &path, const std::string &data) {
  std::ofstream file(path);
  file << data;
  file.close();
  }

std::string read_file(const std::string &path) {
  std::ifstream file(path);
  std::stringstream data;
  data << file.rdbuf();
  file.close();
  return data.str();
  }

