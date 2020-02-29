# THREAD

import threading

def start_new_thread(target, args=(), kwargs={}):
	if not isinstance(args, tuple):
		args = (args,)
	threading.Thread(target, args=args, kwargs=kwargs)
