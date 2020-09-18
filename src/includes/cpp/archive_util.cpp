// archive_util.cpp

#pragma once

static const std::string zip_deflate_str(const std::string &data) {
	z_stream stream;
	u_char out[data.size() + 1024];

	stream.opaque = Z_NULL;
	stream.zalloc = Z_NULL;
	stream.zfree = Z_NULL;
	stream.avail_in = data.size();
	stream.next_in = (u_char*)data.c_str();
	stream.avail_out = data.size();
	stream.next_out = (u_char*)&out;

	// provides a raw deflate (no zlib header and trailer)
	deflateInit2(&stream, Z_DEFAULT_COMPRESSION, Z_DEFLATED, -15, 9, Z_DEFAULT_STRATEGY);
	deflate(&stream, Z_FINISH);
	deflateEnd(&stream);

	return std::string((const char*)&out, stream.total_out);
	}

static const std::string zip_compress_str(const std::string &data, u_int compression_method) {
	if (compression_method == ZIP_DEFLATED)
		return zip_deflate_str(data);
	return data;
	}

struct zip_info {
	std::string arc_name;
	u_int uncompressed_size;
	u_int compressed_size;
	u_int crc;
	u_int header_offset;
	u_short compression_method;
	u_short time;
	u_short date;
	zip_info() {}
	zip_info(
		const std::string &arc_name,
		u_short compression_method,
		u_short time,
		u_short date,
		u_int uncompressed_size,
		u_int compressed_size,
		u_int crc,
		u_int header_offset
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
	};

struct zip_local_file_header {
	u_int signature;                     // 4 local file header signature (0x04034b50)
	u_short version_needed;              // 2 version needed to extract (minimum)
	u_short gp_bit_flag;                 // 2 general purpose bit flag
	u_short compression_method;          // 2 compression method
	u_short time;                        // 2 last mod file time
	u_short date;                        // 2 last mod file date
	u_int crc;                           // 4 crc-32
	u_int compressed_size;               // 4 compressed size
	u_int uncompressed_size;             // 4 uncompressed size
	u_short arc_name_len;                // 2 file name length
	u_short extra_field_len;             // 2 extra field length
	zip_local_file_header(const zip_info &zinfo) {
		this->signature = ZIP_LFH_SIGNATURE;
		this->version_needed = 20;
		this->gp_bit_flag = 0;
		this->compression_method = zinfo.compression_method;
		this->time = zinfo.time;
		this->date = zinfo.date;
		this->crc = zinfo.crc;
		this->compressed_size = zinfo.compressed_size;
		this->uncompressed_size = zinfo.uncompressed_size;
		this->arc_name_len = zinfo.arc_name.size();
		this->extra_field_len = 0;
		}
	};

struct zip_central_directory_header {
	u_int signature;                     // 4 central file header signature (0x02014b50)
	u_short version_made_by;             // 2 version made by
	u_short version_needed;              // 2 version needed to extract
	u_short gp_bit_flag;                 // 2 general purpose bit flag
	u_short compression_method;          // 2 compression method
	u_short time;                        // 2 file last mod time
	u_short date;                        // 2 file last mod date
	u_int crc;                           // 4 crc-32
	u_int compressed_size;               // 4 compressed size
	u_int uncompressed_size;             // 4 uncompressed size
	u_short file_name_len;               // 2 file name length
	u_short extra_field_len;             // 2 extra field length
	u_short file_comment_len;            // 2 file comment length
	u_short disk_number_start;           // 2 disk number start
	u_short internal_file_attributes;    // 2 internal file attributes
	u_int external_file_attributes;      // 4 external file attributes
	u_int relative_header_offset;        // 4 relative offset of local header
	zip_central_directory_header() {}
	zip_central_directory_header(const zip_info &zinfo) {
		this->signature = ZIP_CDH_SIGNATURE;
		this->version_made_by = 20;
		this->version_needed = 20;
		this->compression_method = zinfo.compression_method;
		this->time = zinfo.time;
		this->date = zinfo.date;
		this->crc = zinfo.crc;
		this->compressed_size = zinfo.compressed_size;
		this->uncompressed_size = zinfo.uncompressed_size;
		this->file_name_len = zinfo.arc_name.size();
		this->external_file_attributes = 0600 << 16;
		this->relative_header_offset = zinfo.header_offset;
		}
	};

struct zip_end_of_central_directory {
	u_int signature;                     // 4 end of central dir signature (0x06054b50)
	u_short disk_num;                    // 2 number of this disk
	u_short disk_num_start;              // 2 number of the disk with the start of the central directory
	u_short num_entries_disk;            // 2 total number of entries in the central directory on this disk
	u_short num_entries_total;           // 2 total number of entries in the central directory
	u_int size;                          // 4 size of central directory
	u_int offset;                        // 4 offset of start of central directory with respect to the starting disk number
	u_short comment_len;                 // 2 .ZIP file comment length
	zip_end_of_central_directory(u_short num_entries, u_int size, u_int offset) {
		this->signature = ZIP_ECDR_SIGNATURE;
		this->disk_num = 0;
		this->disk_num_start = 0;
		this->num_entries_disk = num_entries;
		this->num_entries_total = num_entries;
		this->size = size;
		this->offset = offset;
		this->comment_len = 0;
		}
	};
