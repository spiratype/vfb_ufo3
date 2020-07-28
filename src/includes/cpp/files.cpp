// file.cpp

#include <fstream>
#include <string>
#include <vector>

#include <omp.h>

#include "file.cpp"

void write_files(const auto &files) {
	#pragma omp parallel for default(shared)
	for (const auto &file : files)
		write_file(file);
	}

