# THREAD

import thread
import threading

def start_new_thread(target=None, args=(), kwargs={}):
	if args and not isinstance(args, tuple):
		args = (args, )
	thread.start_new_thread(target, args, kwargs)

def start_new_thread2(target=None, args=(), kwargs={}):
	if args and not isinstance(args, tuple):
		args = (args, )
	threading.Thread(target=target, args=args, kwargs=kwargs).start()
