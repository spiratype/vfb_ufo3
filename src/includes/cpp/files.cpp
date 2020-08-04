// file.cpp

#include "file.cpp"

#include <omp.h>

void write_files(const auto &files) {
	#pragma omp parallel for default(shared)
	for (const auto &file : files)
		write_file(file.path, file.data);
	}
