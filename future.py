# coding: utf-8
from __future__ import (absolute_import, division, print_function,
	unicode_literals)

import io
import itertools

__all__ = ['open', 'range', 'str', 'zip', 'items']

open = io.open
range = xrange
str = unicode
zip = itertools.izip

def items(dictionary):
	return dictionary.iteritems()
