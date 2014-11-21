ig = window.ig
init = ->
  tooltip = new Tooltip!watchElements!
  ig.dir = dir = (window.location.hash.substr 1) || "praha-prestupky"
  container = d3.select ig.containers.base
  map = new ig.Map ig.containers.base
    ..drawHeatmap dir
  (err, data) <~ d3.text "../data/processed/#dir/typy.tsv"
  ig.typy = typy = for text, id in data.split "\n"
    {text, id}
  infobar = new ig.Infobar container, typy
  map
    ..on \selection infobar~draw
    ..on \markerClicked infobar~clearFilters
  heatmapLastPointList = null
  mapTimeout = null
  lastHeatCall = 0
  throttleHeatmap = (pointList) ->
    heatmapLastPointList := pointList
    return if mapTimeout isnt null
    nextCall = Math.max do
      lastHeatCall - Date.now! + 500
      0
    mapTimeout := setTimeout do
      ->
        map.drawFilteredHeatmap heatmapLastPointList
        lastHeatCall := Date.now!
        mapTimeout := null
      nextCall

  infobar
    ..on \updatedPoints throttleHeatmap
    ..on \selectionCancelled map~cancelSelection
  geocoder = new ig.Geocoder ig.containers.base
    ..on \latLng (latlng) ->
      map.map.setView latlng, 18
      map.onMapChange!
if d3?
  init!
else
  $ window .bind \load ->
    if d3?
      init!
