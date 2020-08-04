# unique.pxi

def unique_id():
	return str(uuid.uuid4().hex)

def unique_path(path, temp=0):
	if os_sep in path:
		dirname, basename, ext = os_path_split(path, split_ext=1)
		if temp:
			return os_path_join(TEMP, f'{basename}_{unique_id()}.{ext}')
		return os.path.join(dirname, f'{basename}_{unique_id()}.{ext}')
	if '.' in path:
		basename, ext = os_path_splitext(path)
		return os_path_join(TEMP, f'{basename}_{unique_id()}.{ext}')
	return os_path_join(TEMP, f'{path}_{unique_id()}')

def remove_path(path, force=0):
	if os_path_exists(path):
		temp_path = unique_path(path, 1)
		if force:
			try:
				os.rename(path, temp_path)
			except IOError:
				raise IOError(b'%s is open.\nPlease close the file.' % os_path_basename(path))
			os_remove(temp_path)
		else:
			os.rename(path, temp_path)
			os_remove(temp_path)
