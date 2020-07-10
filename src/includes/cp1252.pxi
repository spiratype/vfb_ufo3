# CP1252

def py_bytes(unicode_str):
	return unicode_str.encode('cp1252', 'ignore')

def py_unicode(bytes_str):
	return bytes_str.decode('cp1252', 'ignore')

def cp1252_ascii_bytes(cp1252_bytes):
	return cp1252_bytes.decode('cp1252').encode('ascii')

def cp1252_utf8_bytes(cp1252_bytes):
	return cp1252_bytes.decode('cp1252').encode('utf_8')

def encoded(value):
	if isinstance(value, unicode):
		return py_bytes(value)
	return value

def decoded(value):
	if isinstance(value, bytes):
		return py_unicode(value)
	return value

def decode_dict(dictionary):
	return {decoded(key): decoded(value) for key, value in dictionary.iteritems()}
