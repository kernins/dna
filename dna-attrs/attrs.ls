{ map, each, keys, unique, initial, Str } = require \prelude-ls

observed = require \../dna-observed

objs-list = ($expr) ->
  vars = $expr.match /(this(?:\.[a-zA-Z0-9_\[\]]+)*)/g
  objs = vars |> map ->
     it |> (Str.split \.) |> initial |> Str.join \.
  objs |> unique

module.exports = 

  \dna-click : ($element,$scope,$expr) ->
    $element.on \click, ->
      $scope.$eval $expr

  \dna-hover : ($element,$scope,$expr) ->
    $element.on \hover, ->
      $scope.$eval $expr

  \dna-text : ($element, $scope, $expr) ->
    set = -> $element.inner-text = $scope.$eval $expr
    set!
    $expr |> objs-list |> each ->
      (it |> $scope.$eval |> observed)
        .on \update, ->
          set!

  \dna-html : ($element, $scope, $expr) ->
    set = -> $element.inner-html = $scope.$eval $expr
    set!
    $expr |> objs-list |> each ->
      (it |> $scope.$eval |> observed)
        .on \update, ->
          set!

  \dna-bind : ($element, $scope, $expr) ->
    if /^this\.?([a-z0-9_\.]+)?\.([a-z0-9_]+)$/gim == $expr #TODO whitespaces
      [path, svar] = [that.1, that.2]
      parent =
          | path => $scope.$eval "this.#path"
          | _ => $scope
          
      $element.tag-name |> ~>
      
        | \INPUT is it => do ->
            set-model = -> parent[svar] = it
            set-value = -> $element.value = it
            
            $element
              .on \change, -> set-model $element.value
              .on \keyup, -> set-model $element.value  #TODO not only keyup and not every
            (parent |> observed)
              .on "update #svar", -> set-value it
            
        | \SELECT is it => do ->
            set-model = -> parent[svar] = it
            set-value = -> $element.value = it
            
            $element
              .on \change, -> set-model $element.value
            (parent |> observed)
              .on "update #svar", -> set-value it
            

    else      
      throw "[dna-bind] Invalid model: #{$expr}"
      

  \dna-model : ($element, $scope, $expr) ->  #TODO Test it
    set = -> $element.$scope.model = $scope.$eval $expr
    if $element.scope  
      if typeof! ($scope.$eval $expr) in <[ Object Array ]>
        set!
      else
        set!
        $expr |> objs-list |> each ->
          (it |> $scope.$eval |> observed).on \update, -> set!
          
  \dna-class : ($element, $scope, $expr) ->
    set = ->
      expr = $scope.$eval "(#{$expr})"
      for key, value of expr
        if value
          $element.class-list.add key
        else
          $element.class-list.remove key
    set!
    $expr |> objs-list |> each ->  # TODO test on "this.value" with not observed this
      (it |> $scope.$eval |> observed)
        .on \update, ->
          set!
