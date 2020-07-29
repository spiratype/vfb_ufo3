// zip.hpp

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
typedef unsigned short u_short;
typedef unsigned int u_int;
typedef unsigned long u_long;
