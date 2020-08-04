# coding: utf-8
from __future__ import unicode_literals

def save_encoding(ufo, font):
	font.encoding.Save(ufo.paths.encoding.encode('cp1252'), b'TEMP_ENCODING', 99999)

def load_encoding(ufo, font):
	font.encoding.Load(ufo.paths.encoding.encode('cp1252'))
