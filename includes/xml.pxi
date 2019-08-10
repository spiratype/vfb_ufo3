# XML

XML_PROLOG = '<?xml version="1.0" encoding="UTF-8"?>'

def attributes(attrs):

	'''
	>>> attrs = [['x', 1], ['y', 20]]
	>>> attributes(attrs)
	x="1" y="20"
  >>> attrs = [['x', 1], ['y', None]]
  >>> attributes(attrs)
  x="1"
	'''

	return ' '.join([f'{key}="{val}"' for key, val in attrs if val is not None])
