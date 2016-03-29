crossroads = require \crossroads/dist/crossroads
hasher = require \hasher
{each, Obj} = require \prelude-ls


router = crossroads.create! <<<< {greedy:no}

## hasher.raw = yes
hasher.prependHash = '!'
hasher.changed.add !~> (router.parse it)
hasher.init!

lastRouted=null
router.routed.add (request, info)!-> (lastRouted = {request, info})


routeGroups = {}
class RouteGroup
   (id=null)->
      @id = id==null && Math.floor(Math.random()*10e12) || id
      @routes = []

   add: (route)->
      @routes.push route
      return @
   dispose: ->
      #log 'disposing route group', @id
      @routes |> each (r)!->
         if typeof(r.dispose)=='function'
            #log 'removing route', r
            r.dispose()



module.exports =
   getCurrentHash: ->
      hasher.getHash!

   getLastRouted: ->
      lastRouted


   add: (routes, grpId=null, appendIfGroupExists=false, doRoute=true) -> ##grpId may be string or int, defaults to random int
      if !routes then throw 'No routes to add given'
      if grpId and routeGroups[grpId]
         if !appendIfGroupExists then throw 'RouteGroup with id "'+grpId+'" already exists'
         group = routeGroups[grpId]
      else 
         group = new RouteGroup grpId
         routeGroups[group.id] = group

      routes |> Obj.keys |> each (path)~>
         if routes[path] instanceof Array
            if typeof(routes[path][0])!='function' then throw 'Invalid route "'+path+'": handler must be a function'
            r = routes[path][0]
            p = routes[path][1] or 0
         else 
            if typeof(routes[path])!='function' then throw 'Invalid route "'+path+'": handler must be a function'
            r = routes[path]
            p = 0
         group.add(router.addRoute ((path.charAt 0)=='^') && (new RegExp path) || path, r, p)

      #log 'routeGroups', routeGroups
      if doRoute then @route!
      return group.id

   remove: (grpId) !->
      if !routeGroups.hasOwnProperty grpId then throw 'There is no RouteGroup with ID '+grpId
      routeGroups[grpId].dispose()
      delete routeGroups[grpId]

   clear: !->
      router.removeAllRoutes!


   route: !->
      router.resetState!
      router.parse @getCurrentHash!


   default: (handler)!->
      if typeof(handler)!='function' then throw 'DNA.Router.default(): invalid callback - function expected, '+typeof(handler)+' given'
      router.bypassed.add(handler)

   onRouted: (handler)!->
      if typeof(handler)!='function' then throw 'DNA.Router.onRouted(): invalid callback - function expected, '+typeof(handler)+' given'
      router.routed.add(handler)


   open: !->
      #log 'router.open', it
      if (browser.name=='safari') || (browser.name=='ios') then hasher.setHash (encodeURI it)
      else hasher.setHash it
