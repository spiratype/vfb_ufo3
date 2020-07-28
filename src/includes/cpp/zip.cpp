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
	u_int compression_method;
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
		this->compression_method = compress ? Z_DEFLATED : ZIP_STORED;
		std::time_t time = std::time(nullptr);
		std::tm* dt = std::localtime(&time);
		this->date = ((dt->tm_year - 80) << 9) + ((dt->tm_mon + 1) << 5) + dt->tm_mday;
		this->time = (dt->tm_hour << 11) + (dt->tm_min << 5) + ((int)(dt->tm_sec / 2));
		this->arc_path = arc_path;
		this->archive.open(this->arc_path, std::ios::binary);
		}
	void close() {
		if (this->archive.is_open()) {
			this->finish();
			this->archive.close();
			}
		}
	void write_str(const std::string &arc_name, const std::string &data) {
		std::string compressed;
		zip_info zinfo;
		size_t uncompressed_size = data.size();
		size_t compressed_size = data.size();
		u_long crc = crc32_z(0, (const u_char*)data.c_str(), data.size());
		u_long header_offset = this->tellp();

		if (this->compression_method) {
			compressed = zip_compress_str(data);
			compressed_size = compressed.size();
			}

		this->write_local_file_header(crc, compressed_size, uncompressed_size, arc_name.size());
		this->write(arc_name.c_str(), arc_name.size());

		if (this->compression_method)
			this->write(compressed.data(), compressed.size());
		else
			this->write(data.data(), data.size());

		this->zinfo_list.emplace_back(arc_name, uncompressed_size, compressed_size, crc, header_offset);
		}
	private:
	void write(const char* data, size_t size) {
		this->archive.write(data, size);
		}
	uint64_t tellp() {
		return (uint64_t)this->archive.tellp();
		}
	void finish() {
		uint64_t central_dir_offset = this->tellp();
		this->write_central_directory_header();
		this->write_end_of_central_directory_record(central_dir_offset);
		}
	void write_local_file_header(u_long crc, size_t compressed_size, size_t uncompressed_size, size_t arc_name_size) {
		zip_header header = {};
		ZIP_LE32(header,  ZIP_LFH_SIGNATURE);                                       // 4 local file header signature (0x04034b50)
		ZIP_LE16(header + ZIP_LFH_VERSION_NEEDED, 20);                              // 2 version needed to extract (minimum)
		ZIP_LE16(header + ZIP_LFH_BIT_FLAG, 0);                                     // 2 general purpose bit flag
		ZIP_LE16(header + ZIP_LFH_METHOD, this->compression_method);                // 2 compression method
		ZIP_LE16(header + ZIP_LFH_FILE_TIME, this->time);                           // 2 last mod file time
		ZIP_LE16(header + ZIP_LFH_FILE_DATE, this->date);                           // 2 last mod file date
		ZIP_LE32(header + ZIP_LFH_CRC, crc);                                        // 4 crc-32
		ZIP_LE32(header + ZIP_LFH_COMPRESSED_SIZE, compressed_size);                // 4 compressed size
		ZIP_LE32(header + ZIP_LFH_UNCOMPRESSED_SIZE, uncompressed_size);            // 4 uncompressed size
		ZIP_LE16(header + ZIP_LFH_FILENAME_LEN, arc_name_size);                     // 2 file name length
		                                                                            // 2 extra field length
		this->write((const char*)&header, ZIP_LFH_SIZE);
		}
	void write_central_directory_header() {
		zip_header header = {};
		for (const auto &zinfo : this->zinfo_list) {
			std::memset(&header, '\0', ZIP_HEADER_SIZE);
			ZIP_LE32(header,  ZIP_CDH_SIGNATURE);                                     // 4 central file header signature (0x02014b50)
			ZIP_LE16(header + ZIP_CDH_VERSION_MADE_BY, 20);                           // 2 version made by
			ZIP_LE16(header + ZIP_CDH_VERSION_NEEDED, 20);                            // 2 version needed to extract
			                                                                          // 2 general purpose bit flag
			ZIP_LE16(header + ZIP_CDH_COMPRESSION_METHOD, this->compression_method);  // 2 compression method
			ZIP_LE16(header + ZIP_CDH_FILE_TIME, this->time);                         // 2 file last mod time
			ZIP_LE16(header + ZIP_CDH_FILE_DATE, this->date);                         // 2 file last mod date
			ZIP_LE32(header + ZIP_CDH_CRC, zinfo.crc);                                // 4 crc-32
			ZIP_LE32(header + ZIP_CDH_COMPRESSED_SIZE, zinfo.compressed_size);        // 4 compressed size
			ZIP_LE32(header + ZIP_CDH_UNCOMPRESSED_SIZE, zinfo.uncompressed_size);    // 4 uncompressed size
			ZIP_LE16(header + ZIP_CDH_FILENAME_LEN, zinfo.arc_name.size());           // 2 file name length
			                                                                          // 2 extra field length
			                                                                          // 2 file comment length
			                                                                          // 2 disk number start
			                                                                          // 2 internal file attributes
			ZIP_LE32(header + ZIP_CDH_EXTERNAL_ATTR, 0600 << 16);                     // 4 external file attributes
			ZIP_LE32(header + ZIP_CDH_LFH_OFFSET, zinfo.header_offset);               // 4 relative offset of local header
			this->write((const char*)&header, ZIP_CDH_SIZE);
			this->write(zinfo.arc_name.c_str(), zinfo.arc_name.size());
			}
		}
	void write_end_of_central_directory_record(uint64_t central_dir_offset) {
		zip_header header = {};
		ZIP_LE32(header,  ZIP_ECDR_SIGNATURE);                                      // 4 end of central dir signature (0x06054b50)
		                                                                            // 2 number of this disk
		                                                                            // 2 number of the disk with the start of the central directory
		ZIP_LE16(header + ZIP_ECDR_TOTAL_ENTRIES_DISK, this->zinfo_list.size());    // 2 total number of entries in the central directory on this disk
		ZIP_LE16(header + ZIP_ECDR_TOTAL_ENTRIES, this->zinfo_list.size());         // 2 total number of entries in the central directory
		ZIP_LE32(header + ZIP_ECDR_SIZE_CDH, (this->tellp() - central_dir_offset)); // 4 size of central directory
		ZIP_LE32(header + ZIP_ECDR_START_CDH, central_dir_offset);                  // 4 offset of start of central directory with respect to the starting disk number
		this->write((const char*)&header, ZIP_ECDR_SIZE);
		}
	};

void write_archive(std::string &filename, std::unordered_map<std::string, std::string> &files, bool compress) {
	zip_file archive = zip_file(filename, compress);
	for (const auto &[arc_name, file] : files)
		archive.write_str(arc_name, file);
	archive.close();
	}
