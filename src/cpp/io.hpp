// io.hpp

#include <cstdio>

void write_file(const char* path, const char* text, const size_t text_len) {
	std::FILE* f = std::fopen(path, "w");
	std::setbuf(f, NULL);
	std::fwrite(text, 1, text_len, f);
	std::fflush(f);
	std::fclose(f);
	}
