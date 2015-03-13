crossroads = require \crossroads
hasher = require \hasher
{ any, keys, find, each, Obj } = require \prelude-ls

hasher.raw = yes
hasher.init!

open = ->
  if browser.name is \safari or browser.name is \ios
      hasher.set-hash encodeURI it
  else
      hasher.set-hash it

router = crossroads.create! <<<<
                          greedy:yes

module.exports = 

  add: (routes) ->

    if routes
      routes |> Obj.keys |> each (path) ~>
            if (path.char-at 0) is \^ 
                     rx = new RegExp path
                     router.add-route rx, routes[path]
            else
              router.add-route path, routes[path]

      router.parse hasher.get-hash!
      hasher.changed.add ~> router.parse it

  open: open


