{ each, keys, Obj } = require \prelude-ls

observed = (obj) ->
  if obj.has-own-property \__isObserved
    obj
  else
    obj.__is-observed = yes

    obj |> keys |> each (key)->
      if (typeof! obj[key]) is \Array
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
                @ ->
                  obj.emit "splice #{key}", obj[key], ev
                , 1

    Object.observe obj, ->
      obj.emit \update, it
      it |> each (o) ->
        set-timeout ->
          obj.emit "#{o.type} #{o.name}", o.object?[o.name], o.old-value
        , 1
    obj


module.exports = observed
