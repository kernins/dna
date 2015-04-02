{ keys, map, join, obj-to-lists, Str, Obj } = require \prelude-ls

## wrap = (str,obj) ->
##   names = ((obj |> Obj.filter -> typeof! it is \Object) |> keys)
##   ctx-names = (names |> map -> "this.#it") |> Str.join \,
##   "(function (#{names |> Str.join \, }){ return (#{str}); }).bind(this)(#{ctx-names})"

## wrap = (str,obj) ->
##   "(function ($scope){ return (#{str}); }).bind(this)(this)"

eval-in = (ctx = window, js = '', args = {}) -->
  try
    [names, values] = (args |> obj-to-lists)
    js = js.trim!
    return if not js 
    names.push \$scope
    values.push ctx
    names = names |> map -> "\"#{it}\""
    fn = eval "new Function( #{ names |> join \, }, \" return (#{ js })\") "
    return fn.apply ctx, values
  catch e
    console.error "[Scope] eval-in: ", ctx, js, args, e
    return null

find-parent-scope = (element) ->
  scope = void
  current = element
  if current
    do
      current = current.parent-node
      scope = current?.scope
    until not current or scope?
    scope

Scope = (props = {}) ->
  (@ <<<< props)

Scope::$new = (props) ->
  parent = @
  
  S = (props = {}) ->
    @$parent = parent
    (@ <<<< props)
    
  S:: = parent
  
  new S props

Scope::$eval = (js, args = {}) -> eval-in @, js, args

Scope::$get = (element) ->
  if element.scope
    return that
  else
    find-parent-scope element

Scope::$parent = -> @::

module.exports = Scope
