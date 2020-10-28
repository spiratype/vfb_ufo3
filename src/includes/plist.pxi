# plist.pxi

def parse_plist(plist):

  parsed = {}
  for line in plist.splitlines():
    if '<string>' in line:
      str_element = parse_xml_element(line)
      array.append(str_element)
      continue
    if '<key>' in line:
      key = parse_xml_element(line)
      continue
    if '<array>' in line:
      array = []
      continue
    if '</array>' in line:
      parsed[key] = array
      continue

  return parsed

def parse_xml_element(line):
  return line.split('</')[0].split('>')[1:][0]
