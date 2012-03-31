libxml = require 'libxmljs'
fs     = require 'fs'

filename = 'jawiki-latest-pages-articles.xml'
stack = []
parser = new libxml.SaxPushParser()
rs = fs.createReadStream filename, encoding: 'utf8'
title_ws = fs.createWriteStream 'pages.txt', encoding: 'utf8'
link_ws  = fs.createWriteStream 'links.txt',  encoding: 'utf8'
[id, title, text] = ['', '', '']
[title_d, link_d] = [true, true]

rs.on 'data', (chunk) ->
  parser.push chunk if chunk
  process.stdout.write "\r#{id}\ttitle_d: #{title_d} \tlink_d: #{link_d}"

rs.on 'end', () ->
  process.stdout.write "\n"

title_ws.on 'drain', () ->
  title_d = true
  rs.resume() if title_d && link_d

link_ws.on 'drain', () ->
  link_d = true
  rs.resume() if title_d && link_d

parser.on 'startElementNS', (elem, attrs, prefix, uri, namespaces) ->
  stack.push elem

parser.on 'endElementNS', (elem, prefix, uri) ->
  stack.pop()
  title = title.replace /\s/g, '_'
  if elem == 'page'
    res = text.match /\#REDIRECT \[\[([^\]\#]+)[^\]]*\]\]/m
    if res
      str = res[1].replace /\s/g, '_'
      if! title_ws.write "#{id} #{title} 1\n"
        title_d = false 
        rs.pause()
    else
      if !title_ws.write "#{id} #{title} 0\n"
        title_d = false 
        rs.pause()
      res = text.match /\[\[([^\]\#\|]+)[^\]]*\]\]/gm
      if res
        tmp = ''
        for str in res
          str = str.match(/\[\[([^\]\#\|]+)[^\]]*\]\]/m)[1]
          str = str.replace /\s/g, '_'
          tmp += "#{id} #{str}\n"
        if !link_ws.write tmp
          link_d = false 
          rs.pause()
    [id, title, text] = ['', '', '']

parser.on 'warning', (warning) ->
  console.warn "WARNING: #{warning}"

parser.on 'error', (error) ->
  console.error "ERROR: #{error}"

parser.on 'characters', (chars) ->
  if !stack[3]
    if stack[2] == 'title'
      title += chars
    else if stack[2] == 'id'
      id += chars
  else if stack[2] == 'revision' && stack[3] == 'text'
    text += chars
