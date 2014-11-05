
window.ig.Map = class Map
  (parentElement) ->
    mapElement = document.createElement 'div'
      ..id = \map
    window.ig.Events @
    parentElement.appendChild mapElement
    if "praha" is ig.dir.substr 0, 5
      bounds =
        x: [14.263 14.689]
        y: [49.952 50.171]
      maxBounds = [[49.94,14.24], [50.18,14.7]]
    else
      bounds =
        x: [16.475 16.716]
        y: [49.124 49.289]
      maxBounds = [[49.11 16.46] [49.30 16.74]]

    @map = L.map do
      * mapElement
      * minZoom: 6,
        maxZoom: 18,
        zoom: 12,
        center: [(bounds.y.0 + bounds.y.1) / 2, (bounds.x.0 + bounds.x.1) / 2]
        maxBounds: maxBounds

    baseLayer = L.tileLayer do
      * "https://samizdat.cz/tiles/ton_b1/{z}/{x}/{y}.png"
      * zIndex: 1
        opacity: 1
        attribution: 'mapová data &copy; přispěvatelé <a target="_blank" href="http://osm.org">OpenStreetMap</a>, obrazový podkres <a target="_blank" href="http://stamen.com">Stamen</a>, <a target="_blank" href="https://samizdat.cz">Samizdat</a>'

    labelLayer = L.tileLayer do
      * "https://samizdat.cz/tiles/ton_l1/{z}/{x}/{y}.png"
      * zIndex: 3
        opacity: 0.75

    @map.addLayer baseLayer
    @map.addLayer labelLayer
    @initSelectionRectangle!
    document.addEventListener "keydown" (evt) ~>
      if evt.ctrlKey
        @enableSelectionRectangle!
    document.addEventListener "keyup" (evt) ~>
      if !evt.ctrlKey
        @disableSelectionRectangle!

  drawHeatmap: (dir) ->
    (err, data) <~ d3.tsv "../data/processed/#dir/grouped.tsv", (line) ->
      line.x = parseFloat line.x
      line.y = parseFloat line.y
      line.typ = parseInt line.typ, 10
      line.count = parseInt line.count, 10
      line
    # data .= filter -> -1 != window.ig.typy[it.typ].indexOf "rychlost"
    latLngs = for item in data
      latlng = L.latLng item.y, item.x
        ..alt = item.count
      latlng

    options =
      radius: 8
    L.heatLayer latLngs, options
      ..addTo @map


  initSelectionRectangle: ->
    @selectionRectangleDrawing = no
    @selectionRectangle = L.rectangle do
      * [0,0], [0, 0]
    @selectionRectangle.addTo @map

  enableSelectionRectangle: ->
    @selectionRectangleEnabled = yes
    @map
      ..dragging.disable!
      ..on \mousedown (evt) ~>
        @selectionRectangleDrawing = yes
        @startLatlng = evt.latlng
      ..on \mousemove (evt) ~>
        return unless @selectionRectangleDrawing
        @endLatlng = evt.latlng
        @selectionRectangle.setBounds [@startLatlng, @endLatlng]
        @setSelection [[@startLatlng.lat, @startLatlng.lng], [@endLatlng.lat, @endLatlng.lng]]
      ..on \mouseup ~>
        @selectionRectangleDrawing = no

  disableSelectionRectangle: ->
    @selectionRectangleEnabled = no
    @map
      ..dragging.enable!
      ..off \mousedown
      ..off \mousemove
      ..off \mouseup

  setSelection: (bounds) ->
    # L.rectangle bounds
    #   ..addTo @map
    @emit \selection bounds

