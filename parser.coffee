libxml = require 'libxmljs'
fs     = require 'fs'

#filename = 'jawiki-latest-pages-articles.xml'
filename = 'test.xml'
stack = []
parser = new libxml.SaxPushParser()
rs = fs.createReadStream(filename, {encoding: 'utf8', bufferSize: 4*1024*1024})

rs.on 'data', (chunk) ->
  parser.push chunk if chunk
  
[id, title, text] = ['', '', '']
index = 0

parser.on 'startElementNS', (elem, attrs, prefix, uri, namespaces) ->
  stack.push elem

parser.on 'endElementNS', (elem, prefix, uri) ->
  stack.pop()
  if elem == 'page'
    res = text.match /\#REDIRECT \[\[([^\]\#]+)[^\]]*\]\]/m
    if res
      console.log title + ' => ' + res[1]
    else
      res = text.match /\[\[([^\]\#\|]+)[^\]]*\]\]/gm
      if res
        res = for str in res
          str.match(/\[\[([^\]\#\|]+)[^\]]*\]\]/m)[1]

    [id, title, text] = ['', '', '']
    index += 1

parser.on 'warning', (warning) ->
  console.warn 'WARNING' + warning

parser.on 'error', (error) ->
  console.error 'ERROR: ' + error

parser.on 'characters', (chars) ->
  if !stack[3]
    if stack[2] == 'title'
      title += chars
    else if stack[2] == 'id'
      id += chars
  else if stack[2] == 'revision' && stack[3] == 'text'
    text += chars
