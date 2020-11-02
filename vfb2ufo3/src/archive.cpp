// archive.cpp

#include <cstdint>
#include <ctime>
#include <fstream>
#include <string>
#include <unordered_map>
#include <vector>

#include "zlib.h"

#include "archive.hpp"

namespace zip {

zip_info::zip_info(
    const std::string &arc_name,
    std::uint16_t compression_method,
    std::uint16_t time,
    std::uint16_t date,
    std::uint32_t uncompressed_size,
    std::uint32_t compressed_size,
    std::uint32_t crc,
    std::uint32_t header_offset
    ) {
  this->arc_name = arc_name;
  this->compression_method = compression_method;
  this->time = time;
  this->date = date;
  this->uncompressed_size = uncompressed_size;
  this->compressed_size = compressed_size;
  this->crc = crc;
  this->header_offset = header_offset;
  }

local_file_header::local_file_header(const zip_info &zinfo) {
  this->compression_method = zinfo.compression_method;
  this->time = zinfo.time;
  this->date = zinfo.date;
  this->crc = zinfo.crc;
  this->compressed_size = zinfo.compressed_size;
  this->uncompressed_size = zinfo.uncompressed_size;
  this->arc_name_len = zinfo.arc_name.size();
  }

central_directory_header::central_directory_header(const zip_info &zinfo) {
  this->compression_method = zinfo.compression_method;
  this->time = zinfo.time;
  this->date = zinfo.date;
  this->crc = zinfo.crc;
  this->compressed_size = zinfo.compressed_size;
  this->uncompressed_size = zinfo.uncompressed_size;
  this->file_name_len = zinfo.arc_name.size();
  this->relative_header_offset = zinfo.header_offset;
  }

end_of_central_directory::end_of_central_directory(std::uint16_t num_entries, std::uint32_t size, std::uint32_t offset) {
  this->num_entries_disk = num_entries;
  this->num_entries_total = num_entries;
  this->size = size;
  this->offset = offset;
  }

zip_file::zip_file(const std::string &arc_path, bool compress=true) {
  this->arc_path = arc_path;
  this->compression_method = compress ? Z_DEFLATED : 0;
  auto t = std::time(nullptr);
  auto dt = *std::localtime(&t);
  this->date = ((dt.tm_year - 80) << 9) + ((dt.tm_mon + 1) << 5) + dt.tm_mday;
  this->time = (dt.tm_hour << 11) + (dt.tm_min << 5) + (int(dt.tm_sec / 2));
  this->archive.open(this->arc_path, std::ios::binary);
  }
void zip_file::reserve(size_t n) {
  this->zinfo_list.reserve(n);
  }
void zip_file::close() {
  if (this->archive.is_open()) {
    this->finish();
    this->archive.close();
    }
  }
void zip_file::write_str(const std::string &arc_name, const std::string &data) {
  std::string compressed;
  std::uint32_t crc = crc32_z(0, (const byte*)data.c_str(), data.size());
  std::uint32_t header_offset = this->tellp();

  if (this->compression_method)
    compressed = compress_str(data, this->compression_method);

  auto zinfo = this->zinfo_list.emplace_back(
    arc_name,
    this->compression_method,
    this->time,
    this->date,
    data.size(),
    compressed.size(),
    crc,
    header_offset
    );

  this->write_local_file_header(zinfo);
  this->write(compressed.size() ? compressed : data);
  }
void zip_file::write(const std::string &data) {
  this->archive.write(data.c_str(), data.size());
  }
void zip_file::write(const char* data, size_t size) {
  this->archive.write(data, size);
  }
std::uint32_t zip_file::tellp() {
  return (std::uint32_t)this->archive.tellp();
  }
void zip_file::finish() {
  std::uint32_t central_dir_offset = this->tellp();
  this->write_central_directory_header();
  this->write_end_of_central_directory_record(central_dir_offset);
  }
void zip_file::write_local_file_header(const zip_info &zinfo) {
  zip::local_file_header local_file_header(zinfo);
  this->write((const char*)&local_file_header, 30);
  this->write(zinfo.arc_name.c_str(), zinfo.arc_name.size());
  }
void zip_file::write_central_directory_header() {
  zip::central_directory_header central_directory_header;
  for (const auto &zinfo : this->zinfo_list) {
    central_directory_header = zip::central_directory_header(zinfo);
    this->write((const char*)&central_directory_header, 46);
    this->write(zinfo.arc_name.c_str(), zinfo.arc_name.size());
    }
  }
void zip_file::write_end_of_central_directory_record(std::uint32_t central_dir_offset) {
  size_t num_entries = this->zinfo_list.size();
  std::uint32_t central_dir_size = this->tellp() - central_dir_offset;
  zip::end_of_central_directory end_of_central_directory(num_entries, central_dir_size, central_dir_offset);
  this->write((const char*)&end_of_central_directory, 22);
  }

std::string deflate_str(const std::string &data) {
  z_stream stream;
  std::vector<byte> out;
  out.reserve(data.size() + 512);

  stream.opaque = Z_NULL;
  stream.zalloc = Z_NULL;
  stream.zfree = Z_NULL;
  stream.avail_in = data.size();
  stream.next_in = (byte*)data.data();
  stream.avail_out = data.size();
  stream.next_out = out.data();

  // provides a raw deflate (no zlib header and trailer)
  deflateInit2(&stream, Z_DEFAULT_COMPRESSION, Z_DEFLATED, -15, 9, Z_DEFAULT_STRATEGY);
  deflate(&stream, Z_FINISH);
  deflateEnd(&stream);

  return std::string((const char*)out.data(), stream.total_out);
  }

std::string compress_str(const std::string &data, std::uint32_t compression_method) {
  if (compression_method == Z_DEFLATED)
    return deflate_str(data);
  return data;
  }

void write_archive(const std::string &filename, std::unordered_map<std::string, std::string> &files, bool compress) {
  zip::zip_file archive(filename, compress);
  archive.reserve(files.size());
  for (const auto &[arc_name, file] : files)
    archive.write_str(arc_name, file);
  archive.close();
  }

} // namespace zip
