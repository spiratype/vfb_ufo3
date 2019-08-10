# coding: utf-8
from __future__ import unicode_literals, print_function

import os
import tempfile

TEMP = tempfile.gettempdir()
DESKTOP = os.path.join(os.environ['USERPROFILE'], 'Desktop')

_print = print
def print(message):
	if isinstance(message, bytes):
		message = message.decode('utf_8').encode('cp1252', 'ignore')
	if isinstance(message, unicode):
		message.encode('cp1252', 'ignore')
	_print(message)

def save_encoding(ufo, font):
	font.encoding.Save(ufo.paths.encoding, b'TEMP_ENCODING', 99999)

def load_encoding(ufo, font):
	font.encoding.Load(ufo.paths.encoding)

def read_file(path):
	with open(path, 'rb') as f:
		return f.read().decode('cp1252')
