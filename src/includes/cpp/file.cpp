// file.cpp

#include <fstream>
#include <sstream>
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

void write_file(const std::string &path, const std::string &data) {
	std::ofstream f(path);
	f << data;
	f.close();
	}

std::string read_file(const std::string &path) {
	std::ifstream f(path, std::ios::binary);
	std::stringstream data;
	data << f.rdbuf();
	f.close();
	return data.str();
	}
