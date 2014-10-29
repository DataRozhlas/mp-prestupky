window.ig.Infobar = class Infobar
  (parentElement, @typy) ->
    @element = parentElement.append \div
      ..attr \class \infobar
    @total = @element.append \span
      ..attr \class \total
    @initTimeHistogram!

  initTimeHistogram: ->
    @timeHistogram = [0 til 24].map -> value: 0
    @timeHistogramElm = @element.append \div
      ..attr \class "histogram time"
    @timeHistogramBars = @timeHistogramElm.selectAll \div.bar .data @timeHistogram .enter!append \div
      ..attr \class \bar
    @timeHistogramBarFills = @timeHistogramBars.append \div
      ..attr \class \fill


  draw: (bounds) ->
    (err, data) <~ downloadBounds bounds
    @total.html data.length
    @reset!
    for line in data
      if line.date
        @timeHistogram[line.date.getHours!].value++
    timeHistogramMax = d3.max @timeHistogram.map (.value)
    @timeHistogramBarFills
      ..style \height ->
        "#{it.value / timeHistogramMax * 100}%"


  reset: ->
    for item in @timeHistogram
      item.value = 0


downloadBounds = (bounds, cb) ->
  xBounds = [bounds.0.1, bounds.1.1]
  yBounds = [bounds.0.0, bounds.1.0]
  [xBounds, yBounds].forEach -> it.sort (a, b) -> a - b
  files = getRequiredFiles xBounds, yBounds
  (err, lines) <~ downloadFiles files
  inboundLines = lines.filter ({x, y}) ->
    xBounds.0 < x < xBounds.1 and yBounds.0 < y < yBounds.1
  cb err, inboundLines


downloadFiles = (files, cb) ->
  (err, data) <- async.map files, (file, cb) ->
    d3.tsv do
      "../data/processed/tiles/#file"
      (line) ->
        if line.spachano
          [year, month, day, hour] =
            parseInt (line.spachano.substr 0, 2), 10
            parseInt (line.spachano.substr 2, 2), 10
            parseInt (line.spachano.substr 4, 2), 10
            parseInt (line.spachano.substr 6, 2), 10
          line.date = new Date!
            ..setTime 0
            ..setFullYear year
            ..setMonth month - 1
            ..setDate day
            ..setHours hour
        line.x = parseFloat line.x
        line.y = parseFloat line.y
        # TODO: typ, spachano date
        line
      cb
  all = [].concat ...data
  cb null, all




getRequiredFiles = (x, y) ->
  xIndices = x.map getXIndex
  yIndices = y.map getYIndex
  files = []
  for xIndex in [xIndices.0 to xIndices.1]
    for yIndex in [yIndices.0 to yIndices.1]
      files.push "#{xIndex}-#{yIndex}.tsv"
  files


getXIndex = -> Math.floor it / 0.01
getYIndex = -> Math.floor it / 0.005
