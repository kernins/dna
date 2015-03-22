{ each, keys, Obj } = require \prelude-ls

observe-array = (obj, key)->  #TODO update observation on hard Array updates
  if Array.observe  # Chromium
    Array.observe obj[key], ~>
      it |> each (ev) ->
        set-timeout ->
          obj.emit "#{ev.type} #{key}", ev.object, ev
        , 1
  else              # Other browserers
    Object.observe obj[key], ~>
      it |> each (ev) ->
        if ev.name is \length
          set-timeout ->
            obj.emit "splice #{key}", obj[key], ev
          , 1

observed = (obj) ->
  if obj.has-own-property \__isObserved
    obj
  else
    obj.__is-observed = yes

    obj |> keys |> each (key) ->
      if (typeof! obj[key]) is \Array
        observe-array obj, key

    Object.observe obj, ->
      obj.emit \update, it
      it |> each (o) ->
        if (typeof! o.object[o.name]) is \Array and o.type is \update
            observe-array obj, o.name
        set-timeout ->
          obj.emit "#{o.type} #{o.name}", o.object?[o.name], o.old-value
        , 1
    obj

module.exports = observed
