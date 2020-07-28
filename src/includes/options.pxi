# OPTIONS

DEFAULT_OPTIONS = (
	('output_path', None),
	('layer', None),
	('scale_to_upm', 1000),
	('scale_auto', True),
	('instance_values', []),
	('instance_names', []),
	('instance_attributes', []),
	('features_import_groups', False),
	('kern_feature_generate', True),
	('kern_feature_file_path', None),
	('kern_feature_passthrough', False),
	('kern_min_value', None),
	('mark_feature_generate', False),
	('mark_anchors_include', []),
	('mark_anchors_omit', []),
	('groups_export_flc', False),
	('groups_export_flc_path', None),
	('groups_flc_path', None),
	('groups_plist_path', None),
	('groups_ignore_no_kerning', False),
	('afdko_parts', False),
	('afdko_makeotf_cmd', False),
	('afdko_makeotf_batch_cmd', False),
	('afdko_makeotf_output_dir', None),
	('afdko_makeotf_GOADB_path', None),
	('afdko_makeotf_GOADB_win1252', True),
	('afdko_makeotf_GOADB_macos_roman', False),
	('afdko_makeotf_release', False),
	('afdko_makeotf_subroutinization', True),
	('afdko_makeotf_no_subroutinization', False),
	('afdko_makeotf_sans', False),
	('afdko_makeotf_serif', False),
	('afdko_makeotf_replace_notdef', False),
	('afdko_makeotf_verbose', False),
	('afdko_makeotf_addDSIG', True),
	('afdko_makeotf_suppress_unhinted_glyph_warnings', True),
	('afdko_makeotf_args', []),
	('psautohint_cmd', False),
	('psautohint_batch_cmd', False),
	('psautohint_write_to_default_layer', True),
	('psautohint_decimal', True),
	('psautohint_allow_outline_changes', False),
	('psautohint_no_flex', False),
	('psautohint_no_hint_substitution', False),
	('psautohint_no_zones_stems', False),
	('psautohint_log', False),
	('psautohint_report_only', False),
	('psautohint_verbose', False),
	('psautohint_extra_verbose', False),
	('psautohint_glyphs_list', []),
	('psautohint_glyphs_omit_list', []),
	('glyphs_decompose', False),
	('glyphs_remove_overlaps', False),
	('glyphs_omit_names', []),
	('glyphs_omit_suffixes', []),
	('glyphs_optimize', True),
	('glyphs_optimize_code_points', []),
	('glyphs_optimize_names', []),
	('ufoz', False),
	('ufoz_compress', True),
	('designspace_export', False),
	('designspace_default', []),
	('vfb_save', False),
	('vfb_close', True),
	('force_overwrite', False),
	('report', True),
	('report_verbose', False),
	)

FILE_OPTIONS = {
	'features_file_path',
	'kern_feature_file_path',
	'groups_flc_path',
	'groups_plist_path',
	'afdko_makeotf_GOADB_path',
	}

PATH_OPTIONS = {
	'output_path',
	'afdko_makeotf_output_dir',
	'groups_export_flc_path',
	} | FILE_OPTIONS

INSTANCE_OPTIONS = {
	'instance_values',
	'instance_names',
	'instance_attributes',
	}

@cython.final
cdef class option_dict(dict):

	cdef dict value_types

	def __cinit__(self):
		self.value_types = {}
		self.set_default()

	def update(self, options):
		try:
			for key, value in items(options):
				if self[key] == value or value is None:
					continue
				value = check_option(self.value_types[key], key, value)
				if value is not None:
					PyDict_SetItem(self, key, value)
		except KeyError as e:
			raise KeyError(b"'%s' is an invalid option" % e.message)

	def set_default(self):
		for key, value in DEFAULT_OPTIONS:
			if isinstance(value, int) or key == 'layer' or key == 'kern_min_value':
				value_type = 'int'
			elif isinstance(value, list):
				value_type = 'list'
			elif value is None:
				value_type = 'str'
			elif isinstance(value, bool):
				value = int(value)
				value_type = 'bool'
			PyDict_SetItem(self, key, value)
			self.value_types[key] = value_type

	def __setattr__(self, key, value):
		PyDict_SetItem(self, key, value)

	def __getattr__(self, key):
		return self[key]

	def __reduce__(self):
		return self.__class__

def check_option(value_type, key, value):

	if value_type == 'list':
		if not isinstance(value, (tuple, list)):
			raise ValueError(b"'%s' must be a list or tuple" % key)
		if isinstance(value, tuple):
			value = list(value)
		if key == 'instance_attributes':
			value = [decode_dict(attrs) for attrs in value]
		return value

	if value_type == 'bool':
		if not isinstance(value, (bool, int)):
			raise ValueError(b"'%s' must be True, False, or integer values of one or zero." % key)
		if isinstance(value, bool):
			return int(value)
		return value

	if value_type == 'str':
		if not isinstance(value, basestring):
			raise ValueError(b"'%s' must be a byte- or unicode-string value." % key)
		if isinstance(value, bytes):
			value = cp1252_unicode_str(value)
		if key in PATH_OPTIONS and not os.path.isabs(value):
			return None
		if key in FILE_OPTIONS and not os.path.isfile(value) and key != 'groups_export_flc_path':
			return None
		return os.path.realpath(os.path.normpath(value))

	if value_type == 'int':
		if isinstance(value, float):
			value = int(round(value))
		if not isinstance(value, int):
			raise ValueError(b"'%s' must be an integer." % key)
		return value
