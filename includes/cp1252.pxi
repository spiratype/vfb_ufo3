# CP1252

def py_bytes(unicode_str):
	return unicode_str.encode('cp1252', 'ignore')

def py_unicode(bytes_str):
	return bytes_str.decode('cp1252', 'ignore')

def decoded(value):
	if isinstance(value, bytes):
		return py_unicode(value)
	return value

def decode_dict(dictionary):
	return {decoded(key): decoded(value) for key, value in items(dictionary)}
