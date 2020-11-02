// archive_util.cpp

#pragma once

std::string zip_deflate_str(const std::string &data) {
  z_stream stream;
  std::vector<u_char> out;
  out.reserve(data.size() + 512);

  stream.opaque = Z_NULL;
  stream.zalloc = Z_NULL;
  stream.zfree = Z_NULL;
  stream.avail_in = data.size();
  stream.next_in = (u_char*)data.c_str();
  stream.avail_out = data.size();
  stream.next_out = out.data();

  // provides a raw deflate (no zlib header and trailer)
  deflateInit2(&stream, Z_DEFAULT_COMPRESSION, Z_DEFLATED, -15, 9, Z_DEFAULT_STRATEGY);
  deflate(&stream, Z_FINISH);
  deflateEnd(&stream);

  return std::string((const char*)out.data(), stream.total_out);
  }

static std::string zip_compress_str(const std::string &data, std::uint32_t compression_method) {
  if (compression_method == ZIP_DEFLATED)
    return zip_deflate_str(data);
  return data;
  }

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

zip_local_file_header::zip_local_file_header(const zip_info &zinfo) {
  this->compression_method = zinfo.compression_method;
  this->time = zinfo.time;
  this->date = zinfo.date;
  this->crc = zinfo.crc;
  this->compressed_size = zinfo.compressed_size;
  this->uncompressed_size = zinfo.uncompressed_size;
  this->arc_name_len = zinfo.arc_name.size();
  }

zip_central_directory_header::zip_central_directory_header(const zip_info &zinfo) {
  this->compression_method = zinfo.compression_method;
  this->time = zinfo.time;
  this->date = zinfo.date;
  this->crc = zinfo.crc;
  this->compressed_size = zinfo.compressed_size;
  this->uncompressed_size = zinfo.uncompressed_size;
  this->file_name_len = zinfo.arc_name.size();
  this->relative_header_offset = zinfo.header_offset;
  }

zip_end_of_central_directory::zip_end_of_central_directory(std::uint16_t num_entries, std::uint32_t size, std::uint32_t offset) {
  this->num_entries_disk = num_entries;
  this->num_entries_total = num_entries;
  this->size = size;
  this->offset = offset;
  }
