{ each, keys, Obj } = require \prelude-ls

observe-array = (obj, key) ->
  if Array.observe  # Chromium
    Array.observe obj[key], ~>
      it |> each (ev) ->
        set-timeout ->
          obj.emit "#{ev.type} #{key}", ev.object, ev
        , 1
  else
    Object.observe obj[key], ~>
      it |> each (ev) ->
        if ev.name is \length
          set-timeout ->
            obj.emit "splice #{key}", obj[key], ev
          , 1

observed = (obj) ->
  return if typeof! obj isnt \Object
  
  if obj.has-own-property \__isObserved
    obj
  else
    Object.define-property obj, '__isObserved', do
                           enumerable: no
                           configurable: no
                           writable: no
                           value: yes
                           

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
