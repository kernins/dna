{ map, each, keys, unique, initial, Str } = require \prelude-ls

default-attrs = require \./attrs

apply-attr = require \./apply-attr

module.exports = (element, user-attrs = {}) ->

  attrs = {} <<<< default-attrs <<<< user-attrs

  attrs |> keys |> each (key) ->
    if element.has-attribute key
      apply-attr element, attrs, key

    (element.query-selector-all "[#{key}]") |> each ->
      apply-attr it, attrs, key
    
