window.ig.Infobar = class Infobar
  (parentElement, typy) ->
    ig.Events @
    @typy = typy.map -> {name: it.text, id: it.id, value: 0}
    @typyAssoc = @typy.slice!
    @element = parentElement.append \div
      ..attr \class "infobar nodata"
    @heading = @element.append \h2
    @heading.html if ig.dir.split "-" .1 == "odtahy"
      "Statistiky odtahů"
    else
      "Statistiky přestupků"
    @heading.append \span
      ..attr \class \cancel
      ..html "<br>zrušit výběr"
      ..on \click ~>
        @emit \selectionCancelled
        @clearFilters!
        @drawWithData []
    @element.append \span
      ..attr \class \subtitle
      ..html "Kliknutím vyberte část města, která vás zajímá. Velikost výběru můžete změnit tlačítkem ◰ vlevo&nbsp;nahoře."
    totalElm = @element.append \span
      ..attr \class \total
    @total = totalElm.append \span
      ..attr \class \value
      ..html "0"
    @prestupkuVybranoElm = totalElm.append \span
      ..attr \class \suffix
      ..html " přestupků vybráno"

    @timeFilters = []
    @dateFilters = []
    @typFilters  = []
    @initTimeHistogram!
    @initDayHistogram!
    @initTypy!

  initTimeHistogram: ->
    @timeHistogram = [0 til 24].map -> value: 0
    histogramContainer = @element.append \div
      ..attr \class "histogram-container"
      ..append \h3
        ..html "V kolik hodin se odtahuje"
    @timeHistogramElm = histogramContainer.append \div
      ..attr \class "histogram time"
    @timeHistogramBars = @timeHistogramElm.selectAll \div.bar .data @timeHistogram .enter!append \div
      ..attr \class \bar
      ..on \click (d, i) ~> @toggleTimeFilter i
      ..append \span
        ..attr \class \legend
        ..html (d, i) -> i
    @timeHistogramBarFillsUnfiltered = @timeHistogramBars.append \div
      ..attr \class "fill bg"
    @timeHistogramBarFills = @timeHistogramBars.append \div
      ..attr \class \fill
      ..attr \data-tooltip "Kliknutím vyberte hodinu"

  toggleTimeFilter: (startHour) ->
    index = @timeFilters.indexOf startHour
    if -1 isnt index
      @timeFilters.splice index, 1
    else
      @timeFilters.push startHour
    @updateFilteredView!

  toggleDateFilter: (day) ->
    index = @dateFilters.indexOf day
    if -1 isnt index
      @dateFilters.splice index, 1
    else
      @dateFilters.push day
    @updateFilteredView!

  toggleTypFilter: (typ) ->
    typId = typ.id
    if typ.isFiltered
      @typFilters.splice do
        @typFilters.indexOf typId
        1
    else
      @typFilters.push typId
    typ.isFiltered = !typ.isFiltered
    @updateFilteredView!

  clearFilters: ->
    @timeFilters.length = 0
    @dateFilters.length = 0
    @typFilters.length = 0

  updateFilteredView: ->
    @refilter!
    @recomputeGraphs!
    @refilterTimeHistogram!
    @refilterDayHistogram!
    @refilterTypy!
    @emit \updatedPoints @filteredData

  refilter: ->
    timeFiltersLen = @timeFilters.length
    dateFiltersLen = @dateFilters.length
    typFiltersLen  = @typFilters.length
    @filteredData = @fullData.filter (datum) ~>
      if timeFiltersLen
        return false unless datum.hasHours
        return false if datum.date.getHours! not in @timeFilters
      if dateFiltersLen
        return false unless datum.date
        return false if datum.day not in @dateFilters
      if typFiltersLen
        return false if datum.typId not in @typFilters
      return true

  initDayHistogram: ->
    dny = <[Po Út St Čt Pá So Ne]>
    @dayHistogram = [0 til 7].map -> value: 0
    histogramContainer = @element.append \div
      ..attr \class "histogram-container"
      ..append \h3
        ..html "Které dny v týdnu se odtahuje"
    @dayHistogramElm = histogramContainer.append \div
      ..attr \class "histogram day"
    dayHistogramBars = @dayHistogramElm.selectAll \div.bar .data @dayHistogram .enter!append \div
      ..attr \class \bar
      ..on \click (d, i) ~> @toggleDateFilter i
      ..append \div
        ..attr \class \legend
        ..html (d, i) -> dny[i]
    @dayHistogramBarFillsUnfiltered = dayHistogramBars.append \div
      ..attr \class "fill bg"
    @dayHistogramBarFills = dayHistogramBars.append \div
      ..attr \class \fill
      ..attr \data-tooltip "Kliknutím vyberte den"

  initTypy: ->
    typyCont = @element.append \div
      ..attr \class \typy
      ..append \h3
        ..html if ig.dir.split "-" .1 == "odtahy" then "Nejčastější důvody odtahů" else "Nejčastější přestupky"

    @typyElm = typyCont.append \ol
      ..attr \class \typy

  draw: (bounds) ->
    @element.classed \nodata no
    (err, data) <~ downloadBounds bounds
    @drawWithData data

  drawWithData: (data) ->
    @filteredData = @fullData = data
    if @fullData.length == 0
      @element.classed \nodata yes
    @recomputeGraphs!
    for typ in @typy
      typ.fullValue = typ.value
    @redrawGraphs!
    if @timeFilters.length || @dateFilters.length || @typFilters.length
      @updateFilteredView!
    else
      @emit \updatedPoints @filteredData


  recomputeGraphs: ->
    total = @filteredData.length
    @total.html ig.utils.formatNumber total
    @prestupkuVybranoElm.html switch
    | 5 > total > 1 => " přestupky vybrány"
    | total == 1 => " přestupek vybrán"
    | otherwise => " přestupků vybráno"
    @reset!
    for line in @filteredData
      if line.date
        if line.hasHours
          h = line.date.getHours!
          @timeHistogram[h].value++
        @dayHistogram[line.day].value++
      @typyAssoc[line.typId].value++

  redrawGraphs: ->
    @redrawTimeHistogram!
    @redrawDayHistogram!
    @redrawTypy!

  redrawTimeHistogram: ->
    @timeHistogramMax = d3.max @timeHistogram.map (.value) or 1
    @timeHistogramBarFillsUnfiltered
      ..style \height ~>
        "#{it.value / @timeHistogramMax * 100}%"
    @refilterTimeHistogram!

  refilterTimeHistogram: ->
    @timeHistogramBarFills
      ..style \height ~>
        "#{it.value / @timeHistogramMax * 100}%"

  redrawDayHistogram: ->
    @dayHistogramMax = d3.max @dayHistogram.map (.value) or 1
    @dayHistogramBarFillsUnfiltered
      ..style \height ~>
        "#{it.value / @dayHistogramMax * 100}%"
    @refilterDayHistogram!

  refilterDayHistogram: ->
    @dayHistogramBarFills
      ..style \height ~>
        "#{it.value / @dayHistogramMax * 100}%"

  redrawTypy: ->
    usableTypy = @typy.filter (.value > 0)
    usableTypy.sort (a, b) -> b.value - a.value
    height = 24px
    for typ, index in usableTypy
      typ.index = index
    @typyMax = d3.sum usableTypy.map (.value)
    @typyElm.selectAll \li .data usableTypy
      ..enter!append \li
        ..append \span
          ..attr \class \name
          ..html (.name)
        ..append \div
          ..attr \class "fill bg"
        ..append \div
          ..attr \class "fill fg"
        ..on \click ~> @toggleTypFilter it
      ..exit!remove!
      ..style \top -> "#{it.index * height}px"
      ..attr \data-tooltip ->
          "#{it.name} (#{it.value}x)
          <br><em>Kliknutím vyberte typ přestupku</em>"
      ..select \div.fill.bg
        ..style \width ~> "#{it.value / @typyMax * 100}%"
      ..select \div.fill.fg
        ..style \width ~> "#{it.value / @typyMax * 100}%"

  refilterTypy: ->
    height = 24px
    @typy.sort (a, b) ->
      | b.value - a.value => that
      | b.fullValue - a.fullValue => that
      | otherwise => 0
    for typ, index in @typy
      typ.index = index
    @typyElm.classed \filtered @typFilters.length
    @typyElm.selectAll \li
      ..style \top -> "#{it.index * height}px"
      ..classed \filtered (.isFiltered)
      ..select \div.fill.fg
        ..style \width ~> "#{it.value / @typyMax * 100}%"

  reset: ->
    for field in [@timeHistogram, @dayHistogram, @typy]
      for item in field
        item.value = 0

currBounds = null
downloadBounds = (bounds, cb) ->
  xBounds = [bounds.0.1, bounds.1.1]
  yBounds = [bounds.0.0, bounds.1.0]
  [xBounds, yBounds].forEach -> it.sort (a, b) -> a - b
  files = getRequiredFiles xBounds, yBounds
  currBounds := [xBounds, yBounds]
  (err, lines) <~ downloadFiles files
  return if lines is null
  inboundLines = lines.filter ({x, y}) ->
    currBounds.0.0 < x < currBounds.0.1 and currBounds.1.0 < y < currBounds.1.1
  cb err, inboundLines

cache = {}
downloadFiles = (files, cb) ->
  id = files.join '+'
  if cache[id] isnt void
    cb null, cache[id]
  else
    cache[id] = null
    (err, data) <- async.map files, (file, cb) ->
      (err, data) <~ d3.tsv do
        "../data/processed/#{ig.dir}/tiles/#file"
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
            line.day = line.date.getDay! - 1
            if line.day == -1 then line.day = 6 # nedele na konec tydne
          line.x = parseFloat line.x
          line.y = parseFloat line.y
          line.typId = parseInt line.typ, 10
          # TODO: typ, spachano date
          line
      cb null, data || []
    all = [].concat ...data
    cache[id] = all
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
