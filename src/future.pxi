from future_builtins import zip

from io import open

range = xrange
str = unicode
chr = unichr

def items(dictionary):
	return ((key, dictionary[key]) for key in dictionary)

def values(dictionary):
	return (dictionary[key] for key in dictionary)

def keys(dictionary):
	return (key for key in dictionary)
