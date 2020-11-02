# dict.pxi

def reverse_dict(dictionary):
  return {value: key for key, value in items(dictionary)}

def encoded(value):
  if isinstance(value, unicode):
    return value.encode('cp1252', 'ignore')
  return value

def decoded(value):
  if isinstance(value, bytes):
    return value.decode('cp1252')
  return value

def decode_dict(dictionary):
  return {decoded(key): decoded(value) for key, value in items(dictionary)}
