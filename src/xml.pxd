# XML

cdef inline bytes file_str(unicode unicode_str):

	try:
		return unicode_str.encode('ascii')
	except UnicodeError:
		return unicode_str.encode('utf_8')


cdef inline unicode py_str(bytes byte_string):
	try:
		return byte_string.decode('cp1252')
	except UnicodeError:
		return byte_string.decode('cp1252', 'ignore')


cdef inline unicode _attrs(list attrs):

	'''
	>>> _attrs([('name', 'top')])
	'name="top"'
	'''

	return ' '.join([f'{key}="{val}"' for key, val in attrs if val is not None])


cdef inline unicode _elems(elements, int indents=0):

	'''
	>>> _elems(['<key>Key</key>', '<string>Value</string>'], 1)
	'\t<key>Key</key>\n\t<string>Value</string>'
	'''

	cdef list elems
	if isinstance(elements, list):
		elems = [element(value, indents) for value in elements]
		return ''.join(elems)

	elems = []
	if isinstance(elements, dict):
		for key, value in elements.items():
			if value is not None:
				elems += [text_elem('key', key, indents), element(value, indents)]

	return ''.join(elems)


cdef inline bytes plist_doc(object plist):

	if isinstance(plist, dict):
		plist = dict_elem(plist, 0)
	elif isinstance(plist, list):
		plist = list_elem(plist, 0)
	return file_str(
		'<?xml version="1.0" encoding="UTF-8"?>\n'
		'<!DOCTYPE plist PUBLIC "-//Apple Computer//DTD PLIST 1.0//EN"\n'
		'\t"http://www.apple.com/DTDs/PropertyList-1.0.dtd">\n'
		'<plist version="1.0">\n'
		f'{plist}'
		'</plist>\n'
		)


cdef inline unicode dict_elem(object elems, int indents=0):

	'''
	>>> dict_elem({'Key': 'Value'}, 1)
	'\t<key>Key</key>\n\t<string>Value</string>'
	'''

	return elems_elem('dict', elems, indents)


cdef inline unicode list_elem(list elems, int indents=0):

	'''
	>>> list_elem(['<integer>1</integer>', '<integer>2</integer>'], 1)
	'\t<integer>1</integer>\n\t<integer>2</integer>'
	'''

	if not elems:
		if indents:
			indent = '\t' * indents
			return f'{indent}<array></array>\n'
		return '<array></array>\n'
	return elems_elem('array', elems, indents)


cdef inline unicode elems_elem(unicode tag, elems, indents=0):

	'''
	>>> elems_elem({'Key': 'Value'}, 1)
	'\t<dict>\n\t\t<key>Key</key>\n\t\t<string>Value</string>\n\t</dict>'
	>>> elems_elem(['<integer>1</integer>', '<integer>2</integer>'], 1)
	'\t<array>\n\t\t<integer>1</integer>\n\t\t<integer>2</integer>\n\t</array>'
	'''

	if indents:
		indent = '\t' * indents
		if isinstance(elems, unicode):
			return f'{indent}<{tag}>\n{elems}{indent}</{tag}>\n'
		return f'{indent}<{tag}>\n{_elems(elems, indents+1)}{indent}</{tag}>\n'

	if isinstance(elems, unicode):
		return f'<{tag}>\n{elems}</{tag}>\n'
	return f'<{tag}>\n{_elems(elems, indents+1)}</{tag}>\n'


cdef inline unicode attrs_elems_elem(unicode tag, list attrs, elems, indents=0):

	'''
	>>> attrs_elems_elem('glyph', [('name', 'space')], ['<unicode hex="0020"/>, <advance width="400"/>'], 0)
	'<glyph name="space">\n  <unicode hex="0020"/>\n  <advance width="400"/>\n</glyph>'
	'''

	if indents:
		indent = '\t' * indents
		if isinstance(elems, unicode):
			return f'{indent}<{tag} {_attrs(attrs)}>\n{elems}{indent}</{tag}>\n'
		return f'{indent}<{tag} {_attrs(attrs)}>\n{_elems(elems, indents+1)}{indent}</{tag}>\n'

	if isinstance(elems, unicode):
		return f'<{tag} {_attrs(attrs)}>\n{elems}</{tag}>\n'
	return f'<{tag} {_attrs(attrs)}>\n{_elems(elems, indents+1)}</{tag}>\n'


cdef inline unicode attrs_text_elem(unicode tag, list attrs, unicode text, int indents=0):

	'''
	>>> attrs_text_elem('element', [('name', 'top')], 'Test', 0)
	<element name="top">Test</element>
	'''

	if indents:
		indent = '\t' * indents
		return f'{indent}<{tag} {_attrs(attrs)}>{text}</{tag}>\n'
	return f'<{tag} {_attrs(attrs)}>{text}</{tag}>\n'


cdef inline unicode attrs_elem(unicode tag, list attrs, int indents=0):

	'''
	>>> attrs_elem('element', [('name', 'top')], 0)
	<element name="top"/>
	'''

	if indents:
		indent = '\t' * indents
		return f'{indent}<{tag} {_attrs(attrs)}/>\n'
	return f'<{tag} {_attrs(attrs)}/>\n'


cdef inline unicode text_elem(unicode tag, unicode text, int indents=0):

	'''
	>>> text_elem('string', 'Test', 1)
	  <string>Test</string>
	'''

	if indents:
		indent = '\t' * indents
		return f'{indent}<{tag}>{text}</{tag}>\n'
	return f'<{tag}>\n{text}</{tag}>\n'


cdef inline unicode empty_elem(unicode text, int indents=0):

	'''
	>>> empty_elem('true')
	<true/>
	'''

	if indents:
		indent = '\t' * indents
		return f'{indent}<{text}/>\n'
	return f'<{text}/>\n'


cdef inline element(value, int indents=0):

	'''
	xml element builder

	>>> xml_element(True)
	<true/>
	>>> xml_element(1)
	<integer>1</integer>
	>>> xml_element(1.0)
	<real>1.0</real>
	>>> xml_element('string')
	<string>string</string>
	>>> xml_element([1, 2.0, 3], 0)
	<array>
		<integer>1</integer>
		<real>2</real>
		<integer>3</integer>
	</array>
	>>> xml_element({'a': 1, 'b': 2.0}, 0)
	<dict>
		<key>a</key>
		<integer>1</integer>
		<key>b</key>
		<real>2.0</real>
	</dict>
	'''

	if isinstance(value, bool):
		return empty_elem(unicode(value).lower(), indents)

	elif isinstance(value, bytes):
		return text_elem('string', py_str(value), indents)

	elif isinstance(value, unicode):
		return text_elem('string', value, indents)

	elif isinstance(value, int):
		return text_elem('integer', unicode(value), indents)

	elif isinstance(value, float):
		return text_elem('real', unicode(value), indents)

	elif isinstance(value, dict):
		return dict_elem(value, indents)

	elif isinstance(value, list):
		return list_elem(value, indents)

