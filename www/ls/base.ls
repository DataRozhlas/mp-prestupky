ig = window.ig
init = ->
  typy = for line in window.ig.data.typy.split "\n"
    line
  container = d3.select ig.containers.base
  map = new ig.Map ig.containers.base
    ..drawHeatmap!
  infobar = new ig.Infobar container, typy
  map
    ..on \selection infobar~draw
    ..setSelection [[50.04110381590842 14.339] [50.0385 14.34316635131836]]
if d3?
  init!
else
  $ window .bind \load ->
    if d3?
      init!
