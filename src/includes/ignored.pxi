# IGNORED

import contextlib

# ------------------------------
#  try/except pass replacements
# ------------------------------

@contextlib.contextmanager
def ignored(*exceptions):
	try:
		yield
	except exceptions:
		pass
