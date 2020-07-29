// zip.cpp

#include <cstring>
#include <ctime>
#include <fstream>
#include <string>
#include <vector>
#include <unordered_map>
#include <zlib.h>

#include "zip.hpp"
#include "zip_util.cpp"

class zip_file {
	public:
	u_short compression_method;
	u_short date;
	u_short time;
	std::string arc_path;
	std::ofstream archive;
	std::vector<zip_info> zinfo_list;
	zip_file() {}
	~zip_file() {
		this->close();
		}
	zip_file(const std::string &arc_path, bool compress=true) {
		this->compression_method = compress ? ZIP_DEFLATED : ZIP_STORED;
		std::time_t time = std::time(nullptr);
		std::tm* dt = std::localtime(&time);
		this->date = ((dt->tm_year - 80) << 9) + ((dt->tm_mon + 1) << 5) + dt->tm_mday;
		this->time = (dt->tm_hour << 11) + (dt->tm_min << 5) + ((int)(dt->tm_sec / 2));
		this->arc_path = arc_path;
		this->archive.open(this->arc_path, std::ios::binary);
		}
	void reserve(size_t n) {
		this->zinfo_list.reserve(n);
		}
	void close() {
		if (this->archive.is_open()) {
			this->finish();
			this->archive.close();
			}
		}
	void write_str(const std::string &arc_name, const std::string &data) {
		std::string compressed;
		size_t uncompressed_size = data.size();
		size_t compressed_size = data.size();
		u_long crc = crc32_z(0, (const u_char*)data.c_str(), data.size());
		u_long header_offset = this->tellp();

		if (this->compression_method) {
			compressed = zip_compress_str(data, this->compression_method);
			compressed_size = compressed.size();
			}

		zip_info zinfo = zip_info(arc_name, this->compression_method, this->time, this->date, uncompressed_size, compressed_size, crc, header_offset);
		this->write_local_file_header(zinfo);

		if (this->compression_method)
			this->write(compressed.data(), compressed.size());
		else
			this->write(data.data(), data.size());

		this->zinfo_list.push_back(zinfo);
		}
	private:
	void write(const char* data, size_t size) {
		this->archive.write(data, size);
		}
	u_int tellp() {
		return (u_int)this->archive.tellp();
		}
	void finish() {
		u_int central_dir_offset = this->tellp();
		this->write_central_directory_header();
		this->write_end_of_central_directory_record(central_dir_offset);
		}
	void write_local_file_header(zip_info &zinfo) {
		zip_local_file_header local_file_header = zip_local_file_header(zinfo);
		this->write((const char*)&local_file_header, ZIP_LFH_SIZE);
		this->write(zinfo.arc_name.c_str(), zinfo.arc_name.size());
		}
	void write_central_directory_header() {
		zip_central_directory_header central_directory_header = {};
		for (const auto &zinfo : this->zinfo_list) {
			central_directory_header = zip_central_directory_header(zinfo);
			this->write((const char*)&central_directory_header, ZIP_CDH_SIZE);
			this->write(zinfo.arc_name.c_str(), zinfo.arc_name.size());
			}
		}
	void write_end_of_central_directory_record(u_int central_dir_offset) {
		size_t num_entries = this->zinfo_list.size();
		u_int central_dir_size = this->tellp() - central_dir_offset;
		zip_end_of_central_directory end_of_central_directory = zip_end_of_central_directory(num_entries, central_dir_size, central_dir_offset);
		this->write((const char*)&end_of_central_directory, ZIP_ECDR_SIZE);
		}
	};

void write_archive(std::string &filename, std::unordered_map<std::string, std::string> &files, bool compress) {
	zip_file archive = zip_file(filename, compress);
	archive.reserve(files.size());
	for (const auto &[arc_name, file] : files)
		archive.write_str(arc_name, file);
	archive.close();
	}

int main() {}
