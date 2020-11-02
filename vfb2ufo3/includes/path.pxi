# path.pxi

cdef extern from 'includes/cpp/path.cpp' nogil:
  string os_path_normpath(string)

DESKTOP = f'{os.environ["USERPROFILE"]}\\Desktop'
TEMP = os.environ['TMP']

os_sep = '\\'

def os_path_join(*paths):
  return os_sep.join(paths)

def os_path_basename(path):
  return path[path.rfind(os_sep)+1:]

def os_path_dirname(path):
  return path[:path.rfind(os_sep)]

def os_path_split(path, split_ext=0):
  i = path.rfind(os_sep)
  dirname, filename = path[:i], path[i+1:]
  if split_ext and '.' in filename:
    filename, ext = os_path_splitext(filename)
    return dirname, filename, ext
  return dirname, filename

def os_path_splitdrive(path):
  path = os_path_normpath(path)
  if ':' not in path:
    return '', path
  i = path.find(':') + 1
  return path[:i], path[i:]

def os_path_splitext(path):
  i = path.rfind('.')
  return path[:i], path[i+1:]

def os_path_exists(path):
  try:
    os.stat(path)
  except (OSError, ValueError):
    return 0
  return 1

def os_path_isdir(path):
  try:
    st = os.stat(path)
  except (OSError, ValueError):
    return 0
  return stat.S_ISDIR(st.st_mode)

def os_path_isfile(path):
  try:
    st = os.stat(path)
  except (OSError, ValueError):
    return 0
  return stat.S_ISREG(st.st_mode)

def os_path_isabs(path):
  if path.replace('/', os_sep).startswith('\\\\?\\'):
    return 1
  path = os_path_splitdrive(path)[1]
  return len(path) > 0 and path[0] in '\\/'

def os_makedirs(path):
  try:
    os.makedirs(path)
  except OSError:
    pass

def os_remove(path):
  if os_path_isdir(path):
    remove_tree(path)
  else:
    remove_file(path)

def next_path(path):
  if not os_path_exists(path):
    return path
  i = 1
  dirname, basename, ext = os_path_split(path, split_ext=1)
  while 1:
    path = os_path_join(dirname, f'{basename} ({i}).{ext}')
    if not os_path_exists(path):
      break
    i += 1
  return path

def copy_file(src_path, dest_path):
  start_new_thread(shutil.copyfile, src_path, dest_path)

def remove_file(path):
  start_new_thread(os.remove, path)

def remove_tree(path):
  start_new_thread(shutil.rmtree, path, ignore_errors=1)
