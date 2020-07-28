# PATH

import uuid
import shutil
import tempfile

TEMP = tempfile.gettempdir()

def split_path(path, split_ext=0):
	if isinstance(path, bytes):
		path = path.decode('utf_8')
	dirname, filename = os.path.split(path)
	if split_ext and '.' in filename:
		filename, ext = os.path.splitext(filename)
		return dirname, filename, ext
	return dirname, filename

def unique_id():
	return cp1252_unicode_str(uuid.uuid4().hex)

def unique_path(path, temp=0):
	if isinstance(path, bytes):
		path = path.decode('utf_8')
	if os.sep in path:
		dirname, basename, ext = split_path(path, split_ext=1)
		if temp:
			return os.path.join(TEMP, f'{basename}_{unique_id()}.{ext}').encode('utf_8')
		return os.path.join(dirname, f'{basename}_{unique_id()}.{ext}').encode('utf_8')
	if '.' in path:
		basename, ext = os.path.splitext(path)
		return os.path.join(TEMP, f'{basename}_{unique_id()}.{ext}').encode('utf_8')
	return os.path.join(TEMP, f'{path}_{unique_id()}').encode('utf_8')

def remove_path(path, force=0):
	if os.path.exists(path):
		temp_path = unique_path(path, temp=1)
		if force:
			try:
				move(path, temp_path)
				remove(temp_path)
			except IOError as e:
				if e.errno == 13:
					raise IOError(b'%s is open.\nPlease close the file.' % os.path.basename(path))
		move(path, temp_path)
		remove(temp_path)

def move(src_path, dest_path):
	try:
		os.rename(src_path, dest_path)
	except OSError:
		pass

def make_dir(path):
	try:
		os.makedirs(path)
	except OSError:
		pass

def remove(path):
	if os.path.isfile(path):
		return remove_file(path)
	return remove_tree(path)

def unlink(file):
	try:
		os.remove(file)
	except OSError:
		pass

def copy_file(src_path, dest_path):
	start_new_thread(shutil.copyfile, src_path, dest_path)

def remove_file(file):
	start_new_thread(unlink, file)

def remove_tree(tree):
	start_new_thread(shutil.rmtree, tree, ignore_errors=1)
