{ map, each, keys, unique, initial, Str } = require \prelude-ls

clone = require \clone

Scope = require \../dna-scope

observed = require \../dna-observed

objs-list = (expr) ->
  vars = expr.match /(this(?:\.[a-zA-Z\_0-9]+)*)/g
  objs = vars |> map ->
     it |> (Str.split \.) |> initial |> Str.join \.
  objs |> unique

default-attrs =

  'dna-click' : (element,scope,expr) ->
    element.on \click, ->
      scope.$eval expr

  'dna-hover' : (element,scope,expr) ->
    element.on \hover, ->
      scope.$eval expr

  'dna-text' : (element, scope, expr) ->
    set = -> element.inner-text = scope.$eval expr
    set!
    expr |> objs-list |> each ->
      (it |> scope.$eval |> observed)
        .on \update, ->
          set!

  'dna-html' : (element, scope, expr) ->
    set = -> element.inner-text = scope.$eval expr
    set!
    expr |> objs-list |> each ->
      (it |> scope.$eval |> observed)
        .on \update, ->
          set!

  'dna-model' : (element, scope, expr) ->
    set = -> element.scope.model = scope.$eval expr
    if element.scope
      if typeof! (scope.$eval expr) in <[ Object Array ]>
        set!
      else
        set!
        expr |> objs-list |> each ->
          (it |> scope.$eval |> observed).on \update, -> set!


apply-attr = (element, attr) ->
  element.$dna-attrs = element.$dna-attrs or []

  if not (attr in element.$dna-attrs)
    element.$dna-attrs.push attr
    expr = element.get-attribute attr
    scope = (element |> Scope.$parent)

    if @attrs[attr]
      new @attrs[attr](element, scope, expr)

module.exports = (attrs = {}, element) -->
  @attrs = (clone default-attrs) <<<< attrs
  @attrs |> keys |> each (key) ->
    if element.has-attribute key
      apply-attr element, key
      
    (element.query-selector-all "[#{key}]") |> each (el) ->
      apply-attr el, key
    
