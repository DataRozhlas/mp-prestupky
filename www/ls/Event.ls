# Kudos 2 https://github.com/allouis/minivents
window.ig.Events = (target = null) ->
  events = {}
  target ?= @

  target.on = (type, func) ->
    events[type] ?= []
    events[type].push func

  target.off = (type, func) ->
    list = events[type]
    if func
      i = list.length = func ? list.length : 0
      while(i-- > 0)
        if func == list[i] then list.splice i, 1
    else
      list.length = 0

  target.emit = (type, ...args) ->
    list = events[type] || []
    for cb in list
      cb ...args
