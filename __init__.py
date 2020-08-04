# coding: utf-8
from __future__ import absolute_import, unicode_literals, print_function

import gc
import os

resources_path = os.path.join(os.path.dirname(__file__), 'resources')
if resources_path not in os.environ['PATH']:
	os.environ['PATH'] += '%s;' % resources_path

from . import core

show_default_optimize_code_points = core.show_default_optimize_code_points

__version__ = '0.7.2'
__doc__ = """
VFB2UFO3
DESCRIPTION
Multiple master-compatible Unified Font Object (UFO) version 3 font writer API
for Windows FontLab 5.2

VFB2UFO3 is primarily intended to create scaled UFO instances from a > 1000 UPM
multiple master FontLab `.vfb` font with PostScript outlines for use with the
AFDKO tools for creating binary fonts while still working with Windows FontLab
5.2. The most significant non-trivial change that will occur in export is the
renaming of kerning glyph groups (FontLab classes). Providing a `.flc`
(FontLab-class) file can speed up conversion significantly when font groups are
not identifiable as first/second from their name. All glyph hints/links are
ignored. A batch command can be created for use with `psautohint`, which
supports hinting outlines with decimal coordinates.

INSTALLATION
PyPi
`pip install vfb2ufo3`

FontLab Installer
Download the lastest release FontLab installer (`.flw`) file and drag it into
the FontLab main window then restart FontLab or reset macro system.

ZIP Archive
Download and extract the latest release `.zip` file and move the extracted
files to your FontLab Macros folder. The default directory structure is shown
below.


```
[user folder]
    └── Documents
        └── Fontlab
            └── Studio 5
                └── Macros
                    └── System
                        └── Modules
                            └── vfb2ufo3
                                ├── resources
                                │   ├── libgcc_s_dw2-1.dll
                                │   ├── libgomp-1.dll
                                │   ├── libstdc++-6.dll
                                │   ├── libwinpthread-1.dll
                                │   └── zlib1.dll
                                ├── __init__.py
                                ├── core.pyd
                                ├── designspace.pyd
                                ├── fdk.pyd
                                ├── fea.pyd
                                ├── fontinfo.pyd
                                ├── glif.pyd
                                ├── groups.pyd
                                ├── kern.pyd
                                ├── mark.pyd
                                ├── plist.pyd
                                ├── tools.pyd
                                ├── user.py
                                └── vfb.pyd
```

REQUIREMENTS
This package has no Python dependencies outside of the standard library. It is
written in C++ and Cython. The submodules are compiled into `.pyd` extension
modules. To recompile the submodules, the PyPi `cython` package and a compiler
for Cython to utilize during extension module compilation will be required.

The some extension modules compiled from C++ require several DLLs included in
the release `.zip` archive, FontLab installer, and PyPi package.

OPTIONAL
  cython
  pip install cython
  https://github.com/cython/cython

  AFDKO
  pip install afdko
  https://github.com/adobe-type-tools/afdko

  MinGW 32-bit/i686 GCC >= 9.3.0
  http://winlibs.com
  https://www.msys2.org
  http://mingw.org

FUNCTIONALITY
UFO output is produced without changes to the source font. The source font will
be copied and UFOs will be created from the copy. If the font is multiple
master, instances will be generated from the copy. If a specific `layer` or
`instance_values` are not provided for a multiple master source font, a UFO
will be generated for each master in the font.

Fonts with a large number of glyphs benefit greatly from supplying additional
glyph names to be optimized when removing overlaps (`glyphs_optimize_names`)
and/or glyph names and suffixes which can be omitted from the final UFO
instance (`glyphs_omit_names`, `glyphs_omit_suffixes`). See GLYPHS OPTIONS
below.

Generated instances/layers can be saved and/or left open after generation via
the `vfb_save` and `vfb_close` options. If `vfb_save` is set to `True`, the
resulting `.vfb` instance will be updated during UFO creation. This includes
glyph outline changes (overlap removal and decomposition).

All path options must be absolute paths; folder and file paths which are not
absolute will be ignored. The default output path is the user's Desktop.

A dictionary of attributes may be suppled via the `instance_attributes` option.
These attributes should consist of keys from the UFO specification and they
must match the data type in the specification. Not all fontinfo attributes are
configurable; please see `CONFIGURABLE_ATTRS` in the `fontinfo.pxi` source file
for a list of attributes which will be checked and updated to the UFO(s) during
creation.


```
-------------------------------------------------------------------------------
EXAMPLE UFO GENERATION SCRIPT FOR SINGLE-AXIS MULTIPLE MASTER .VFB FONT
-------------------------------------------------------------------------------
#FLM: write ufo
# coding: utf-8
from __future__ import absolute_import, unicode_literals

import os

from vfb2ufo3 import write_ufo

user_profile_folder = os.environ['USERPROFILE']
output_path = os.path.join(user_profile_folder, 'Documents', 'test_font')

instances = [
	0,
	200,
	400,
	650,
	1000,
	]
names = [
	'Thin',
	'Light',
	'Regular',
	'SemiBold',
	'Bold',
	]
attributes = [
	{'openTypeOS2WeightClass': 200},
	{'openTypeOS2WeightClass': 300},
	{'openTypeOS2WeightClass': 400},
	{'openTypeOS2WeightClass': 600},
	{'openTypeOS2WeightClass': 700},
	]

write_ufo(
	output_path=output_path,
	instance_values=instances,
	instance_names=names,
	instance_attributes=attributes,
	glyphs_decompose=True,
	glyphs_remove_overlaps=True,
	)

-------------------------------------------------------------------------------
```

SCALE OPTIONS
By default, the target UPM for UFO output is 1000. For a UPM other than 1000,
say 2048, it should be set via the `scale_to_upm` option. The value from the
`scale_to_upm` option is ignored if it is lower than 1000. Scaling can be
turned off by setting `scale_auto` to `False`; this does not reduce conversion
times.

All scaling operations are performed independently from FontLab; if the `.vfb`
instance(s)/master copy are being saved, the `.vfb` font and glyph values will
be the original un-scaled values.

INSTANCE OPTIONS
When creating instances from a multiple master source font, lists of values,
names (optional), and attributes (optional) should be provided to generate
instance UFOs from the master font.

If the source is a multiple master font and a list of instance values is not
provided, a UFO for each master will be created.

For multiple master fonts, the instance values list should be values in
`tuple`- or `list`-form with a value for each axis. For single-axis fonts, if
the list values are numerical, the values will be converted to single-element
lists:

2-axis font
  `instance_values = [[0, 1000], [200, 1000]]`

  `instance_values = [(0, 1000), (200, 1000)]`

1-axis font
  `instance_values = [[0], [200]]`

  `instance_values = [(0,), (200,)]`

  `instance_values = [0, 200]` becomes `[[0], [200]]`

If the optional lists of names and/or attributes are provided in addition to a
list of values, they must be of the same length as the values list. A
`ValueError` will be raised if the lengths do not match, since this will likely
produce undesirable results:

Correct:

```
instance_values = [(0, 1000), (200, 1000)]
instance_names = ['Light Display', 'Regular Display']
```

Incorrect (`ValueError`):

```
instance_values = [(0, 1000), (200, 1000)]
instance_names = ['Light Display']
```

GLYPH OPTIONS
Glyph scaling is independent from the `.vfb` instance itself; if the `.vfb`
instance is being saved, the glyphs in the `.vfb` will remain un-scaled.

Glyph decomposition and overlap removal is optional and occurs after instances
are generated. This option is intended for final output when a binary font will
be created from the UFO.

By default, when decomposing and removing overlaps from glyph outlines for
export, GLIF files for glyphs containing components will be built using
contours from each component's base contours.

When decomposing only, the optimization outlined above will be used for all
glyphs containing components.

The generated `.vfb` instance(s) will leave components in component-form.

To disable the optimizations outlined above, set the `glyphs_optimize` option
to `False`.

Omit glyphs from instance
  A list of glyph suffixes and/or glyph names can be supplied that should be
  omitted from the instance UFO via the `glyphs_omit_suffixes` and
  `glyphs_omit_names` options, respectively.

Optimize glyph name and code point lists
  If removing overlaps, the default list of code points for glyphs to be
  constructed in the above manner is composed of glyphs that normally have no
  overlapping components. The list is located in the `ufo.pxi` source file with
  the character representations for these code points shown below.

  The code points from the default code point list can be shown by running the
  `vfb2ufo3.show_default_optimize_code_points()` function. The code points will
  print to the FontLab output window and can then be copied into a text editor
  and edited as needed.

  A user-supplied code point list (`glyphs_optimize_code_points`) can be a list
  of `'0x00ac'`-format strings, integers in hexadecimal-form (`0x00ac`), or
  numeric integers (`172`); values which cannot be converted to an integer will
  raise a `ValueError`. Only the first code point in each glyph's list of code
  points (FontLab unicodes attribute) is checked for code point set membership.

  A user-supplied glyph name list (`glyphs_optimize_names`) can be supplied to
  supplement the code point list for glyphs. Any glyphs containing components
  that do not overlap should be added to this list.

  Small case variants of the code points in the code point list will be also
  added to code point list assuming they end with `.sc`, `.smcp`, or `.c2sc`
  suffixes.

`OPTIMIZE_CODE_POINTS`

```
Latin
À Á Â Ã Ä Ā Ă Ǣ Ǽ Ȁ Ȃ Ǎ Ȧ
Ḇ
Ć Ĉ Ċ Č
Ď Ḍ Ḏ Ḓ
È É Ê Ë Ē Ĕ Ė Ė Ȅ Ȇ
Ĝ Ğ Ġ Ģ Ḡ Ǧ Ǵ
Ĥ Ḥ Ḫ
Ì Í Ĩ Ī Ĭ İ Î Ï Ȉ Ȋ Ǐ
Ĵ
Ķ Ḳ Ḵ
Ĺ Ļ Ľ Ŀ Ḷ Ḹ Ḻ Ḽ
Ḿ Ṁ Ṃ
Ñ Ń Ņ Ň Ṅ Ṇ Ṉ Ṋ Ǹ
Ò Ó Ô Õ Ö Ō Ŏ Ő Ȍ Ȏ Ȯ Ǒ
Ŗ Ř Ŕ Ṙ Ṛ Ṝ Ṟ Ȑ Ȓ
Ś Ŝ Ş Ș Š Ṣ
Ţ Ț Ť Ṭ Ṯ Ṱ
Ũ Ū Ŭ Ů Ű Ù Ú Û Ü Ȕ Ȗ Ǔ Ǖ Ǘ Ǚ Ǜ
Ṿ
Ŵ Ẁ Ẃ Ẅ Ẇ
Ẋ Ẍ
Ŷ Ÿ Ý Ẏ Ȳ
Ź Ż Ž Ẑ Ẓ Ẕ
Ĳ Ǉ Ǌ ǈ ǋ
Ǳ Ǆ ǲ ǅ
à á â ã ä ā ă ǣ ǽ ȁ ȃ ǎ ȧ
ḇ
ć ĉ ċ č
ď ḍ ḏ ḓ
è é ê ë ē ĕ ė ě ȅ ȇ
ĝ ğ ġ ģ ḡ ǧ ǵ
ĥ ẖ ḥ ḫ
ì í ĩ ī ĭ î ï ȉ ȋ ǐ
ĵ ǰ
ķ ḳ ḵ
ĺ ļ ľ ŀ ḷ ḹ ḻ ḽ
ḿ ṁ ṃ
ń ņ ň ŉ ñ ṅ ṇ ṉ ṋ ǹ
ò ó ō ŏ ő ô õ ö ȍ ȏ ȯ ǒ
ŗ ř ŕ ṙ ṛ ṝ ṟ ȑ ȓ
ś ŝ ş ș š ṣ
ţ ț ť ṭ ṯ ṱ
ũ ū ŭ ů ű ù ú û ü ȕ ȗ ǔ ǖ ǘ ǚ ǜ
ṿ
ŵ ẁ ẃ ẅ ẇ
ẋ ẍ
ý ÿ ŷ ẏ ȳ
ź ż ž ẑ ẓ ẕ
ĳ ǉ ǌ
ǳ ǆ

Cyrillic
Ѓ Ќ Ѝ Й Ӣ Ӥ Ў Ӝ Ӂ Ѐ Ё Ӗ Ӟ Ѷ Ә Ӛ Ѕ І Ї Ј Ӑ Ӓ Ӕ Ӧ Ӯ Ӱ Ӳ Ӵ Ӹ Ӏ Ӏ
ѓ ќ ѝ й ӣ ӥ ў ӝ ӂ ѐ ё ӗ ӟ ѷ ә ӛ ѕ і ї ј ӑ ӓ ӕ ӧ ӯ ӱ ӳ ӵ ӹ

Greek Mono- and Polytonic
Ἀ Ἁ Ἂ Ἃ Ἄ Ἅ Ἆ Ἇ ᾈ ᾉ ᾊ ᾋ ᾌ ᾍ ᾎ ᾏ Ᾰ Ᾱ Ὰ Ά ᾼ
Ἐ Ἑ Ἒ Ἓ Ἔ Ἕ Ὲ Έ
Ἠ Ἡ Ἢ Ἣ Ἤ Ἥ Ἦ Ἧ ᾘ ᾙ ᾚ ᾛ ᾜ ᾝ ᾞ ᾟ Ὴ Ή ῌ
Ἰ Ἱ Ἲ Ἳ Ἴ Ἵ Ἶ Ἷ Ῐ Ῑ Ὶ Ί
Ὀ Ὁ Ὂ Ὃ Ὄ Ὅ Ὸ Ό
Ῥ
Ὑ Ὓ Ὕ Ὗ Ῠ Ῡ Ὺ Ύ
Ὠ Ὡ Ὢ Ὣ Ὤ Ὥ Ὦ Ὧ ᾨ ᾩ ᾪ ᾫ ᾬ ᾭ ᾮ ᾯ Ὼ Ώ ῼ
ἀ ἁ ἂ ἃ ἄ ἅ ἆ ἇ ᾀ ᾁ ᾂ ᾃ ᾄ ᾅ ᾆ ᾇ ᾰ ᾱ ᾲ ᾳ ᾴ ᾶ ᾷ ὰ ά
ἐ ἑ ἒ ἓ ἔ ἕ ὲ έ
ἠ ἡ ἢ ἣ ἤ ἥ ἦ ἧ ᾐ ᾑ ᾒ ᾓ ᾔ ᾕ ᾖ ᾗ ῂ ῃ ῄ ῆ ῇ ὴ ή
ἰ ἱ ἲ ἳ ἴ ἵ ἶ ἷ ῐ ῑ ῒ ΐ ῖ ῗ ὶ ί
ὀ ὁ ὂ ὃ ὄ ὅ ὸ ό
ῤ ῥ
ὐ ὑ ὒ ὓ ὔ ὕ ὖ ὗ ῠ ῡ ῢ ΰ ὺ ύ ῦ ῧ
ὠ ὡ ὢ ὣ ὤ ὥ ὦ ὧ ᾠ ᾡ ᾢ ᾣ ᾤ ᾥ ᾦ ᾧ ῲ ῳ ῴ ῶ ῷ ὼ ώ
```

Features options
Font groups can be added to the `features.fea` file on export by setting
`features_import_groups` to `True`. The font's features are neither formatted
nor checked for correctness. Users are responsible for moving referenced
feature files from `include()` statements to the chosen output directory. Also
see KERN FEATURE OPTIONS and MARK FEATURE OPTIONS below for `kern` and `mark`
feature options.

Kern feature options
Kern values will be scaled in parity with the output UFO. This scaling is
independent from the created `.vfb` instance. A minimum value can be set using
`kern_min_value`. This value should be a positive integer and when set, all
kern values (negative and positive) not above the threshold will be omitted
from the `kern` feature.

By default, the `kern` feature from the master font is not included in the
`features.fea` file. To include the `kern` feature from the master font,
`kern_feature_passthrough` should be set to `True`.

An external feature file with a `kern` feature can be imported to the font
features using the `kern_feature_file_path` option, which expects a path to a
text file with the `.fea` extension.

By default, a new `kern` feature is generated for each instance. Setting
`kern_feature_generate` to `False` will turn this off. The `kern` feature
generation will add subtables and a lookup as necessary. This is not
particularly elegant, and so far, no checks are made to guarantee a working
`kern` feature. Any remaining subtable overflows may be due to glyph(s) being
in more than one kern group of the same side; however overflows can also be
caused by issues from one or more `GPOS` features located earlier in the
feature list.

Mark feature options
A `mark` feature can be generated on export by setting `mark_feature_generate`
to `True`. A list of anchor names to omit (`mark_anchors_omit`) or a list of
anchor names to include (`mark_anchors_include`) can be supplied to fine-tune
the `mark` feature output.

Group options
Providing a FontLab-class file (`.flc`) or `groups.plist` speeds up UFO
creation time significantly when the group names are not named using first and
second group identifiers (see `groups_flc_path` and `groups_plist_path`
options). Group names in the `.flc` file do not have match any specific
formatting (e.g. `MMK_R_<key glyph>`, `public.kern2.<key glyph>`).

When not using either a `.flc` or `groups.plist` file, group names will be
checked for UFO3-style group identifiers (`public.kern1.<key glyph>`,
`public.kern2.<key glyph>`), MetricsMachine-style identifiers (`MMK_L_<key
glyph>`, `MMK_R_<key glyph>`), and the simpler `_L` and `_R` identifier
suffixes. Groups which either have no kerning or are not identifiable using
their name will be identified as first/second using FontLab's built-in
`GetClassLeft`/`GetClassRight` methods.

If the `export_flc` option is set to `True`, a FontLab-class file (`.flc`) will
be generated with group names matching those of the generated UFOs. This file
will be located in the same directory as the generated UFO(s).

The `kern_ignore_no_kerning` option can be set to `True` to ignore groups which
have no kerning pairs. This may be desirable if making a binary font from the
UFO. This option has no effect when using an imported `.flc` or `groups.plist`
file.

FontLab kern classes without a key glyph in a provided `.flc` file or in the
master font's kern classes will have the first glyph in the FontLab class
marked as the key glyph and it will be noted in the output console. If there is
more than one glyph marked as a key glyph, the first marked glyph is considered
the key glyph. These key glyph operations may affect the kerning. An imported
`groups.plist` infers that the glyph in the group name is the key glyph.

Kern group naming recommendations

```
Typical FontLab-style kerning groups:
_A: A' Agrave Aacute Acircumflex Atilde Adieresis Aring...
_A_r: A' AE Agrave Aacute Acircumflex Atilde Adieresis Aring...

Recommended naming for FontLab-style kerning groups:
_public.kern1.A: A' Agrave Aacute Acircumflex Atilde Adieresis Aring...
_public.kern2.A: A' AE Agrave Aacute Acircumflex Atilde Adieresis Aring...

Final output (UFO groups.plist):
<key>public.kern1.A</key>
<array>
	<string>A</string>
	<string>Agrave</string>
	<string>Aacute</string>
	<string>Acircumflex</string>
	<string>Atilde</string>
	<string>Adieresis</string>
	<string>Aring</string>
	...
</array>

<key>public.kern2.A</key>
<array>
	<string>A</string>
	<string>AE</string>
	<string>Agrave</string>
	<string>Aacute</string>
	<string>Acircumflex</string>
	<string>Atilde</string>
	<string>Adieresis</string>
	<string>Aring</string>
	...
</array>
```

AFDKO options
The `OS/2`, `hhea`, `head`, and `name` tables will be added to the features
file. The `name` table entry strings will be formatted according to OpenType
Feature File Specification § 9.e. Any strings unable to be formatted fully for
each platform's specific encoding restriction (Windows -- `UTF-8`, Macintosh --
`Mac Roman`) will be formatted to their nearest ASCII equivalent rather than
omitting any un-encodable characters. The standard library `unicodedata` module
is used for any entries meeting this criteria.

GlyphOrderAndAliasDB (GOADB) and FontMenuNameDB files can be generated for use
with MakeOTF. The GOADB can be provided (`afdko_makeotf_GOADB_path`), derived
from the `.vfb`'s original encoding, or the order of the source font.

Optionally, the first 256 glyphs can be filled from the `Windows-1252` or `Mac
OS Roman` code pages (`afdko_makeotf_GOADB_win1252`,
`afdko_makeotf_GOADB_macos_roman`). The first character of a generated GOADB
file will always start with the `.notdef` glyph. If a GOADB file is provided,
it is not checked for correctness. Commands to run MakeOTF for each generated
instance separately or all instances as a batch using the options
`afdko_makeotf_cmd` and `afdko_makeotf_batch_cmd`, respectively.

There are several explicit keyword options to enable specific MakeOTF switches.
For those not available via a keyword option, they should be defined as a list
of strings and passed to the `afdko_makeotf_args` option.

psautohint options
`psautohint` can be utilized for generating glyph hints after UFO generation.
Commands to run `psautohint` for each generated instance separately or all
instances as a batch using the options `psautohint_cmd` and
`psautohint_batch_cmd`, respectively. The default options are `-d` (write
decimal (float) hint coordinates) and `-w` (write hints directly to the .glif
lib for each glyph).

UFOZ options
UFO instances can be written as a `.ufoz` archive. If you are planning on any
file transfer operations after creation, transferring a single `.ufoz` file is
much quicker than the large number of small text files in the generated UFO
instance(s), especially when transferring through USB. By default, archives are
written in compressed mode. Compression can be turned off by setting
`ufoz_compress` to `False`.

`.designspace` font options
A `.designspace` document can be created in place of individual UFO instances.
A UFO for each master will be generated and the instances will be described in
the `.designspace` document. A default instance can be described with the
`designspace_default` option. This value must be a list or tuple with a value
for each axis in the font. If `glyphs_omit_list` or `glyphs_omit_suffixes_list`
lists are provided, the glyphs will remain in the source UFOs and a glyph mute
rule for each glyph to be omitted will be added for each instance.

Benchmarks
For reference, testing was performed on a Windows 10 machine with an Intel Xeon
E5 1650v3 @ 3.5 GHz CPU and a solid-state hard drive; CPUs with fewer cores
and/or a hard disk drive increases file write times considerably.

Times are per-instance (±.5 sec) and do not include time to load and parse user
options, then copy the original font and prepare the copy for conversion to the
UFO format. This prep time increases when not providing a FontLab-class
(`.flc`) or `groups.plist` file.

The `ufoz` option reduces build time considerably.

Test (~3200 glyphs @ 10,000 UPM -> 1,000 UPM), <10 sec

```
flc_path = <path to .flc file>

vfb2ufo3.write_ufo(
	glyphs_decompose=True,
	glyphs_remove_overlaps=True,
	groups_flc_path=flc_path,
	)
```

Test (~2900 glyphs @ 10,000 UPM -> 1,000 UPM), ≈9 sec

```
flc_path = <path to .flc file>
glyphs_omit_list = [
	<glyph names to be omitted go here>
	]
glyphs_omit_suffixes_list = [
	<glyph name suffixes to be omitted go here>
	]

vfb2ufo3.write_ufo(
	glyphs_decompose=True,
	glyphs_remove_overlaps=True,
	glyphs_omit_list=glyphs_omit_list,
	glyphs_omit_suffixes_list=glyphs_omit_suffixes_list,
	groups_flc_path=flc_path,
	)
```

Test (~2900 glyphs @ 10,000 UPM -> 1,000 UPM), ≈7 sec

```
flc_path = <path to .flc file>
glyphs_optimize_names = [
	<glyph names with no overlapping components go here>
	]
glyphs_omit_list = [
	<glyph names to be omitted go here>
	]
glyphs_omit_suffixes_list = [
	<glyph name suffixes to be omitted go here>
	]

vfb2ufo3.write_ufo(
	glyphs_decompose=True,
	glyphs_remove_overlaps=True,
	glyphs_optimize_names=glyphs_optimize_names,
	glyphs_omit_list=glyphs_omit_list,
	glyphs_omit_suffixes_list=glyphs_omit_suffixes_list,
	groups_flc_path=flc_path,
	)
```

Test (~2900 glyphs @ 10,000 UPM -> 1,000 UPM), ≈4 sec

```
flc_path = <path to .flc file>
vfb2ufo3.write_ufo(
	glyphs_decompose=True,
	groups_flc_path=flc_path,
	)
```

Test (~2900 glyphs @ 10,000 UPM -> 1,000 UPM), ≈3-4 sec

```
flc_path = <path to .flc file>
glyphs_omit_list = [
	<glyph names to be omitted go here>
	]
glyphs_omit_suffixes_list = [
	<glyph name suffixes to be omitted go here>
	]

vfb2ufo3.write_ufo(
	glyphs_decompose=True,
	glyphs_omit_list=glyphs_omit_list,
	glyphs_omit_suffixes_list=glyphs_omit_suffixes_list,
	groups_flc_path=flc_path,
	)
```

Test (~3200 glyphs @ 10,000 UPM -> 1,000 UPM), ≈3 sec

```
flc_path = <path to .flc file>

vfb2ufo3.write_ufo(
	groups_flc_path=flc_path,
	)
```

Test (~3200 glyphs @ 10,000 UPM -> 1,000 UPM), <1.5 sec

```
flc_path = <path to .flc file>

vfb2ufo3.write_ufo(
	groups_flc_path=flc_path,
	ufoz=True,
	)
```

Test (~3200 glyphs @ 10,000 UPM -> 1,000 UPM), <1.5 sec

```
flc_path = <path to .flc file>

vfb2ufo3.write_ufo(
	groups_flc_path=flc_path,
	ufoz=True,
	ufoz_compress=False,
	)
```

Notes
Generally, no assumptions are made about the correctness of the input. When
`adfko_makeotf_release` mode is set, glyph name errors will raise an exception
and UFO generation will not continue. Glyph name checks are made prior to
building instances. Other errors in the original font will likely be passed
through to the UFO.

Author
Jameson R Spires

License
Source files are covered under the MIT License.

Version history
version 0.7.2
reorganization of `.pxi` includes
removal of `.pxd` Cython declaration files
incorporated automatic string encoding from Python to C/C++
more explicit Python string encoding/decoding

version 0.7.1
changes to `.ufoz` C++ code

version 0.7.0
additional C++ conversion for `.ufoz` file creation utilizing zlib compression
small changes and corrections

version 0.6.6
change to `setup.py` for PyPi package
created FontLab installer

version 0.6.5
change to `glif.hpp`

version 0.6.4
remove schedule from OpenMP pragma
correction for quadratic curves in `glif.pyx`
correction for `glif` file name creation

version 0.6.3
added 32-bit GCC DLLs
C++ string formatting improved utilizing {fmt} formatting library
`mark` feature generation corrections
small changes and corrections

version 0.6.2
replaced `push_back` with `emplace_back` where possible in `glif.hpp`
corrections to shifted and scaled contour-from-component builds

version 0.6.1
small corrections

version 0.6.0
small fix for single-master font builds
small changes to several source files
`glif.pyx` has been rewritten in C++ as much as possible

version 0.5.2
small change to `groups.pyx`
re-added link to known working GCC compiler

version 0.5.1
majority of code base rewritten
support for UFO3 specification only
considerable improvement in UFO creation times
corrected UFOZ build structure
removed hint operations, added psautohint batch command options
improved option handling
improved group conversion
native `kern` and `mark` feature generation

version 0.3.1
updated sample script

version 0.3.0
additional documentation
slight improvement in glif and .glif file creation times
added sample benchmark times

version 0.2.0
minor formatting
change to plistlib for groups.plist import
removed commented lines in `__init__.py`
added `futures` package as a required package
added module to PyPi

version 0.1.0
initial release
"""

def cleanup():
	gc.collect()
	del gc.garbage[:]

def write_ufo(
	output_path=None,

	layer=None,

	scale_to_upm=1000,
	scale_auto=True,

	instance_values=[],
	instance_names=[],
	instance_attributes=[],

	features_import_groups=False,

	kern_feature_generate=True,
	kern_feature_file_path=None,
	kern_feature_passthrough=False,
	kern_min_value=None,

	mark_feature_generate=False,
	mark_anchors_include=[],
	mark_anchors_omit=[],

	groups_export_flc=False,
	groups_export_flc_path=None,
	groups_flc_path=None,
	groups_plist_path=None,
	groups_ignore_no_kerning=False,

	afdko_parts=False,
	afdko_makeotf_cmd=False,
	afdko_makeotf_batch_cmd=False,
	afdko_makeotf_output_dir=None,
	afdko_makeotf_GOADB_path=None,
	afdko_makeotf_GOADB_win1252=True,
	afdko_makeotf_GOADB_macos_roman=False,
	afdko_makeotf_release=False,
	afdko_makeotf_subroutinization=True,
	afdko_makeotf_no_subroutinization=False,
	afdko_makeotf_sans=False,
	afdko_makeotf_serif=False,
	afdko_makeotf_replace_notdef=False,
	afdko_makeotf_verbose=False,
	afdko_makeotf_addDSIG=True,
	afdko_makeotf_suppress_unhinted_glyph_warnings=True,
	afdko_makeotf_args=[],

	psautohint_cmd=False,
	psautohint_batch_cmd=False,
	psautohint_write_to_default_layer=True,
	psautohint_decimal=True,
	psautohint_allow_outline_changes=False,
	psautohint_no_flex=False,
	psautohint_no_hint_substitution=False,
	psautohint_no_zones_stems=False,
	psautohint_log=False,
	psautohint_report_only=False,
	psautohint_verbose=False,
	psautohint_extra_verbose=False,
	psautohint_glyphs_list=[],
	psautohint_glyphs_omit_list=[],

	glyphs_decompose=False,
	glyphs_remove_overlaps=False,
	glyphs_omit_names=[],
	glyphs_omit_suffixes=[],
	glyphs_optimize=True,
	glyphs_optimize_code_points=[],
	glyphs_optimize_names=[],

	ufoz=False,
	ufoz_compress=True,

	designspace_export=False,
	designspace_default=[],

	vfb_save=False,
	vfb_close=True,

	force_overwrite=False,

	report=True,
	report_verbose=False,
	):

	options = core.decode_dict(locals())
	core.write_ufo(options)
	cleanup()

