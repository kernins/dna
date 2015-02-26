eval-in = (ctx, js) --> ((-> "#{js}" |> eval).call ctx)

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
