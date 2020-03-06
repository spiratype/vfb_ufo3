# coding: utf-8
# cython: wraparound=False
# cython: boundscheck=False
# cython: cdivision=True
# cython: auto_pickle=False
# distutils: extra_compile_args=[-fconcepts, -O3, -fno-strict-aliasing, -Wno-register]
# distutils: extra_link_args=[-fconcepts, -O3, -fno-strict-aliasing, -Wno-register]
from __future__ import absolute_import, division, unicode_literals, print_function
include 'includes/future.pxi'
include 'includes/cp1252.pxi'

cimport cython

import gc
import os
import time
import zipfile

from FL import fl

from . import user
from .user import print

include 'includes/ignored.pxi'
include 'includes/string.pxi'
include 'includes/thread.pxi'
include 'includes/path.pxi'
include 'includes/defaults.pxi'

# ----------------
#  report builder
# ----------------

def report_times(times, ufoz=0):

	report_times = (
		f'  {time_str(times.glifs)} (glifs)\n'
		f'  {time_str(times.features)} (features)\n'
		f'  {time_str(times.kern)} (kern)\n'
		f'  {time_str(times.plists)} (plists)\n'
		f'  {time_str(times.fontinfo)} (fontinfo)'
		)
	return report_times

def finish(ufo, instance=0):

	if instance:

		if ufo.opts.ufoz and ufo.archive:
			write_zip(ufo.paths.instance.ufoz, ufo.archive, ufo.opts.ufoz_compress)
		if ufo.opts.vfb_save or not ufo.opts.vfb_close:
			fl[ufo.instance.ifont].Save(ufo.paths.instance.vfb)
		fl.Close(ufo.instance.ifont)

		total = time_str(time.clock() - ufo.instance_times.total)
		ufo_path = ufo.instance_paths[ufo.instance.completed]
		filename = os.path.basename(ufo_path)
		if 'masters' in ufo_path:
			filename = os.path.join('masters', filename)
		ufo.instance.completed += 1
		if not ufo.opts.report_verbose:
			print(f' {filename} completed {total}')
			return

		print(f'\n {filename} completed {total}:\n'
			f'{report_times(ufo.instance_times, ufo.opts.ufoz)}')

		ufo.total_times.glifs += ufo.instance_times.glifs
		ufo.total_times.features += ufo.instance_times.features
		ufo.total_times.plists += ufo.instance_times.plists
		ufo.total_times.kern += ufo.instance_times.kern
		ufo.total_times.fontinfo += ufo.instance_times.fontinfo
		ufo.total_times.afdko += ufo.instance_times.afdko

		reset(ufo, instance=1)
		return

	remove_path(ufo.paths.encoding)

	if ufo.opts.vfb_save or not ufo.opts.vfb_close:
		fl[ufo.master_copy.ifont].Save(ufo.paths.vfb)
	fl.Close(ufo.master_copy.ifont)

	total = time_str(time.clock() - ufo.total_times.start)
	if not ufo.opts.report_verbose:
		print(f'\n{ufo.instance.completed} UFO(s) completed ({total})')
		open_vfbs(ufo)
		return reset(ufo)

	report = [
		f'\n{ufo.instance.completed} UFO(s) completed ({total}):\n',
		f'{report_times(ufo.total_times, ufo.opts.ufoz)}\n'.replace('  ', ' '),
		]
	if ufo.opts.scale_auto:
		report.append(f' {ufo.opts.scale_to_upm} upm (auto-scaled)\n')
	elif ufo.opts.scale_to_upm:
		report.append(f' {ufo.opts.scale_to_upm} upm (scaled)\n')

	if ufo.opts.glyphs_decompose or ufo.opts.glyphs_remove_overlaps:
		report.append(' glyph options:\n')
		if ufo.opts.glyphs_decompose:
			report.append('  decomposition\n')
		if ufo.opts.glyphs_remove_overlaps:
			report.append('  overlaps removed\n')

	if ufo.opts.afdko_parts:
		report.append(' font options:\n  AFDKO\n')

	print(''.join(report))
	open_vfbs(ufo)
	reset(ufo)


def open_vfbs(ufo):
	for path in ufo.paths.vfbs:
		if os.path.isfile(path):
			fl.Open(path)

def reset(ufo, instance=0):

	if instance:
		for key, value in UFO_TIMES_INSTANCE:
			ufo.instance_times[key] = value
		return

	for key, value in UFO_TIMES_TOTAL:
		ufo.total_times[key] = value

	for key, value in UFO_TIMES_INSTANCE:
		ufo.instance_times[key] = value

	for key, value in UFO_PATHS:
		ufo.paths[key] = value

	for key, value in UFO_PATHS_INSTANCE:
		ufo.paths.instance[key] = value

	for key, value in UFO_MASTER:
		ufo.master[key] = value

	for key, value in UFO_PLISTS:
		ufo.plists[key] = value

	ufo.opts = None

	gc.collect()
	del gc.garbage[:]

def write_zip(path, archive, compress=0):

	try:
		with zipfile.ZipFile(path, 'w', compression=compress*8) as z:
			for path, contents in items(archive):
				z.writestr(path, contents)
	except IOError as e:
		if e.errno == 13:
			raise IOError(f' {os.path.basename(path)} is open.\n Please close the file.')
		raise IOError(f' {os.path.basename(path)} already exists.\n'
			" Please rename or delete the existing file, or set 'force_overwrite' to True")

# ------------
#  time tools
# ------------

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
