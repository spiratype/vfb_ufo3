# features.pxi

OMIT_NIDS = {1, 2, 3, 4, 6}

CODE_PAGES = {
  0: 1252,
  1: 1250,
  2: 1251,
  3: 1253,
  4: 1254,
  5: 1255,
  6: 1256,
  7: 1257,
  8: 1258,
  16: 874,
  17: 932,
  18: 936,
  19: 949,
  20: 950,
  21: 1361,
  48: 869,
  49: 866,
  50: 865,
  51: 864,
  52: 863,
  53: 862,
  54: 861,
  55: 860,
  56: 857,
  57: 855,
  58: 852,
  59: 775,
  60: 737,
  61: 708,
  62: 850,
  63: 437,
  }

FEATURES = {
  'aalt': 'Access All Alternates',
  'abvf': 'Above-base Forms',
  'abvm': 'Above-base Mark Positioning',
  'abvs': 'Above-base Substitutions',
  'afrc': 'Alternative Fractions',
  'akhn': 'Akhands',
  'blwf': 'Below-base Forms',
  'blwm': 'Below-base Mark Positioning',
  'blws': 'Below-base Substitutions',
  'calt': 'Contextual Alternates',
  'case': 'Case-Sensitive Forms',
  'ccmp': 'Glyph Composition / Decomposition',
  'cfar': 'Conjunct Form After Ro',
  'cjct': 'Conjunct Forms',
  'clig': 'Contextual Ligatures',
  'cpct': 'Centered CJK Punctuation',
  'cpsp': 'Capital Spacing',
  'cswh': 'Contextual Swash',
  'curs': 'Cursive Positioning',
  'c2pc': 'Petite Capitals From Capitals',
  'c2sc': 'Small Capitals From Capitals',
  'dist': 'Distances',
  'dlig': 'Discretionary Ligatures',
  'dnom': 'Denominators',
  'dtls': 'Dotless Forms',
  'expt': 'Expert Forms',
  'falt': 'Final Glyph on Line Alternates',
  'fin2': 'Terminal Forms #2',
  'fin3': 'Terminal Forms #3',
  'fina': 'Terminal Forms',
  'flac': 'Flattened accent forms',
  'frac': 'Fractions',
  'fwid': 'Full Widths',
  'half': 'Half Forms',
  'haln': 'Halant Forms',
  'halt': 'Alternate Half Widths',
  'hist': 'Historical Forms',
  'hkna': 'Horizontal Kana Alternates',
  'hlig': 'Historical Ligatures',
  'hngl': 'Hangul',
  'hojo': 'Hojo Kanji Forms (JIS X 0212-1990 Kanji Forms)',
  'hwid': 'Half Widths',
  'init': 'Initial Forms',
  'isol': 'Isolated Forms',
  'ital': 'Italics',
  'jalt': 'Justification Alternates',
  'jp78': 'JIS78 Forms',
  'jp83': 'JIS83 Forms',
  'jp90': 'JIS90 Forms',
  'jp04': 'JIS2004 Forms',
  'kern': 'Kerning',
  'lfbd': 'Left Bounds',
  'liga': 'Standard Ligatures',
  'ljmo': 'Leading Jamo Forms',
  'lnum': 'Lining Figures',
  'locl': 'Localized Forms',
  'ltra': 'Left-to-right alternates',
  'ltrm': 'Left-to-right mirrored forms',
  'mark': 'Mark to Base Positioning',
  'med2': 'Medial Forms #2',
  'medi': 'Medial Forms',
  'mgrk': 'Mathematical Greek',
  'mkmk': 'Mark to Mark Positioning',
  'mset': 'Mark Positioning via Substitution',
  'nalt': 'Alternate Annotation Forms',
  'nlck': 'NLC Kanji Forms',
  'nukt': 'Nukta Forms',
  'numr': 'Numerators',
  'onum': 'Oldstyle Figures',
  'opbd': 'Optical Bounds',
  'ordn': 'Ordinals',
  'ornm': 'Ornaments',
  'palt': 'Proportional Alternate Widths',
  'pcap': 'Petite Capitals',
  'pkna': 'Proportional Kana',
  'pnum': 'Proportional Figures',
  'pref': 'Pre-Base Forms',
  'pres': 'Pre-base Substitutions',
  'pstf': 'Post-base Forms',
  'psts': 'Post-base Substitutions',
  'pwid': 'Proportional Widths',
  'qwid': 'Quarter Widths',
  'rand': 'Randomize',
  'rclt': 'Required Contextual Alternates',
  'rkrf': 'Rakar Forms',
  'rlig': 'Required Ligatures',
  'rphf': 'Reph Forms',
  'rtbd': 'Right Bounds',
  'rtla': 'Right-to-left alternates',
  'rtlm': 'Right-to-left mirrored forms',
  'ruby': 'Ruby Notation Forms',
  'rvrn': 'Required Variation Alternates',
  'salt': 'Stylistic Alternates',
  'sinf': 'Scientific Inferiors',
  'size': 'Optical size',
  'smcp': 'Small Capitals',
  'smpl': 'Simplified Forms',
  'ssty': 'Math script style alternates',
  'stch': 'Stretching Glyph Decomposition',
  'subs': 'Subscript',
  'sups': 'Superscript',
  'swsh': 'Swash',
  'titl': 'Titling',
  'tjmo': 'Trailing Jamo Forms',
  'tnam': 'Traditional Name Forms',
  'tnum': 'Tabular Figures',
  'trad': 'Traditional Forms',
  'twid': 'Third Widths',
  'unic': 'Unicase',
  'valt': 'Alternate Vertical Metrics',
  'vatu': 'Vattu Variants',
  'vert': 'Vertical Writing',
  'vhal': 'Alternate Vertical Half Metrics',
  'vjmo': 'Vowel Jamo Forms',
  'vkna': 'Vertical Kana Alternates',
  'vkrn': 'Vertical Kerning',
  'vpal': 'Proportional Alternate Vertical Metrics',
  'vrt2': 'Vertical Alternates and Rotation',
  'vrtr': 'Vertical Alternates for Rotation',
  'zero': 'Slashed Zero',
  }

# OT_FEATURES.update({f'ss{i:<02}': f'Stylistic Set {i}' for i in range(1, 21)})
# OT_FEATURES.update({f'cv{i:<02}': f'Character Variant {i}' for i in range(1, 100)})

SCALABLE_TABLE_KEYS = {
  'TypoAscender',
  'TypoDescender',
  'TypoLineGap',
  'winAscent',
  'winDescent',
  'XHeight',
  'CapHeight',
  'CaretOffset',
  'Ascender',
  'Descender',
  'LineGap',
  }

# LOOKUP_FLAGS = {
#   'RightToLeft',
#   'IgnoreBaseGlyphs',
#   'IgnoreLigatures',
#   'IgnoreMarks',
#   'MarkAttachmentType',
#   'UseMarkFilteringSet',
#   }

def fea_group(name, glyphs, indent=0):
  if indent:
    return f'\t@{name}=[{" ".join(glyphs)}];'
  return f'@{name}=[{" ".join(glyphs)}];'

def fea_table(label, table):
  table = '\n'.join(f'\t{key} {value};' for (key, value) in table
    if value is not None)
  return f'table {label} {{\n{table}\n}} {label};'

def fea_lookup(label, lookup, kern=0):
  if kern:
    return fea_kern_lookup(label, lookup)
  return '\n'.join((
    f'\tlookup {label} {{',
    *[f'\t{line}' for line in lookup],
    f'\t}} {label};',
    ))

def fea_kern_lookup(label, lookup):
  lookup = [
    f'\tlookup {label} useExtension {{\n'
    '\t\tlookupflag IgnoreMarks;',
    *[f'\t{line}' for line in lookup],
    f'\t\tlookupflag 0;\n'
    f'\t}} {label};\n'
    f'\tlookup {label};',
    ]
  return lookup

def fea_feature(label, feature):
  feature = '\n'.join(feature)
  return f'feature {label} {{ # {FEATURES[label]}\n{feature}\n}} {label};'
