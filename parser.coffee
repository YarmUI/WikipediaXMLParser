libxml = require 'libxmljs'
fs     = require 'fs'

#filename = 'jawiki-latest-pages-articles.xml'
filename = 'test.xml'
stack = []
parser = new libxml.SaxPushParser()
rs = fs.createReadStream filename, {encoding: 'utf8', bufferSize: 1024*1024}
red_ws   = fs.createWriteStream 'redirect.txt', {encoding: 'utf8'}
title_ws = fs.createWriteStream 'title.txt', {encoding: 'utf8'}
link_ws  = fs.createWriteStream 'link.txt', {encoding: 'utf8'}
[id, title, text] = ['', '', '']
[red_d, title_d, link_d] = [true, true, true]
index = 0

rs.on 'data', (chunk) ->
  parser.push chunk if chunk
  process.stdout.write "\r#{index}\tred_d: #{red_d} \ttitle_d: #{title_d} \tlink_d: #{link_d}"
  rs.pause() if !red_d || !title_d || !link_d

red_ws.on 'drain', () ->
  red_d = true
  rs.resume() if red_d && title_d && link_d

title_ws.on 'drain', () ->
  title_d = true
  rs.resume() if red_d && title_d && link_d

link_ws.on 'drain', () ->
  link_d = true
  rs.resume() if red_d && title_d && link_d

parser.on 'startElementNS', (elem, attrs, prefix, uri, namespaces) ->
  stack.push elem

parser.on 'endElementNS', (elem, prefix, uri) ->
  stack.pop()
  title = title.replace /\s/g, '_'
  if elem == 'page'
    res = text.match /\#REDIRECT \[\[([^\]\#]+)[^\]]*\]\]/m
    if res
      str = res[1].replace /\s/g, '_'
      red_d = false if !red_ws.write "#{title} #{str}\n"
    else
      title_d = false if !title_ws.write "#{id} #{index} #{title}\n"
      res = text.match /\[\[([^\]\#\|]+)[^\]]*\]\]/gm
      if res
        tmp = ''
        for str in res
          str = str.match(/\[\[([^\]\#\|]+)[^\]]*\]\]/m)[1]
          str = str.replace /\s/g, '_'
          tmp += "#{index} #{str}\n"
        link_d = false if !link_ws.write tmp
      index += 1

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
