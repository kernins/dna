{ keys, map, join, obj-to-lists, Str, Obj } = require \prelude-ls

## wrap = (str,obj) ->
##   names = ((obj |> Obj.filter -> typeof! it is \Object) |> keys)
##   ctx-names = (names |> map -> "this.#it") |> Str.join \,
##   "(function (#{names |> Str.join \, }){ return (#{str}); }).bind(this)(#{ctx-names})"

## wrap = (str,obj) ->
##   "(function ($scope){ return (#{str}); }).bind(this)(this)"

eval-in = (ctx = window, js = '', args = {}) -->
  [names, values] = (args |> obj-to-lists)
  js = js.trim!
  return if not js 
  names.push \$scope
  values.push ctx
  names = names |> map -> "\"#{it}\""
  fn = eval "new Function( #{ names |> join \, }, \" return (#{ js })\") "
  fn.apply ctx, values

find-parent-scope = (element) ->
  scope = void
  if element
    do
      element = element.parent-node
      scope = element?.scope
    until not element or scope?
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
