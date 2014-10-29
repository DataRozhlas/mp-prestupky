bounds =
  x: [14.2633323501339 14.6895150599435]
  y: [49.9529729169694 50.1716609107504]

window.ig.Map = class Map
  (parentElement) ->
    mapElement = document.createElement 'div'
      ..id = \map
    window.ig.Events @
    parentElement.appendChild mapElement
    @map = L.map do
      * mapElement
      * minZoom: 6,
        maxZoom: 17,
        zoom: 16,
        # center: [(bounds.y.0 + bounds.y.1) / 2, (bounds.x.0 + bounds.x.1) / 2]
        center: [50.03815124242662, 14.339518547058107]
        maxBounds: [[48.4,11.8], [51.2,18.9]]

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
    # @map.addLayer labelLayer
    @initSelectionRectangle!

  drawHeatmap: ->
    (err, data) <~ d3.tsv "../data/processed/grouped.tsv", (line) ->
      line.x = parseFloat line.x
      line.y = parseFloat line.y
      line.typ = parseInt line.typ, 10
      line.count = parseInt line.count, 10
      line
    latLngs = for item in data
      latlng = L.latLng item.y, item.x
        ..alt = item.count
      latlng

    L.heatLayer latLngs, radius: 7
      ..addTo @map


  initSelectionRectangle: ->
    @selectionRectangleDrawing = no
    @selectionRectangle = L.rectangle do
      * [bounds.y.0, bounds.x.0], [bounds.y.1, bounds.x.1]
    @selectionRectangle.addTo @map
    @map
      ..dragging.disable!
      ..on \mousedown (evt) ~>
        @selectionRectangleDrawing = yes
        @startLatlng = evt.latlng
      ..on \mousemove (evt) ~>
        return unless @selectionRectangleDrawing
        @endLatlng = evt.latlng
        @selectionRectangle.setBounds [@startLatlng, @endLatlng]
      ..on \mouseup ~>
        @selectionRectangleDrawing = no
        @setSelection [[@startLatlng.lat, @startLatlng.lng], [@endLatlng.lat, @endLatlng.lng]]
        # console.log [@startLatlng.lat, @startLatlng.lng], [@endLatlng.lat, @endLatlng.lng]

    # @map.addLayer L.rectangle do
    #   * [bounds.y.0, bounds.x.0], [bounds.y.1, bounds.x.1]

  setSelection: (bounds) ->
    # L.rectangle bounds
    #   ..addTo @map
    @emit \selection bounds

