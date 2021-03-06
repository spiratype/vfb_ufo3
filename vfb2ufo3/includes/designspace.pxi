# designspace.pxi

AXIS_TAGS = {
  'Italic': 'ital',
  'OpticalSize': 'opsz',
  'Serif': 'serf',
  'Slant': 'slnt',
  'Width': 'wdth',
  'Weight': 'wght',
  }
SOURCE_ATTRS = (
  'filename',
  'familyname',
  'stylename',
  'name',
  )
INSTANCE_ATTRS = (
  'filename',
  'familyname',
  'stylename',
  'name',
  'postscriptfontname',
  'stylemapfamilyname',
  'stylemapstylename',
  )

@cython.final
cdef class c_designspace:

  def __init__(self, parent):
    self.path = parent.paths.designspace
    self.rules = [dspace_rule(glyph, glyph=1)
      for glyph in parent.designspace.glyphs_omit]
    self.axes = []
    self.sources = []
    self.instances = []

  def write(self):
    write_file(self.path, self.text)

  def __reduce__(self):
    return self.__class__

def dspace_location(dimensions):
  return ['\t\t\t<location>', *dimensions, '\t\t\t</location>']

def dspace_axes(axes):
  return ['\t<axes>', *axes, '\t</axes>']

def dspace_instances(instances):
  return ['\t<instances>', *instances, '\t</instances>']

def dspace_sources(sources):
  return ['\t<sources>', *sources, '\t</sources>']

def dspace_axis(tag, default):
  attrs = elem_attrs((
    ('default', default),
    ('minimum', '0'),
    ('maximum', '1000'),
    ('name', tag.lower()),
    ('tag', AXIS_TAGS[tag]),
    ))
  return [f'\t\t<axis {attrs}>', dspace_labelname(tag), '\t\t</axis>']

def dspace_labelname(text):
  return f'\t\t\t<labelname xml:lang="en">{text}</labelname>'

def dspace_dimension(name, double value):
  attrs = elem_attrs((
    ('name', name.lower()),
    ('xvalue', number_str(value)),
    ))
  return f'\t\t\t\t<dimension {attrs}/>'

def dspace_copy(tag):
  return f'\t\t\t<{tag} copy="1"/>'

def dspace_rule(name, glyph=0):
  if glyph:
    return f'\t\t\t<glyph mute="1" name="{name}"/>'

def dspace_source(location, names, features=0, groups=0, info=0, lib=0):
  attrs = elem_attrs([[name, names[name]] for name in SOURCE_ATTRS])
  copies = ['features', 'groups', 'info', 'lib']
  options = decode_dict(locals())
  copies = [dspace_copy(key) for key in copies if options[key] == 1]
  elems = copies + location
  return [f'\t\t<source {attrs}>', *elems, '\t\t</source>']

def dspace_instance(location, names, rules):
  attrs = elem_attrs([[name, names[name]] for name in INSTANCE_ATTRS])
  instance = rules + location
  return [f'\t\t<instance {attrs}>', *instance, '\t\t</instance>']
