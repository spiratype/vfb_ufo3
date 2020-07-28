#pragma once

// https://pkware.cachefly.net/webdocs/casestudies/APPNOTE.TXT

#define ZIP_STORED (0)

#define ZIP_HEADER_SIZE (256)

#define ZIP_LFH_SIGNATURE (0x04034b50)
#define ZIP_LFH_VERSION_NEEDED (4)
#define ZIP_LFH_BIT_FLAG (6)
#define ZIP_LFH_METHOD (8)
#define ZIP_LFH_FILE_TIME (10)
#define ZIP_LFH_FILE_DATE (12)
#define ZIP_LFH_CRC (14)
#define ZIP_LFH_COMPRESSED_SIZE (18)
#define ZIP_LFH_UNCOMPRESSED_SIZE (22)
#define ZIP_LFH_FILENAME_LEN (26)
#define ZIP_LFH_SIZE (30)

#define ZIP_CDH_SIGNATURE (0x02014b50)
#define ZIP_CDH_VERSION_MADE_BY (4)
#define ZIP_CDH_VERSION_NEEDED (6)
#define ZIP_CDH_BIT_FLAG (8)
#define ZIP_CDH_COMPRESSION_METHOD (10)
#define ZIP_CDH_FILE_TIME (12)
#define ZIP_CDH_FILE_DATE (14)
#define ZIP_CDH_CRC (16)
#define ZIP_CDH_COMPRESSED_SIZE (20)
#define ZIP_CDH_UNCOMPRESSED_SIZE (24)
#define ZIP_CDH_FILENAME_LEN (28)
#define ZIP_CDH_DISK_START (34)
#define ZIP_CDH_INTERNAL_ATTR (36)
#define ZIP_CDH_EXTERNAL_ATTR (38)
#define ZIP_CDH_LFH_OFFSET (42)
#define ZIP_CDH_SIZE (46)

#define ZIP_ECDR_SIGNATURE (0x06054b50)
#define ZIP_ECDR_DISK_NUMBER (4)
#define ZIP_ECDR_DISK_NUMBER_CDH (6)
#define ZIP_ECDR_TOTAL_ENTRIES (8)
#define ZIP_ECDR_TOTAL_ENTRIES_DISK (10)
#define ZIP_ECDR_SIZE_CDH (12)
#define ZIP_ECDR_START_CDH (16)
#define ZIP_ECDR_SIZE (22)

typedef unsigned char u_char;
typedef unsigned short u_short;
typedef unsigned int u_int;
typedef unsigned long u_long;

typedef char zip_header[ZIP_HEADER_SIZE];

static inline void zip_le16(u_char* arr, u_short v);
static inline void zip_le32(u_char* arr, u_int v);

#define ZIP_LE16(arr, v) zip_le16((u_char*)(arr), (u_short)(v))
#define ZIP_LE32(arr, v) zip_le32((u_char*)(arr), (u_int)(v))
