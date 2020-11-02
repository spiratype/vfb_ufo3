// file.cpp

#pragma once

#include <omp.h>

#include "file.cpp"

void write_files(const auto &files) {
  #pragma omp parallel for default(shared)
  for (const auto &file : files)
    write_file(file.path, file.data);
  }
