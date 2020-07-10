# coding: utf-8
# cython: wraparound=False
# cython: boundscheck=False
# cython: infer_types=True
# cython: cdivision=True
# cython: auto_pickle=False
# distutils: extra_compile_args=[-O0, -fno-strict-aliasing]
# distutils: extra_link_args=[-O0]
from __future__ import division, unicode_literals, print_function
include 'includes/future.pxi'
include 'includes/cp1252.pxi'

import time

FLC_HEADER =               '%%FONTLAB CLASSES'
FLC_GROUP_MARKER =         '%%CLASS'
FLC_GLYPHS_MARKER =        '%%GLYPHS '
FLC_KERNING_MARKER =       '%%KERNING'
FLC_LEFT_KERNING_MARKER =  '%%KERNING L 0'
FLC_RIGHT_KERNING_MARKER = '%%KERNING R 0'
FLC_END_MARKER =           '%%END'

def main():
	_main()

def time_str(duration, precision=1, simple_output=False):

	'''
	time string from time.clock() double

	>>> time_str(4.505)
	4.5 sec
	'''

	if duration == 0.0:
		return '0 sec'

	def hours_time(hours, minutes, seconds):

		if simple_output:
			return hours, minutes, seconds
		else:
			return f'{hours} hr {minutes} min {seconds} sec'

	def minutes_time(minutes, seconds, duration):

		if simple_output :
			return minutes, seconds
		else:
			return f'{minutes} min {seconds} sec'

	def seconds_time(seconds, duration):

		str_seconds = f'{seconds}'
		if str_seconds.count('.0000'):
			seconds = str_seconds[:str_seconds.find('.')] + '.000'
		if simple_output:
			return seconds
		else:
			return f'{seconds} sec'

	def milliseconds_time(milliseconds, duration):

		milliseconds = int(round(milliseconds))
		if simple_output:
			return int(round(milliseconds))
		else:
			return f'{milliseconds} msec'

	def microseconds_time(microseconds, duration):

		microseconds = int(round(microseconds))
		if simple_output:
			return int(round(microseconds))
		else:
			return f'{microseconds} µsec'

	def nanoseconds_time(nanoseconds, duration):

		nanoseconds = int(round(nanoseconds))
		if simple_output:
			return round(duration, 9)
		else:
			return f'{nanoseconds} nsec'


	if 1 > duration >= 1e-9:
		milliseconds = duration * 1e3
		if 999 > milliseconds >= 1:
			return milliseconds_time(milliseconds, duration)
		else:
			microseconds = duration * 1e6
			if 999 > microseconds >= 1:
				return microseconds_time(microseconds, duration)
			else:
				nanoseconds = duration * 1e9
				if 999 > nanoseconds >= 1:
					return nanoseconds_time(nanoseconds, duration)

	if 3600 > duration >= 1:
			minutes, seconds = duration // 60, duration % 60
			if 59 > minutes >= 1:
				return minutes_time(minutes, round(seconds, precision), duration)
			else:
				seconds = round(duration, precision)
				return seconds_time(seconds, duration)

	if duration >= 3600:
		hours, minutes = duration // 3600, duration % 3600
		seconds = round(duration % 3600, precision)
		return hours_time(hours, minutes, seconds)

def _main():
	iters = 1000000
	start = time.clock()
	for i in range(iters):
		flc_file = [f'{FLC_HEADER}\n']
		flc_end_marker = f'{FLC_END_MARKER}\n'
		marker = FLC_RIGHT_KERNING_MARKER if i % 2 else FLC_LEFT_KERNING_MARKER
		flc_file += [
			marker,
			flc_end_marker,
			]
	print(time_str((time.clock() - start) / iters))

	start = time.clock()
	for i in range(iters):
		flc_file = [FLC_HEADER + '\n']
		flc_end_marker = FLC_END_MARKER + '\n'
		marker = FLC_RIGHT_KERNING_MARKER if i % 2 else FLC_LEFT_KERNING_MARKER
		flc_file += [
			marker,
			flc_end_marker,
			]
	print(time_str((time.clock() - start) / iters))
