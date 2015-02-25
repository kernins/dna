{ map, each, keys, unique, initial, Str } = require \prelude-ls

clone = require \clone

Scope = require \../dna-scope

default-attrs = require \./attrs

apply-attr = ($element, attr) ->
  $element.__dna-attrs = $element.__dna-attrs or {}

  if not ($element.__dna-attrs[attr])
    $element.__dna-attrs[attr] = yes
    $expr = $element.get-attribute attr
    $scope = ($element |> Scope.$parent)

    if @attrs[attr]
      new @attrs[attr]($element, $scope, $expr)

module.exports = (attrs = {}, $element) -->
  @attrs = (clone default-attrs) <<<< attrs
  @attrs |> keys |> each (key) ->
    if $element.has-attribute key
      apply-attr $element, key
      
    ($element.query-selector-all "[#{key}]") |> each (el) ->
      apply-attr el, key
    
