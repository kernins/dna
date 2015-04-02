{ map, each, keys, unique, initial, Str } = require \prelude-ls
clone = require \../clone
Scope = require \../scope

default-attrs = require \./attrs

apply-attr = (element, attrs, key) ->
  element.$$dna-attrs = element.$$dna-attrs or {}

  if not (element.$$dna-attrs[key])
      element.$$dna-attrs[key] = yes
      expr = element.get-attribute key
      scope = (element |> Scope::$get)

      try
        if attrs[key]
          new that element, scope, expr
      catch e
        console.error "[apply-attr] #{key} = #{expr}", element, e
          

module.exports = (element, user-attrs = {}) ->
  attrs = {} <<<< default-attrs <<<< user-attrs

  attrs |> keys |> each (key) ->
    if element.has-attribute key
      apply-attr element, attrs, key

    (element.query-selector-all "[#{key}]") |> each ->
      apply-attr it, attrs, key
    
