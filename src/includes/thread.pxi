# thread.pxi

def start_new_thread(target, *args, **kwargs):
	threading.Thread(target=target, args=args, kwargs=kwargs).start()
