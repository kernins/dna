{keys, map, obj-to-lists, Str, Obj} = require \prelude-ls

## wrap = (str,obj) ->
##   names = ((obj |> Obj.filter -> typeof! it is \Object) |> keys)
##   ctx-names = (names |> map -> "this.#it") |> Str.join \,
##   "(function (#{names |> Str.join \, }){ return (#{str}); }).bind(this)(#{ctx-names})"

## wrap = (str,obj) ->
##   "(function ($scope){ return (#{str}); }).bind(this)(this)"

eval-in = (ctx, js) -->
  ((-> "#{js}" |> eval).call ctx)

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

Scope::$eval = (js) -> eval-in @, js

Scope::$get = (element) ->
  if element.scope
    return that
  else
    find-parent-scope element

Scope::$parent = -> @::

module.exports = Scope
