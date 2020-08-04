# defaults.pxi

UFO_GLYPH_SETS = (
	('omit', None),
	('optimized', None),
	('bases', None),
	('latn', None),
	('cyrl', None),
	('grek', None),
	)

UFO_CODE_POINTS = (
	('optimize', None),
	)

UFO_MASTER = (
	('ifont', None),
	('filename', None),
	('dirname', None),
	('family_name', None),
	('version_major', None),
	('version_minor', None),
	('version', None),
	('axes_names', None),
	('axes_names_short', None),
	('upm', None),
	('font_style', None),
	('ot_prefix', ''),
	('ot_features', {}),
	('classes', []),
	('lookup_block', []),
	)

UFO_MASTER_COPY = (
	('ifont', None),
	)

UFO_INSTANCE = (
	('completed', None),
	('index', None),
	('ifont', None),
	('fontinfo', None),
	('name_records', None),
	('kerning', None),
	)

UFO_TIMES_TOTAL = (
	('start', 0.0),
	('glifs', 0.0),
	('groups', 0.0),
	('features', 0.0),
	('plists', 0.0),
	('kern', 0.0),
	('fontinfo', 0.0),
	('afdko', 0.0),
	)

UFO_TIMES_INSTANCE = (
	('total', 0.0),
	('glifs', 0.0),
	('features', 0.0),
	('plists', 0.0),
	('kern', 0.0),
	('fontinfo', 0.0),
	('afdko', 0.0),
	)

UFO_PLISTS = (
	('metainfo', None),
	('groups', None),
	('lib', None),
	('glyphs_contents', None),
	('layercontents', None),
	)

UFO_PATHS_INSTANCE_PLISTS = [
	('metainfo', None),
	('fontinfo', None),
	('groups', None),
	('kerning', None),
	('lib', None),
	('glyphs_contents', None),
	('layercontents', None),
	]

UFO_PATHS_INSTANCE_AFDKO = [
	('fontnamedb', None),
	('goadb', None),
	('makeotf_cmd', None),
	]

UFO_PATHS_INSTANCE_PSAUTOHINT = [
	('psautohint_cmd', None),
	]

UFO_PATHS_INSTANCE = [
	('ufo', None),
	('ufoz', None),
	('vfb', None),
	('otf', None),
	('features', None),
	('glyphs', None),
	] + UFO_PATHS_INSTANCE_PLISTS + UFO_PATHS_INSTANCE_AFDKO + UFO_PATHS_INSTANCE_PSAUTOHINT

UFO_PATHS_AFDKO = [
	('goadb', None),
	('makeotf_cmd', None),
	]

UFO_PATHS = [
	('out', None),
	('encoding', None),
	('GOADB', None),
	('flc', None),
	('groups_plist', None),
	('kern_feature', None),
	('designspace', None),
	('vfb', None),
	('vfbs', []),
	('psautohint_cmd', None),
	]

UFO_GROUPS = (
	('opentype', None), # {opentype_group_name: group_glyphs}
	('kerning', None), # {kern_group_name: (is_second_group, group_glyphs)}
	('all', None), # {group_name: group_glyphs}
	('kerning_fea', None),
	('imported', 0),
	('no_kerning', None),
	)

UFO_KERN = (
	('scaled', 0),
	('firsts', None), # set of first glyphs in a kerning pair
	('seconds', None), # set of second glyphs in a kerning pair
	('glyphs_len', None), # {group_name: len(group_glyphs_list)}
	('groups_no_kerning', None),
	('firsts_by_key_glyph', None),
	('seconds_by_key_glyph', None),
	('key_glyph_from_group', None), # {key_glyph: group_name}
	)

UFO_AFDKO_MAKEOTF = (
	('cmd', None),
	)

UFO_PSAUTOHINT = (
	('glyph_list', []),
	('glyph_omit_list', []),
	('cmd', None),
	)

UFO_DESIGNSPACE = (
	('default', None),
	('names', None),
	('values', None),
	('attrs', None),
	('sources', None),
	('instances', None),
	('glyphs_omit', None),
	)

UFO_BASE = [
	('start', None),
	('last', None),
	('scale', None),
	('encoding', None),
	('creator', 'com.spiratype'),
	('metainfo', None),
	('lib', None),
	('layercontents', None),
	('glyph_contents', None),
	('archive', None),
	('glyph_order', None),
	('GOADB', None),
	('glifs', None),
	('mark_classes', None),
	('mark_bases', None),
	('opts', None),
	('instance_values', None),
	('instance_names', None),
	('instance_attributes', None),
	('instance_paths', None),
	('build_masters', 0),
	('instances', None),
	('instance_from_master', 0),
	]

FILE_HEADERS = {
	'kern': b'feature kern {',
	'flc': b'%%FONTLAB CLASSES',
	}

FILE_HEADER_ERRORS = {
	'kern': "Provided kern feature does not begin with 'feature kern {'.",
	'flc': ("Provided .flc file is invalid.\n"
		"Valid .flc files begin with '%%FONTLAB CLASSES'."),
	}
