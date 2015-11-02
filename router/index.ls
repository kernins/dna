crossroads = require \crossroads/dist/crossroads
hasher = require \hasher
{ any, keys, find, each, Obj } = require \prelude-ls

## hasher.raw = yes
hasher.prepend-hash = \!
hasher.init!

open = ->
   log 'router.open', it
   if browser.name is \safari or browser.name is \ios
      hasher.set-hash encodeURI it
   else
      hasher.set-hash it

router = crossroads.create! <<<<
   greedy:no

routeGroups = {}
class RouteGroup
   (id=null)->
      @id = id==null && Math.floor(Math.random()*10e12) || id
      @routes = []

   add: (route)->
      @routes.push route
      return @
   dispose: ->
      log 'disposing route group', @id
      @routes |> each (r)!->
         if typeof r.dispose == \function
            log 'removing route', r
            r.dispose()


hasher.changed.add ~>
   router.parse it

module.exports =
   clear: ->
      router.remove-all-routes!

   add: (routes, grpId=null) -> ##grpId may be string or int, defaults to random int
      if !routes then throw 'No routes given'
      if grpId and routeGroups[grpId] then throw 'RouteGroup with id "'+grpId+'" already exists'

      group = new RouteGroup grpId
      routeGroups[group.id] = group

      routes |> Obj.keys |> each (path)~>
         if routes[path] instanceof Array
            if typeof routes[path][0] isnt \function then throw 'Invalid route "'+path+'": handler must be a function'
            r = routes[path][0]
            p = routes[path][1] or 0
         else 
            if typeof routes[path] isnt \function then throw 'Invalid route "'+path+'": handler must be a function'
            r = routes[path]
            p = 0
         group.add(router.add-route ((path.char-at 0) is \^) && (new RegExp path) || path, r, p)

      current-hash = hasher.get-hash!
      router.reset-state!
      router.parse current-hash
      log 'routeGroups', routeGroups
      return group.id

   remove: (grpId) !->
      if !routeGroups.hasOwnProperty grpId then throw 'There is no RouteGroup with ID '+grpId
      routeGroups[grpId].dispose()
      delete routeGroups[grpId]

   default: (handler)!->
      router.bypassed.add(handler)


   open: open
  