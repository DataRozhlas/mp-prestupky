require! {
  parse: "csv-parse"
  fs
  async
}
stream = fs.createReadStream "#__dirname/../data/praha_prest_6_13_5_14.csv"
reader = parse {delimiter: ','}
stream.pipe reader

minX = Infinity
maxX = -Infinity

minY = Infinity
maxY = -Infinity
i = 0
out = {}
finish = (cb) ->
  files = for id, data of out
    {id, data}
  console.log "Saving #{files.length} files"
  saved = 0
  <~ async.eachLimit files, 20, ({id, data}, cb) ->
    saved += data.split "\n" .length
    <~ fs.writeFile "#__dirname/../data/processed/tiles/#{id}.tsv", data
    process.nextTick cb
  console.log "Saved #saved lines"
  cb!
lines = 0
typIndices = {}
currentTypIndex = 0
reader.on \data (line) ->
  [..._, spachano,oblast,addr,ulice,cislo,typ,x,y] = line
  return if x == 'x'
  x = parseFloat x
  x -= 0.0011
  x .= toFixed 5
  y = parseFloat y
  y -= 0.00074
  y .= toFixed 5
  return unless x and y
  xIndex = (Math.floor x / 0.01)
  yIndex = (Math.floor y / 0.005)
  spachano = spachano.substr 2, 8
  typId = if typIndices[typ]
    that
  else
    currentTypIndex++
    i = currentTypIndex
    typIndices[typ] = i
    i
  id = "#{xIndex}-#{yIndex}"
  lines++
  out[id] ?= 'typ\tx\ty\tspachano'
  out[id] += "\n#typId\t#x\t#y\t#spachano"

<~ reader.on \end
console.log "Found #lines records"
typy = ["typy"]
for typ, index of typIndices
  typy[index] = typ
fs.writeFile "#__dirname/../data/processed/typy.tsv", typy.join "\n"
<~ finish!
