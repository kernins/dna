#
# default attrs
#

{ map, each, keys, unique, initial, last, Str } = require \prelude-ls

observed = require \../observed

computed-style = require \computed-style

var-str = -> it |> (Str.split \.) |> last

initial-str = -> it |> (Str.split \.) |> initial |> Str.join \.

objs-list = ($expr) ->
  vars = $expr.match /(this(?:\.[a-zA-Z0-9_\[\]]+)*)/g
  objs = vars |> map ->
     it |> initial-str
  objs |> unique

clean-element = (element) ->
  if element?.tag-name
    while element.first-child
      element.remove-child element.first-child

render-fn = ($element, $scope, $template = '') ->
  clean-element $element

  $element.innerHTML = do ~>
       | typeof! $template is \String   => $template
       | typeof! $template is \Function => $scope |> $template
       | _                              => ''
       
  try 
    $element.trigger \rendered
  catch
    console.warn '[render-fn] There is no eddy or other event emitter'

module.exports = 

  \dna-click : ($element,$scope,$expr) ->
    $element.on \click, ->
      $scope.$eval $expr

  \dna-hover : ($element,$scope,$expr) ->
    $element.on \hover, ->
      $scope.$eval $expr

  \dna-submit : ($element,$scope,$expr) ->
    $element.on \submit, ->
      $scope.$eval $expr
      it.prevent-default!

  \dna-key-enter : ($element,$scope,$expr) ->
    $element.on \keydown, ->
      if it.key-code is 13
        $scope.$eval $expr

  \dna-select-fn : ($element, $scope, $expr) ->  #TODO think more about *-fn and parameters
    $element.on 'select', ->
      if typeof! (fn = $scope.$eval $expr) is \Function
        fn ...

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
    if /^this\.?([a-z0-9_\.\[\]]+)?\.([a-z0-9_]+)$/gim == $expr #TODO whitespaces
      [path, svar] = [that.1, that.2]
      parent =
          | path? => $scope.$eval "this.#path"
          | _ => $scope
          
      $element.tag-name |> ~>
      
        | \INPUT is it => do ->
            set-model = -> parent[svar] = it
            set-value = ->
              if $element.value != it
                $element.value = it
              
            if parent[svar]?
              $element.value = that
            else if $element.value?
              parent[svar] = that

            (parent |> observed)
              .on "update #svar", ->
                set-value it
              
            $element
              .on \change, ->
                set-model $element.value
              .on \keyup, ->
                set-model $element.value  #TODO not only keyup and not every
              
            
        | \SELECT is it => do ->
            set-model = -> parent[svar] = it
            set-value = -> $element.value = it
            
            if parent[svar]?
              $element.value = that
            else if $element.value?
              parent[svar] = that
              
            $element
              .on \change, -> set-model $element.value
            (parent |> observed)
              .on "update #svar", -> set-value it


            
    else      
      throw "[dna-bind] Invalid model: #{$expr}"
      

  \dna-model : ($element, $scope, $expr) ->  #TODO Test it
    set = ->
      $element.scope?.model = $scope.$eval $expr
    if typeof! ($scope.$eval $expr) in <[ Object Array ]>
      set!
    else
      set!
      obj = $scope.$eval ($expr |> initial-str)
      var-name = ($expr |> var-str)
      if obj and var-name
        (obj |> observed)
          .on "update #{var-name}", ->
            set!
            
      ## $expr |> objs-list |> each ->
      ##   (it |> $scope.$eval |> observed).on \update, ->
      ##     set!
          
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

  \dna-show : ($element, $scope, $expr) ->
    display-style = computed-style $element, \display
    set = ->
      if $scope.$eval "(#{$expr})"
        $element.style.display = display-style or \block
      else
        $element.style.display = \none

    set!
    $expr |> objs-list |> each ->  # TODO test on "this.value" with not observed this
      (it |> $scope.$eval |> observed)
        .on \update, ->
          set!
          
  \dna-template : ($element, $scope, $expr) ->
    ## console.log \dna-template
    if $template = $scope.$eval $expr
      $element.template = $template
      $element.render = (template = $element.template) ->
                             render-fn $element, $scope, $template
      set-timeout ->
        $element.render!
      , 50 # TODO test it with controller

  \dna-controller : ($element, $scope, $expr) ->
    ## console.log \dna-controller
    if Ctrl = ($scope.$eval $expr)
      set-timeout ~>
        $element.controller = new Ctrl $element $scope
      , 50 # TODO test to all-attrs initialized before this
      
  \dna-render-on-splice : ($element, $scope, $expr) ->
    ## console.log \dna-render-on-splice
    if /^this\.?([a-z0-9_\.]+)?\.([a-z0-9_]+)$/gim == $expr #TODO whitespaces
      [path, svar] = [that.1, that.2]
      parent =
          | path => $scope.$eval "this.#path"
          | _ => $scope
      
      if typeof! (array = $scope.$eval $expr) is \Array
        (parent |> observed)
          .on "splice #{svar}", -> $element.render?!
      else
        throw "[dna-render-on-splice] Not an Array: #{$expr}"
    else
      throw "[dna-render-on-splice] Invalid model: #{$expr}"
      
  \dna-render-on-update : ($element, $scope, $expr) ->
    ## console.log \dna-render-on-update
    if /^this\.?([a-z0-9_\.]+)?\.([a-z0-9_]+)$/gim == $expr #TODO whitespaces
      [path, svar] = [that.1, that.2]
      parent =
          | path => $scope.$eval "this.#path"
          | _ => $scope
      
      if typeof! (array = $scope.$eval $expr) in <[String Number Boolean]>
        (parent |> observed)
          .on "update #{svar}", -> $element.render?!
      else
        throw "[dna-render-on-update] Not an simple variable: #{$expr}"
    else
      throw "[dna-render-on-update] Invalid model: #{$expr}"
      
