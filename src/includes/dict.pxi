# DICT

def reverse_dict(dictionary):
	return {value: key for key, value in items(dictionary)}

def encoded(value):
	if isinstance(value, unicode):
		return cp1252_bytes_str(value)
	return value

def decoded(value):
	if isinstance(value, bytes):
		return cp1252_unicode_str(value)
	return value

def decode_dict(dictionary):
	return {decoded(key): decoded(value) for key, value in dictionary.iteritems()}
