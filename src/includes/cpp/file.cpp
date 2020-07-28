// file.cpp

#include <fstream>
#include <string>
#include <vector>

class cpp_file;
typedef std::vector<cpp_file> cpp_files;

class cpp_file {
	public:
	std::string path;
	std::string data;
	cpp_file(const std::string &path, const std::string &data) {
		this->path = path;
		this->data = data;
		}
	};

void add_file(cpp_files &files, const std::string &path, const std::string &data) {
	files.emplace_back(path, data);
	}

void write_file(const auto &file) {
	std::ofstream f(file.path);
	f << file.data;
	f.close();
	}
