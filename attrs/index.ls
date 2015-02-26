{ map, each, keys, unique, initial, Str } = require \prelude-ls
clone = require \clone
Scope = require \../scope

default-attrs = require \./attrs

apply-attr = (element, attrs, key) ->
  ## console.log \apply-attr, element, attrs, key
  element.$$dna-attrs = element.$$dna-attrs or {}

  if not (element.$$dna-attrs[key])
    element.$$dna-attrs[key] = yes
    expr = element.get-attribute key
    scope = (element |> Scope::$get)

    if attrs[key]
      new that element, scope, expr

module.exports = (element, user-attrs = {}) ->
  attrs = {} <<<< default-attrs <<<< user-attrs

  attrs |> keys |> each (key) ->
    if element.has-attribute key
      apply-attr element, attrs, key

    (element.query-selector-all "[#{key}]") |> each ->
      apply-attr it, attrs, key
    
