require! {
  parse: "csv-parse"
  fs
  async
}
file = "praha_odtah_6_13_5_14"
targetDir = "praha-odtahy"

stream = fs.createReadStream "#__dirname/../data/#file.csv"
reader = parse {delimiter: ','}
stream.pipe reader

minX = Infinity
maxX = -Infinity

minY = Infinity
maxY = -Infinity

out = {}
typIndices = {}
currentTypIndex = 0
reader.on \data (line) ->
  [..._,typ,x,y] = line
  return if x == 'x'
  x = parseFloat x
  x -= 0.0011
  x .= toFixed 5
  y = parseFloat y
  y -= 0.00074
  y .= toFixed 5
  return unless x and y
  typId = if typIndices[typ]
    that
  else
    currentTypIndex++
    i = currentTypIndex
    typIndices[typ] = i
    i
  id = [x, y, typId].join "\t"
  out[id] = out[id] + 1 || 1

<~ reader.on \end
output = for id, count of out
  id += "\t#count"
console.log "writing #{output.length} lines"
output.unshift "x\ty\ttyp\tcount"
<~ fs.writeFile "#__dirname/../data/processed/#targetDir/grouped.tsv" output.join "\n"
