# core.pxi

OPTIMIZE_CODE_POINTS = {
	0x00c0, 0x00c1, 0x00c2, 0x00c3, 0x00c4, 0x00c8, 0x00c9, 0x00ca,
	0x00cb, 0x00cc, 0x00cd, 0x00ce, 0x00cf, 0x00d1, 0x00d2, 0x00d3,
	0x00d4, 0x00d5, 0x00d6, 0x00d9, 0x00da, 0x00db, 0x00dc, 0x00dd,
	0x00e0, 0x00e1, 0x00e2, 0x00e3, 0x00e4, 0x00e8, 0x00e9, 0x00ea,
	0x00eb, 0x00ec, 0x00ed, 0x00ee, 0x00ef, 0x00f1, 0x00f2, 0x00f3,
	0x00f4, 0x00f5, 0x00f6, 0x00f9, 0x00fa, 0x00fb, 0x00fc, 0x00fd,
	0x00ff, 0x0100, 0x0101, 0x0102, 0x0103, 0x0106, 0x0107, 0x0108,
	0x0109, 0x010a, 0x010b, 0x010c, 0x010d, 0x010e, 0x010f, 0x0112,
	0x0113, 0x0114, 0x0115, 0x0116, 0x0117, 0x011a, 0x011b, 0x011c,
	0x011d, 0x011e, 0x011f, 0x0120, 0x0121, 0x0122, 0x0123, 0x0124,
	0x0125, 0x0128, 0x0129, 0x012a, 0x012b, 0x012c, 0x012d, 0x0130,
	0x0132, 0x0133, 0x0134, 0x0135, 0x0136, 0x0137, 0x0139, 0x013a,
	0x013b, 0x013c, 0x013d, 0x013e, 0x013f, 0x0140, 0x0143, 0x0144,
	0x0145, 0x0146, 0x0147, 0x0148, 0x0149, 0x014c, 0x014d, 0x014e,
	0x014f, 0x0150, 0x0151, 0x0154, 0x0155, 0x0156, 0x0157, 0x0158,
	0x0159, 0x015a, 0x015b, 0x015c, 0x015d, 0x015e, 0x015f, 0x0160,
	0x0161, 0x0162, 0x0163, 0x0164, 0x0165, 0x0168, 0x0169, 0x016a,
	0x016b, 0x016c, 0x016d, 0x016e, 0x016f, 0x0170, 0x0171, 0x0174,
	0x0175, 0x0176, 0x0177, 0x0178, 0x0179, 0x017a, 0x017b, 0x017c,
	0x017d, 0x017e, 0x01c4, 0x01c5, 0x01c6, 0x01c7, 0x01c8, 0x01c9,
	0x01ca, 0x01cb, 0x01cc, 0x01cd, 0x01ce, 0x01cf, 0x01d0, 0x01d1,
	0x01d2, 0x01d3, 0x01d4, 0x01d5, 0x01d6, 0x01d7, 0x01d8, 0x01d9,
	0x01da, 0x01db, 0x01dc, 0x01e2, 0x01e3, 0x01e6, 0x01e7, 0x01f0,
	0x01f1, 0x01f2, 0x01f3, 0x01f4, 0x01f5, 0x01f8, 0x01f9, 0x01fc,
	0x01fd, 0x0200, 0x0201, 0x0202, 0x0203, 0x0204, 0x0205, 0x0206,
	0x0207, 0x0208, 0x0209, 0x020a, 0x020b, 0x020c, 0x020d, 0x020e,
	0x020f, 0x0210, 0x0211, 0x0212, 0x0213, 0x0214, 0x0215, 0x0216,
	0x0217, 0x0218, 0x0219, 0x021a, 0x021b, 0x0226, 0x0227, 0x022e,
	0x022f, 0x0232, 0x0233, 0x0400, 0x0401, 0x0403, 0x0405, 0x0406,
	0x0407, 0x0408, 0x040c, 0x040d, 0x040e, 0x0419, 0x0439, 0x0450,
	0x0451, 0x0453, 0x0455, 0x0456, 0x0457, 0x0458, 0x045c, 0x045d,
	0x045e, 0x0476, 0x0477, 0x04c0, 0x04c1, 0x04c2, 0x04cf, 0x04d0,
	0x04d1, 0x04d2, 0x04d3, 0x04d4, 0x04d5, 0x04d6, 0x04d7, 0x04d8,
	0x04d9, 0x04da, 0x04db, 0x04dc, 0x04dd, 0x04de, 0x04df, 0x04e2,
	0x04e3, 0x04e4, 0x04e5, 0x04e6, 0x04e7, 0x04ee, 0x04ef, 0x04f0,
	0x04f1, 0x04f2, 0x04f3, 0x04f4, 0x04f5, 0x04f8, 0x04f9, 0x1e06,
	0x1e07, 0x1e0c, 0x1e0d, 0x1e0e, 0x1e0f, 0x1e12, 0x1e13, 0x1e20,
	0x1e21, 0x1e24, 0x1e25, 0x1e2a, 0x1e2b, 0x1e32, 0x1e33, 0x1e34,
	0x1e35, 0x1e36, 0x1e37, 0x1e38, 0x1e39, 0x1e3a, 0x1e3b, 0x1e3c,
	0x1e3d, 0x1e3e, 0x1e3f, 0x1e40, 0x1e41, 0x1e42, 0x1e43, 0x1e44,
	0x1e45, 0x1e46, 0x1e47, 0x1e48, 0x1e49, 0x1e4a, 0x1e4b, 0x1e58,
	0x1e59, 0x1e5a, 0x1e5b, 0x1e5c, 0x1e5d, 0x1e5e, 0x1e5f, 0x1e62,
	0x1e63, 0x1e6c, 0x1e6d, 0x1e6e, 0x1e6f, 0x1e70, 0x1e71, 0x1e7e,
	0x1e7f, 0x1e80, 0x1e81, 0x1e82, 0x1e83, 0x1e84, 0x1e85, 0x1e86,
	0x1e87, 0x1e8a, 0x1e8b, 0x1e8c, 0x1e8d, 0x1e8e, 0x1e8f, 0x1e90,
	0x1e91, 0x1e92, 0x1e93, 0x1e94, 0x1e95, 0x1e96, 0x1f00, 0x1f01,
	0x1f02, 0x1f03, 0x1f04, 0x1f05, 0x1f06, 0x1f07, 0x1f08, 0x1f09,
	0x1f0a, 0x1f0b, 0x1f0c, 0x1f0d, 0x1f0e, 0x1f0f, 0x1f10, 0x1f11,
	0x1f12, 0x1f13, 0x1f14, 0x1f15, 0x1f18, 0x1f19, 0x1f1a, 0x1f1b,
	0x1f1c, 0x1f1d, 0x1f20, 0x1f21, 0x1f22, 0x1f23, 0x1f24, 0x1f25,
	0x1f26, 0x1f27, 0x1f28, 0x1f29, 0x1f2a, 0x1f2b, 0x1f2c, 0x1f2d,
	0x1f2e, 0x1f2f, 0x1f30, 0x1f31, 0x1f32, 0x1f33, 0x1f34, 0x1f35,
	0x1f36, 0x1f37, 0x1f38, 0x1f39, 0x1f3a, 0x1f3b, 0x1f3c, 0x1f3d,
	0x1f3e, 0x1f3f, 0x1f40, 0x1f41, 0x1f42, 0x1f43, 0x1f44, 0x1f45,
	0x1f48, 0x1f49, 0x1f4a, 0x1f4b, 0x1f4c, 0x1f4d, 0x1f50, 0x1f51,
	0x1f52, 0x1f53, 0x1f54, 0x1f55, 0x1f56, 0x1f57, 0x1f59, 0x1f5b,
	0x1f5d, 0x1f5f, 0x1f60, 0x1f61, 0x1f62, 0x1f63, 0x1f64, 0x1f65,
	0x1f66, 0x1f67, 0x1f68, 0x1f69, 0x1f6a, 0x1f6b, 0x1f6c, 0x1f6d,
	0x1f6e, 0x1f6f, 0x1f70, 0x1f71, 0x1f72, 0x1f73, 0x1f74, 0x1f75,
	0x1f76, 0x1f77, 0x1f78, 0x1f79, 0x1f7a, 0x1f7b, 0x1f7c, 0x1f7d,
	0x1f80, 0x1f81, 0x1f82, 0x1f83, 0x1f84, 0x1f85, 0x1f86, 0x1f87,
	0x1f88, 0x1f89, 0x1f8a, 0x1f8b, 0x1f8c, 0x1f8d, 0x1f8e, 0x1f8f,
	0x1f90, 0x1f91, 0x1f92, 0x1f93, 0x1f94, 0x1f95, 0x1f96, 0x1f97,
	0x1f98, 0x1f99, 0x1f9a, 0x1f9b, 0x1f9c, 0x1f9d, 0x1f9e, 0x1f9f,
	0x1fa0, 0x1fa1, 0x1fa2, 0x1fa3, 0x1fa4, 0x1fa5, 0x1fa6, 0x1fa7,
	0x1fa8, 0x1fa9, 0x1faa, 0x1fab, 0x1fac, 0x1fad, 0x1fae, 0x1faf,
	0x1fb0, 0x1fb1, 0x1fb2, 0x1fb3, 0x1fb4, 0x1fb6, 0x1fb7, 0x1fb8,
	0x1fb9, 0x1fba, 0x1fbb, 0x1fbc, 0x1fc2, 0x1fc3, 0x1fc4, 0x1fc6,
	0x1fc7, 0x1fc8, 0x1fc9, 0x1fca, 0x1fcb, 0x1fcc, 0x1fd0, 0x1fd1,
	0x1fd2, 0x1fd3, 0x1fd6, 0x1fd7, 0x1fd8, 0x1fd9, 0x1fda, 0x1fdb,
	0x1fe0, 0x1fe1, 0x1fe2, 0x1fe3, 0x1fe4, 0x1fe5, 0x1fe6, 0x1fe7,
	0x1fe8, 0x1fe9, 0x1fea, 0x1feb, 0x1fec, 0x1ff2, 0x1ff3, 0x1ff4,
	0x1ff6, 0x1ff7, 0x1ff8, 0x1ff9, 0x1ffa, 0x1ffb, 0x1ffc,
	}

UFO_AFDKO = (
	('makeotf', attribute_dict(UFO_AFDKO_MAKEOTF)),
	)

UFO_PATHS += [
	('instance', attribute_dict(UFO_PATHS_INSTANCE)),
	('afdko', attribute_dict(UFO_PATHS_AFDKO)),
	]

UFO_BASE += [
	('glyph_sets', attribute_dict(UFO_GLYPH_SETS)),
	('code_points', attribute_dict(UFO_CODE_POINTS)),
	('master', attribute_dict(UFO_MASTER)),
	('master_copy', attribute_dict(UFO_MASTER_COPY)),
	('instance', attribute_dict(UFO_INSTANCE)),
	('total_times', attribute_dict(UFO_TIMES_TOTAL)),
	('instance_times', attribute_dict(UFO_TIMES_INSTANCE)),
	('plists', attribute_dict(UFO_PLISTS)),
	('paths', attribute_dict(UFO_PATHS)),
	('afdko', attribute_dict(UFO_AFDKO)),
	('psautohint', attribute_dict(UFO_PSAUTOHINT)),
	('groups', attribute_dict(UFO_GROUPS)),
	('kern', attribute_dict(UFO_KERN)),
	('designspace', attribute_dict(UFO_DESIGNSPACE)),
	]

MATRIX = (
	(0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1),
	(0, 0, 1, 1, 0, 0, 1, 1, 0, 0, 1, 1, 0, 0, 1, 1),
	(0, 0, 0, 0, 1, 1, 1, 1, 0, 0, 0, 0, 1, 1, 1, 1),
	(0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1),
	)

UFO = attribute_dict(UFO_BASE)
