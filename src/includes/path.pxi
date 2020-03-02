# PATH

import uuid
import shutil
import tempfile

TEMP = tempfile.gettempdir()

def split_path(path, split_ext=0):
	dirname, filename = os.path.split(path)
	if split_ext and '.' in filename:
		if filename.count('.') > 1:
			filename = filename.split('.')
			i = len(filename) - 1
			filename, ext = filename[:i], filename[i:]
			filename, ext = '.'.join(filename), ''.join(ext)
		else:
			filename, ext = filename.split('.')
		return dirname, filename, ext
	return dirname, filename

def unique_id():
	return py_unicode(uuid.uuid4().hex)

def unique_path(path, temp=0):
	if isinstance(path, bytes):
		path = path.decode('utf_8')
	if os.sep in path:
		dirname, basename, ext = split_path(path, split_ext=1)
		if temp:
			return file_str(os.path.join(TEMP, f'{basename}_{unique_id()}.{ext}'))
		return file_str(os.path.join(dirname, f'{basename}_{unique_id()}.{ext}'))
	if '.' in path:
		basename, ext = path.split('.')
		return file_str(os.path.join(TEMP, f'{basename}_{unique_id()}.{ext}'))
	return file_str(os.path.join(TEMP, f'{path}_{unique_id()}'))

def remove_path(path, force=0):
	if os.path.exists(path):
		temp_path = unique_path(path, temp=1)
		if force:
			try:
				move(path, temp_path)
				remove(temp_path)
			except IOError as e:
				if e.errno == 13:
					error = b'%s is open.\nPlease close the file.' % os.path.basename(path)
					raise IOError(error)
		else:
			move(path, temp_path)
			remove(temp_path)

def move(src_path, dest_path):
	with ignored(OSError):
		os.rename(src_path, dest_path)

def make_dir(path):
	with ignored(OSError):
		os.makedirs(path)

def remove(path):
	if os.path.isfile(path):
		return remove_file(path)
	return remove_tree(path)

def unlink(file):
	with ignored(OSError):
		os.remove(file)

def copy_file(src_path, dest_path):
	start_new_thread(shutil.copyfile, args=(src_path, dest_path))

def remove_file(file):
	start_new_thread(unlink, args=(file,))

def remove_tree(tree):
	start_new_thread(shutil.rmtree, args=(tree,), kwargs={'ignore_errors': 1})
