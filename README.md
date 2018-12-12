## Description
Multiple master-compatible UFO writer API for Windows FontLab 5.2

vfb_ufo3 is primarily intended to create scaled UFOs from a > 1000 upm multiple master .vfb font. Hinting output is optional; as of psautohint v1.7, psautohint rounds all coordinates to integers, negating the lossless scaling performed during UFO creation. The most significant non-trivial change that will occur in export is the renaming of kerning glyph groups ('classes' in FontLab). See **kerning group options** below.

## Requirements
This module is written in Python 3 syntax when possible and Python 2 elsewhere. The submodules are written in Cython and compiled into .pyd extension modules for increased execution speed on par with FontLab's 'vfb2ufo' command line program. To recompile the submodules, PyPi packages 'future_fstrings' and 'cython' will need to be installed, as well as a C compiler compatible with Cython. The TDM build GCC compiler (version 4.3.3) located at the url below was used to compile the submodules and is known to work with Windows FontLab 5.2.

Windows GCC (MinGW) 4.3.3

https://github.com/develersrl/gccwinbinaries

## Functionality
UFO output is produced without changes to the source font. A copy will be created and the UFO will be processed from the copy. If the font is multiple master, instances will be generated from the copy. In the multiple master-use case, if 'instance_values' or a specific master layer is not provided, a UFO will be generated for each master in the font. The generated instances/layers can be saved and/or left open after generation via the 'vfb_save' and 'vfb_close' arguments. If an output path is provided, it must be an absolute path, otherwise the output will be saved to the user's Desktop. A dictionary of attributes may be suppled via the 'instance_attributes' argument. These attributes should consist of keys from the UFO specification and they must match the data type in the specification. If it is a scalable font metric and the font is being scaled, the unscaled value should be supplied. Any attribute in the dictionary will be updated in the generated vfb instance if it is mappable to a FontLab attribute.

### Example UFO generation script
```
#FLM: write ufo
# coding: utf-8

import os

from vfb_ufo3 import write_ufo

path = os.path.join('C:', 'Users', 'username', 'Documents', 'fonts')

font = fl.font

instances = [
	[0],
	[200],
	[400],
	[650],
	[1000],
	]
names = [
	['Thin'],
	['Light'],
	['Regular'],
	['SemiBold'],
	['Bold'],
	]
attributes = [
	{'openTypeOS2WeightClass': 200},
	{'openTypeOS2WeightClass': 300},
	{'openTypeOS2WeightClass': 400},
	{'openTypeOS2WeightClass': 600},
	{'openTypeOS2WeightClass': 700},
	]

write_ufo(
	font,
	path=path,
	instance_values=instances,
	instance_names=names,
	instance_attributes=attributes,
	decompose_glyphs=True,
	remove_glyph_overlaps=True
	)
```

## Options
Lossless glyph scaling
Compressed UFO output (direct-to-disk UFOZ)
features.fea table additions (AFDKO)
MakeOTF parts/batch command (AFDKO)
OpenType and kerning group import to features.fea

## Kerning options
Kern values will be scaled in parity with the output UFO. The values will be changed in the generated vfb instance during generation and reverted if the vfb is being saved.

## 'kern' feature options
A feature file with the 'kern' feature can be imported to the font features using the 'features_kern_feature_file' argument, which expects a path to a text file with the .fea extension. The 'features_kern_feature_omit' and 'features_kern_feature_passthrough' arguments allow for 'kern' feature omission and 'kern' feature pass-through, respectively. A new 'kern' feature can be generated setting 'features_kern_feature_generate' to True. The 'kern' feature generation utilises FontLab's MakeKernFeature() command with additional subtables and a lookup as necessary. This is not particularly elegant, and no checks are made to guarantee a working 'kern' feature. Any remaining subtable overflows may be due to glyph(s) being in more than one kern group of the same side, however overflows can also be caused by issues from one or more GPOS features located earlier in the feature list.

## Group options
Optionally, a FontLab-class file (.flc) or groups.plist may be provided. Group names will be normalized to match the UFO3 kern group naming scheme. If the imported groups.plist contains kern group names that do not follow the @MMK- or public.kern- prefixes, or the key glyphs from the imported .flc file do not match the master font key glyphs, the font's kerning will very likely no longer remain functional. Providing a FontLab-class file or groups.plist file is considerably faster than using FontLab's builtin methods.

Setting the 'export_flc' argument to True will produce an .flc file on the desktop that matches the group names of the generated UFOs.

## Kerning group options
For portability and uniformity, kerning glyph groups will be renamed to match the UFO3 specification for both UFO2 and UFO3 exports. Combined left/right FL classes will be split into separate groups.

If there are any FL kern classes without a key glyph in a provided .flc file or in the master font's kern classes, the first glyph in the FL class will be marked as the key glyph and it will be noted in the output console. This may affect the kerning.

#### Kern group naming recommendations
```
  FontLab-style kerning groups:
  _A_l: A' Agrave Aacute Acircumflex Atilde Adieresis Aring...
  _A_r: A' AE Agrave Aacute Acircumflex Atilde Adieresis Aring...

  Working output:
  _public.kern1.A: A' Agrave Aacute Acircumflex Atilde Adieresis Aring...
  _public.kern2.A: A' AE Agrave Aacute Acircumflex Atilde Adieresis Aring...

  Final output:
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

## Glyph options
Glyph decomposition and overlap removal is optional and occurs after instances are generated. This option is intended for final output when a binary font will be created from the UFO.

#### Omit glyphs from instance
A list of glyph names and/or glyph suffixes can be supplied that should be omitted from the instance UFO via the 'glyphs_omit_list' and 'glyphs_omit_suffixes_list' arguments.

## Hinting options
All glyph hints may be omitted by setting 'hints_ignore' to True and vertical hints may be omitted by setting 'hints_ignore_vertical' to True. All hint operations occur after glyph decomposition/overlap removal (if they are set). Glyph links are converted to hints after instance generation. If vertical hints were in the original hint replacement list, the replacement list is reset by FontLab during removal. FontLab's builtin hint replacement can be run during generation by setting 'hints_autoreplace' to True. Setting 'hints_afdko' to True will build hints compatible with MakeOTF.

## AFDKO options
GlyphOrderAndAliasDB (GOADB) and FontMenuNameDB files can be generated for use with MakeOTF. The GOADB can be generated using a provided GOADB file path, derived from the FL font's encoding, or the order of the source font. Optionally, the first 256 characters can be filled from the Windows 1252 or Mac OS Roman codepages. The first character of a generated GOADB file will always start with the '.notdef' glyph. The OS/2, hhea, head, and name tables will be added to the features file. If a GOADB file is provided, it is not checked for correctness. A batch command to run MakeOTF for each generated instance or all instances using the arguments 'afdko_makeotf_cmd' and 'afdko_makeotf_batch_cmd', respectively.

  # FDK arguments
  There are several explicit keyword agruments to enable specific makeotf switches. For those not available via a keyword agrument, they should be defined as a list of strings and passed to the 'afdko_args' argument.

## UFOZ options
UFOs can be written as a .ufoz archive. By default, the archive is written in compressed mode. Setting 'ufoz_compress' to False will write an uncompressed .ufoz.

## Designspace document options
A .designspace document can be created in lieu of individual instances. A UFO for each master will be generated and the instances will be described in the .designspace document.

## Notes
Generally, no assumptions are made about the correctness of the input. Glyph name errors are noted in the output window. In the case of 'afdko_release' mode, glyph name errors will raise an exception and UFO generation will not continue. Other errors in font will likely be passed through to the UFO.
