{ map, each, keys, unique, initial, Str } = require \prelude-ls

clone = require \clone

Scope = require \../dna-scope

observed = require \../dna-observed

objs-list = (expr) ->
  vars = expr.match /(this(?:\.[a-zA-Z0-9_]+)*)/g
  objs = vars |> map ->
     it |> (Str.split \.) |> initial |> Str.join \.
  objs |> unique

default-attrs =

  'dna-click' : (element,$scope,expr) ->
    element.on \click, ->
      $scope.$eval expr

  'dna-hover' : (element,$scope,expr) ->
    element.on \hover, ->
      $scope.$eval expr

  'dna-text' : (element, $scope, expr) ->
    set = -> element.inner-text = $scope.$eval expr
    set!
    expr |> objs-list |> each ->
      (it |> $scope.$eval |> observed)
        .on \update, ->
          set!

  'dna-html' : (element, $scope, expr) ->
    set = -> element.inner-text = $scope.$eval expr
    set!
    expr |> objs-list |> each ->
      (it |> $scope.$eval |> observed)
        .on \update, ->
          set!

  'dna-bind' : (element, $scope, expr) ->
    console.log \dna-bind, element.tag-name, expr
    if /^this\.?([a-z0-9_\.]+)?\.([a-z0-9_]+)$/gim == expr
      [path, svar] = [that.1, that.2]
      parent =
          | path => $scope.$eval "this.#path"
          | _ => $scope
          
      element.tag-name |> ~>
        | it is \INPUT => do ->
            set-model = -> parent[svar] = it
            set-value = -> element.value = it
            
            element
              .on \change, -> set-model element.value
              .on \keyup, -> set-model element.value
            (parent |> observed)
              .on "update #svar", -> set-value it
            
        | it is \SELECT => do ->
            set-model = -> parent[svar] = it
            set-value = -> element.value = it
            
            element
              .on \change, -> set-model element.value
            (parent |> observed)
              .on "update #svar", -> set-value it
            

    else      
      throw "[dna-bind] Invalid model: #{expr}"
      

  'dna-model' : (element, $scope, expr) ->
    set = -> element.$scope.model = $scope.$eval expr
    if element.$scope
      if typeof! ($scope.$eval expr) in <[ Object Array ]>
        set!
      else
        set!
        expr |> objs-list |> each ->
          (it |> $scope.$eval |> observed).on \update, -> set!


apply-attr = (element, attr) ->
  element.$dna-attrs = element.$dna-attrs or []

  if not (attr in element.$dna-attrs)
    element.$dna-attrs.push attr
    expr = element.get-attribute attr
    $scope = (element |> Scope.$parent)

    if @attrs[attr]
      new @attrs[attr](element, $scope, expr)

module.exports = (attrs = {}, element) -->
  @attrs = (clone default-attrs) <<<< attrs
  @attrs |> keys |> each (key) ->
    if element.has-attribute key
      apply-attr element, key
      
    (element.query-selector-all "[#{key}]") |> each (el) ->
      apply-attr el, key
    
