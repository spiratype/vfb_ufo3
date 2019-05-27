# coding: future_fstrings
from __future__ import absolute_import, division, print_function, unicode_literals

import array
import collections
import io
import itertools

open = io.open
range = xrange
str = unicode
zip = itertools.izip

def items(dictionary):
	return dictionary.iteritems()

FREE = -1
DUMMY = -2

class dict(collections.MutableMapping):

	'''
	space efficient dictionary with fast iteration and cheap resizes

	by Raymond Hettinger
	https://code.activestate.com/recipes/578375/
	'''

	@staticmethod
	def _gen_probes(hashvalue, mask):

		'''
		same sequence of probes used in the current dictionary design
		'''

		PERTURB_SHIFT = 5
		if hashvalue < 0:
			hashvalue = -hashvalue
		i = hashvalue & mask
		yield i
		perturb = hashvalue
		while True:
			i = (5 * i + perturb + 1) & 0xFFFFFFFFFFFFFFFF
			yield i & mask
			perturb >>= PERTURB_SHIFT

	def _lookup(self, key, hash_value):

		'''
		same lookup logic as currently used in real dicts
		'''

		# at least one open slot
		assert self.filled < len(self.indices)
		free_slot = None
		for i in self._gen_probes(hash_value, len(self.indices)-1):
			index = self.indices[i]
			if index == FREE:
				return (FREE, i) if free_slot is None else (DUMMY, free_slot)
			elif index == DUMMY:
				if free_slot is None:
					free_slot = i
			elif (self.keylist[index] is key or
				  self.hashlist[index] == hash_value
				  and self.keylist[index] == key):
					return (index, i)

	@staticmethod
	def _make_index(n):

		'''
		new sequence of indices using the smallest possible datatype
		'''

		# signed char
		if n <= 2**7:
			return array.array('b', [FREE]) * n

		# signed short
		if n <= 2**15:
			return array.array('h', [FREE]) * n

		# signed long
		if n <= 2**31:
			return array.array('l', [FREE]) * n

		# python integers
		return [FREE] * n

	def _resize(self, n):

		'''
		re-index the existing hash/key/value entries
		entries do not get moved, they only get new indices
		no calls are made to hash() or __eq__()
		'''

		# round-up to power-of-two
		n = 2 ** n.bit_length()
		self.indices = self._make_index(n)
		for index, hash_value in enumerate(self.hashlist):
			for i in dict._gen_probes(hash_value, n-1):
				if self.indices[i] == FREE:
					break
			self.indices[i] = index
		self.filled = self.used

	def clear(self):
		self.indices = self._make_index(8)
		self.hashlist = []
		self.keylist = []
		self.valuelist = []
		self.used = 0
		self.filled = 0              # used + dummies

	def __getitem__(self, key):
		hash_value = hash(key)
		index, i = self._lookup(key, hash_value)
		if index < 0:
			raise KeyError(key)
		return self.valuelist[index]

	def __setitem__(self, key, value):
		hash_value = hash(key)
		index, i = self._lookup(key, hash_value)
		if index < 0:
			self.indices[i] = self.used
			self.hashlist.append(hash_value)
			self.keylist.append(key)
			self.valuelist.append(value)
			self.used += 1
			if index == FREE:
				self.filled += 1
				if self.filled * 3 > len(self.indices) * 2:
					self._resize(4 * len(self))
		else:
			self.valuelist[index] = value

	def __delitem__(self, key):
		hash_value = hash(key)
		index, i = self._lookup(key, hash_value)
		if index < 0:
			raise KeyError(key)
		self.indices[i] = DUMMY
		self.used -= 1

		# if needed, swap with the lastmost entry to avoid leaving a "hole"
		if index != self.used:
			last_hash = self.hashlist[-1]
			last_key = self.keylist[-1]
			last_value = self.valuelist[-1]
			last_index, j = self._lookup(last_key, last_hash)
			assert last_index >= 0 and i != j
			self.indices[j] = index
			self.hashlist[index] = last_hash
			self.keylist[index] = last_key
			self.valuelist[index] = last_value

		# remove the lastmost entry
		self.hashlist.pop()
		self.keylist.pop()
		self.valuelist.pop()

	def __init__(self, *args, **kwds):
		if not hasattr(self, 'keylist'):
			self.clear()
		self.update(*args, **kwds)

	def __len__(self):
		return self.used

	def __iter__(self):
		return iter(self.keylist)

	# def iterkeys(self):
	# 	return iter(self.keylist)

	# def keys(self):
	# 	return list(self.keylist)

	# def itervalues(self):
	# 	return iter(self.valuelist)

	# def values(self):
	# 	return list(self.valuelist)

	# def iteritems(self):
	# 	return itertools.izip(self.keylist, self.valuelist)

	# def items(self):
	# 	return zip(self.keylist, self.valuelist)

	def keys(self):
		return iter(self.keylist)

	def values(self):
		return iter(self.valuelist)

	def items(self):
		return zip(self.keylist, self.valuelist)

	def __contains__(self, key):
		index, i = self._lookup(key, hash(key))
		return index >= 0

	def get(self, key, default=None):
		index, i = self._lookup(key, hash(key))
		return self.valuelist[index] if index >= 0 else default

	def popitem(self):
		if not self.keylist:
			raise KeyError('popitem(): dictionary is empty')
		key = self.keylist[-1]
		value = self.valuelist[-1]
		del self[key]
		return key, value

	def __repr__(self):
		rep = ', '.join([': '.join([f"'{key}'", f"'{val}'"])
			for key, val in self.items()])
		return f'{{{rep}}}'.encode('ascii')

class AttributeDict(object):
	def __init__(self, **kwargs):
		self._dict_ = dict(**kwargs)

	def __getattr__(self, name):
		try:
			return self._dict_[name]
		except KeyError:
			raise AttributeError(name)

	def __setattr__(self, name, value):
		if name == '_dict_':
			return super(AttributeDict, self).__setattr__(name, value)
		self._dict_[name] = value

	def keys(self):
		return iter(self._dict_.keylist)

	def values(self):
		return iter(self._dict_.valuelist)

	def items(self):
		return zip(self._dict_.keylist, self._dict_.valuelist)

	def __repr__(self):
		return repr(self._dict_)
