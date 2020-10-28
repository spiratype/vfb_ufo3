// archive.hpp

#pragma once
#pragma pack(1)

// https://pkware.cachefly.net/webdocs/casestudies/APPNOTE.TXT

#define ZIP_STORED (0)
#define ZIP_DEFLATED Z_DEFLATED

#define ZIP_LFH_SIGNATURE (0x04034b50)
#define ZIP_LFH_SIZE (30)

#define ZIP_CDH_SIGNATURE (0x02014b50)
#define ZIP_CDH_SIZE (46)

#define ZIP_ECDR_SIGNATURE (0x06054b50)
#define ZIP_ECDR_SIZE (22)

typedef unsigned char u_char;

struct zip_info {
  std::string arc_name;
  std::uint32_t uncompressed_size;
  std::uint32_t compressed_size;
  std::uint32_t crc;
  std::uint32_t header_offset;
  std::uint16_t compression_method;
  std::uint16_t time;
  std::uint16_t date;
  zip_info() {}
  zip_info(
    const std::string &arc_name,
    std::uint16_t compression_method,
    std::uint16_t time,
    std::uint16_t date,
    std::uint32_t uncompressed_size,
    std::uint32_t compressed_size,
    std::uint32_t crc,
    std::uint32_t header_offset
    );
  };

struct zip_local_file_header {
  const std::uint32_t signature = ZIP_LFH_SIGNATURE;    // 4 local file header signature (0x04034b50)
  const std::uint16_t version_needed = 20;              // 2 version needed to extract (minimum)
  const std::uint16_t gp_bit_flag = 0;                  // 2 general purpose bit flag
  std::uint16_t compression_method;                     // 2 compression method
  std::uint16_t time;                                   // 2 last mod file time
  std::uint16_t date;                                   // 2 last mod file date
  std::uint32_t crc;                                    // 4 crc-32
  std::uint32_t compressed_size;                        // 4 compressed size
  std::uint32_t uncompressed_size;                      // 4 uncompressed size
  std::uint16_t arc_name_len;                           // 2 file name length
  const std::uint16_t extra_field_len = 0;              // 2 extra field length
  explicit zip_local_file_header(const zip_info &zinfo);
  };

struct zip_central_directory_header {
  std::uint32_t signature = ZIP_CDH_SIGNATURE;          // 4 central file header signature (0x02014b50)
  std::uint16_t version_made_by = 20;                   // 2 version made by
  std::uint16_t version_needed = 20;                    // 2 version needed to extract
  std::uint16_t gp_bit_flag = 0;                        // 2 general purpose bit flag
  std::uint16_t compression_method;                     // 2 compression method
  std::uint16_t time;                                   // 2 file last mod time
  std::uint16_t date;                                   // 2 file last mod date
  std::uint32_t crc;                                    // 4 crc-32
  std::uint32_t compressed_size;                        // 4 compressed size
  std::uint32_t uncompressed_size;                      // 4 uncompressed size
  std::uint16_t file_name_len;                          // 2 file name length
  std::uint16_t extra_field_len = 0;                    // 2 extra field length
  std::uint16_t file_comment_len = 0;                   // 2 file comment length
  std::uint16_t disk_number_start = 0;                  // 2 disk number start
  std::uint16_t internal_file_attributes = 0;           // 2 internal file attributes
  std::uint32_t external_file_attributes = 0600 << 16;  // 4 external file attributes
  std::uint32_t relative_header_offset;                 // 4 relative offset of local header
  zip_central_directory_header() {}
  explicit zip_central_directory_header(const zip_info &zinfo);
  };

struct zip_end_of_central_directory {
  const std::uint32_t signature = ZIP_ECDR_SIGNATURE;   // 4 end of central dir signature (0x06054b50)
  const std::uint16_t disk_num = 0;                     // 2 number of this disk
  const std::uint16_t disk_num_start = 0;               // 2 number of the disk with the start of the central directory
  std::uint16_t num_entries_disk;                       // 2 total number of entries in the central directory on this disk
  std::uint16_t num_entries_total;                      // 2 total number of entries in the central directory
  std::uint32_t size;                                   // 4 size of central directory
  std::uint32_t offset;                                 // 4 offset of start of central directory with respect to the starting disk number
  const std::uint16_t comment_len = 0;                  // 2 .ZIP file comment length
  zip_end_of_central_directory(std::uint16_t num_entries, std::uint32_t size, std::uint32_t offset);
  };
