# IO

def write_file(path, contents):
	start_new_thread(_write_file, args=(path, contents))

def write_file2(path, contents):
	start_new_thread2(_write_file, args=(path, contents))

def _write_file(path, contents):
	with open(path, 'wb', 0) as f:
		f.write(contents)
