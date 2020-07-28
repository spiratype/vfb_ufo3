#pragma once

static const std::string zip_compress_str(const std::string &data) {
	z_stream stream;
	char out[data.size() + 1024];

	stream.opaque = Z_NULL;
	stream.zalloc = Z_NULL;
	stream.zfree = Z_NULL;
	stream.avail_in = data.size();
	stream.next_in = (u_char*)data.c_str();
	stream.avail_out = data.size();
	stream.next_out = (u_char*)&out;

	// provides a raw deflate (no zlib header and trailer)
	deflateInit2(&stream, Z_BEST_COMPRESSION, Z_DEFLATED, -15, 9, Z_DEFAULT_STRATEGY);
	deflate(&stream, Z_FINISH);
	deflateEnd(&stream);

	return std::string((const char*)&out, stream.total_out);
	}

static inline void zip_le16(u_char* arr, u_short v) {
	arr[0] = (u_char)v;
	arr[1] = (u_char)(v >> 8);
	}

static inline void zip_le32(u_char* arr, u_int v) {
	zip_le16(arr, v);
	arr[2] = (u_char)(v >> 16);
	arr[3] = (u_char)(v >> 24);
	}

struct zip_info {
	std::string arc_name;
	u_long uncompressed_size;
	u_long compressed_size;
	u_long crc;
	u_long header_offset;
	zip_info() {}
	zip_info(std::string arc_name, u_long uncompressed_size, u_long compressed_size, u_long crc, u_long header_offset) {
		this->arc_name = arc_name;
		this->uncompressed_size = uncompressed_size;
		this->compressed_size = compressed_size;
		this->crc = crc;
		this->header_offset = header_offset;
		}
	};
