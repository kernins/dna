clone = require \clone

eval-in = (ctx, js) --> ((-> "#{js}" |> eval).call ctx)

find-parent-scope = (element) ->
  scope = void
  if element
    do
      element = element.parent-node
      scope = element?.scope
    until not element or scope?
    scope

Scope = (element, props = {}) ->
  self = @
  if element
    S = (props) ->
      @$parent = (el = element) -> (el |> find-parent-scope)
      @$eval = eval-in @
      @ <<<< props

    if parent-scope = (element |> find-parent-scope)
      S.prototype = parent-scope
      
    return (new S props)

# helper method to find parent scope without (new Scope!)
Scope.$parent = find-parent-scope

module.exports = Scope
