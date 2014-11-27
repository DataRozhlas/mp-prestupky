require! {
  parse: "csv-parse"
  fs
  async
  diacritics
}

# file = "brno_prest_6_13_9_14"
# targetDir = "brno-prestupky"

# file = "brno_odtahy_6_13_9_14"
# targetDir = "brno-odtahy"

# file = "praha_odtah_6_13_5_14"
# targetDir = "praha-odtahy"

# file = "praha_prest_6_13_5_14"
# targetDir = "praha-prestupky"

file = "praha_prest_6_13_5_14"
targetDir = "praha-rychlost"

# file = "teplice_odtahy"
# targetDir = "teplice-odtahy"


stream = fs.createReadStream "#__dirname/../data/#file.csv"
reader = parse {delimiter: ','}
stream.pipe reader

isRychlost = 'rychlost' is targetDir.split '-' .1
out = {}
typIndices = {}
currentTypIndex = 0
reader.on \data (line) ->
  if 'praha_prest_6_13_5_14' == file
    [..._, spachano,oblast,addr,ulice,cislo,typ,x,y] = line
  else
    [..._, spachano,_,typ,_,x,y] = line
  return if x == 'X'
  x = parseFloat x
  # x -= 0.0011
  y = parseFloat y
  # y -= 0.00074
  return unless x > 0 and y > 0
  x .= toFixed 5
  y .= toFixed 5
  # typ = diacritics.remove typ
  typ .= toLowerCase!
  typ .= replace /[^a-z0-9]/gi ''
  typ .= replace /s/g 'z'
  typId = if typIndices[typ]
    that
  else
    currentTypIndex++
    i = currentTypIndex
    typIndices[typ] = i
    i
  id = [x, y].join "\t"
  if !isRychlost or -1 != typ.indexOf 'rychlozt'
    out[id] = out[id] + 1 || 1

<~ reader.on \end
output = for id, count of out
  id += "\t#count"
console.log "writing #{output.length} lines"
output.unshift "x\ty\tcount"
<~ fs.writeFile "#__dirname/../data/processed/#targetDir/grouped.tsv" output.join "\n"
