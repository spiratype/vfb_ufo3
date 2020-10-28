from future_builtins import zip

range = xrange
str = unicode
chr = unichr

def items(dictionary):
  return dictionary.iteritems()

def values(dictionary):
  return dictionary.itervalues()

def keys(dictionary):
  return dictionary.iterkeys()
