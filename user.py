# coding: utf-8
from __future__ import unicode_literals, print_function

import subprocess

def save_encoding(ufo, font):
	font.encoding.Save(ufo.paths.encoding.encode('cp1252'), b'TEMP_ENCODING', 99999)

def load_encoding(ufo, font):
	font.encoding.Load(ufo.paths.encoding.encode('cp1252'))

def run(command, dir_path=None, show_output=1):

	if show_output:
		print(command)

	job = subprocess.Popen(
		command,
		shell=1,
		stdout=subprocess.PIPE,
		stderr=subprocess.PIPE,
		bufsize=1,
		cwd=dir_path,
		universal_newlines=1,
		)

	while 1:
		out = job.stdout.readline()
		if out == '' and job.poll() is not None:
			break
		if out and show_output:
			print(out + '\n')

	return job.communicate() # stderr, stdout
