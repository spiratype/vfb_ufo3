# xml.pxi

def elem_attrs(attrs):

	'''
	>>> elem_attrs([('name', 'top')])
	name='top'
	'''

	return ' '.join(f"{key}='{val}'" for key, val in attrs if val is not None)


def xml_elems(elements, indents=0):

	'''
	>>> xml_elems(('<key>Key</key>', '<string>Value</string>'), 1)
		<key>Key</key>
		<string>Value</string>
	'''

	if isinstance(elements, list):
		return ''.join(element(value, indents) for value in elements)

	elems = []
	if isinstance(elements, dict):
		for key, value in elements.items():
			if value is not None:
				elems += [text_elem('key', key, indents), element(value, indents)]

	return ''.join(elems)


def plist_doc(plist):

	if isinstance(plist, dict):
		plist = dict_elem(plist)
	if isinstance(plist, list):
		plist = list_elem(plist)

	return (
		"<?xml version='1.0' encoding='UTF-8'?>\n"
		"<!DOCTYPE plist PUBLIC '-//Apple Computer//DTD PLIST 1.0//EN'\n"
		"\t'http://www.apple.com/DTDs/PropertyList-1.0.dtd'>\n"
		"<plist version='1.0'>\n"
		f"{plist}"
		"</plist>\n"
		).encode('utf_8')

def dict_elem(elems, indents=0):

	'''
	>>> dict_elem({'Key': 'Value'}, 1)
	<dict>
		<key>Key</key>
		<string>Value</string>
	</dict>
	'''

	return elems_elem('dict', elems, indents)


def list_elem(elems, indents=0):

	'''
	>>> list_elem(['<integer>1</integer>', '<integer>2</integer>'], 1)
	<array>
		<integer>1</integer>
		<integer>2</integer>
	</array>
	'''

	if not elems:
		if indents:
			indent = '\t' * indents
			return f'{indent}<array></array>\n'
		return '<array></array>\n'
	return elems_elem('array', elems, indents)


def elems_elem(tag, elems, indents=0):

	'''
	>>> elems_elem({'Key': 'Value'}, 1)
		<dict>
			<key>Key</key>
			<string>Value</string>
		</dict>
	>>> elems_elem(['<integer>1</integer>', '<integer>2</integer>'], 1)
		<array>
			<integer>1</integer>
			<integer>2</integer>
		</array>
	'''

	if indents:
		indent = '\t' * indents
		if isinstance(elems, unicode):
			return f'{indent}<{tag}>\n{elems}{indent}</{tag}>\n'
		return f'{indent}<{tag}>\n{xml_elems(elems, indents+1)}{indent}</{tag}>\n'

	if isinstance(elems, unicode):
		return f'<{tag}>\n{elems}</{tag}>\n'
	return f'<{tag}>\n{xml_elems(elems, indents+1)}</{tag}>\n'


def attrs_elems_elem(tag, attrs, elems, indents=0):

	'''
	>>> attrs_elems_elem('glyph', [('name', 'space')], ['<unicode hex="0020"/>, <advance width="400"/>'], 0)
	<glyph name="space">
		<unicode hex="0020"/>
		<advance width="400"/>
	</glyph>
	'''

	if indents:
		indent = '\t' * indents
		if isinstance(elems, unicode):
			return f'{indent}<{tag} {elem_attrs(attrs)}>\n{elems}{indent}</{tag}>\n'
		return f'{indent}<{tag} {elem_attrs(attrs)}>\n{xml_elems(elems, indents+1)}{indent}</{tag}>\n'

	if isinstance(elems, unicode):
		return f'<{tag} {elem_attrs(attrs)}>\n{elems}</{tag}>\n'
	return f'<{tag} {elem_attrs(attrs)}>\n{xml_elems(elems, indents+1)}</{tag}>\n'


def attrs_text_elem(tag, attrs, text, indents=0):

	'''
	>>> attrs_text_elem('element', [('name', 'top')], 'Test', 0)
	<element name='top'>Test</element>
	'''

	if indents:
		indent = '\t' * indents
		return f'{indent}<{tag} {elem_attrs(attrs)}>{text}</{tag}>\n'
	return f'<{tag} {elem_attrs(attrs)}>{text}</{tag}>\n'


def attrs_elem(tag, attrs, indents=0):

	'''
	>>> attrs_elem('element', [('name', 'top')], 0)
	<element name='top'/>
	'''

	if indents:
		indent = '\t' * indents
		return f'{indent}<{tag} {elem_attrs(attrs)}/>\n'
	return f'<{tag} {elem_attrs(attrs)}/>\n'


def text_elem(tag, text, indents=0):

	'''
	>>> text_elem('string', 'Test', 1)
		<string>Test</string>
	'''

	if indents:
		indent = '\t' * indents
		return f'{indent}<{tag}>{text}</{tag}>\n'
	return f'<{tag}>\n{text}</{tag}>\n'


def empty_elem(text, indents=0):

	'''
	>>> empty_elem('true')
	<true/>
	'''

	if indents:
		indent = '\t' * indents
		return f'{indent}<{text}/>\n'
	return f'<{text}/>\n'


def element(value, indents=0):

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
		return empty_elem(str(value).lower(), indents)

	elif isinstance(value, bytes):
		return text_elem('string', value.decode('cp1252'), indents)

	elif isinstance(value, unicode):
		return text_elem('string', value, indents)

	elif isinstance(value, int):
		return text_elem('integer', str(value), indents)

	elif isinstance(value, float):
		return text_elem('real', str(value), indents)

	elif isinstance(value, dict):
		return dict_elem(value, indents)

	elif isinstance(value, list):
		return list_elem(value, indents)
