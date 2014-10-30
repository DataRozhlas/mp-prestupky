window.ig.Infobar = class Infobar
  (parentElement, typy) ->
    @typy = typy.map -> {name: it, value: 0}
    @element = parentElement.append \div
      ..attr \class \infobar
    @total = @element.append \span
      ..attr \class \total
    @initTimeHistogram!
    @initDayHistogram!
    @initTypy!


  initTimeHistogram: ->
    @timeHistogram = [0 til 24].map -> value: 0
    @timeHistogramElm = @element.append \div
      ..attr \class "histogram time"
    timeHistogramBars = @timeHistogramElm.selectAll \div.bar .data @timeHistogram .enter!append \div
      ..attr \class \bar
    @timeHistogramBarFills = timeHistogramBars.append \div
      ..attr \class \fill


  initDayHistogram: ->
    @dayHistogram = [0 til 7].map -> value: 0
    @dayHistogramElm = @element.append \div
      ..attr \class "histogram day"
    dayHistogramBars = @dayHistogramElm.selectAll \div.bar .data @dayHistogram .enter!append \div
      ..attr \class \bar
    @dayHistogramBarFills = dayHistogramBars.append \div
      ..attr \class \fill

  initTypy: ->
    @typyElm = @element.append \ol
      ..attr \class \typy

  draw: (bounds) ->
    (err, data) <~ downloadBounds bounds
    @total.html data.length
    @reset!
    for line in data
      if line.date
        if line.hasHours
          h = line.date.getHours!
          @timeHistogram[h].value++
        day = line.date.getDay! - 1
        if day == -1 then day = 6 # nedele na konec tydne
        @dayHistogram[day].value++
      @typy[line.typId].value++
    @redrawTimeHistogram!
    @redrawDayHistogram!
    @redrawTypy!


  redrawTimeHistogram: ->
    timeHistogramMax = d3.max @timeHistogram.map (.value)
    @timeHistogramBarFills
      ..style \height ->
        "#{it.value / timeHistogramMax * 100}%"


  redrawDayHistogram: ->
    dayHistogramMax = d3.max @dayHistogram.map (.value)
    @dayHistogramBarFills
      ..style \height ->
        "#{it.value / dayHistogramMax * 100}%"


  redrawTypy: ->
    usableTypy = @typy.filter (.value > 0)
    usableTypy.sort (a, b) -> b.value - a.value
    height = 24px
    for typ, index in usableTypy
      typ.index = index
    max = d3.sum usableTypy.map (.value)
    @typyElm.selectAll \li .data usableTypy
      ..enter!append \li
        ..append \span
          ..attr \class \name
          ..html (.name)
        ..append \div
          ..attr \class \fill
      ..exit!remove!
      ..style \top -> "#{it.index * height}px"
      ..select \div.fill
        ..style \width -> "#{it.value / max * 100}%"


  reset: ->
    for field in [@timeHistogram, @dayHistogram, @typy]
      for item in field
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
    (err, data) <~ d3.tsv do
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
          if !isNaN hour
            line.date.setHours hour
            line.hasHours = yes
        line.x = parseFloat line.x
        line.y = parseFloat line.y
        line.typId = parseInt line.typ, 10
        # TODO: typ, spachano date
        line
    cb null, data || []
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
