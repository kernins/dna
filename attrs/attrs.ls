#
# default attrs
#

{ map, each, keys, unique, initial, last, Str } = require \prelude-ls

observed = require \../observed

computed-style = require \computed-style

var-str = -> it |> (Str.split \.) |> last

initial-str = -> it |> (Str.split \.) |> initial |> Str.join \.

objs-list = ($expr) ->
  vars = $expr.match /(this(?:\.[a-zA-Z0-9_\[\]\'\"]+)*)/g  # TODO more inteligent parsing
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

  \x-click : ($element,$scope,$expr) ->
    $element.on \click, ($event)->
      $scope.$eval $expr

  \x-hover : ($element,$scope,$expr) ->
    $element.on \hover, ->
      $scope.$eval $expr

  \x-blur : ($element,$scope,$expr) ->
    $element.on \blur, ->
      set-timeout ->
        $scope.$eval $expr
      , 300


  \x-submit : ($element,$scope,$expr) ->
    $element.on \submit, ->
      $scope.$eval $expr
      it.prevent-default!

  \x-key-enter : ($element,$scope,$expr) ->
    $element.on \keydown, ->
      if it.key-code is 13
        $scope.$eval $expr

  \x-keydown : ($element,$scope,$expr) ->
    $element.on \keydown, ->
      $scope.$eval $expr #TODO $event
      ## if typeof! ($scope.$eval $expr) is \Function
      ##   console.log \KEYDOWN, that
        
  \x-keyup : ($element,$scope,$expr) ->
    $element.on \keyup, ($event)-> 
      $scope.$eval $expr #TODO $event

  \x-select-fn : ($element, $scope, $expr) ->  #TODO think more about *-fn and parameters
    $element.on 'select', ->
      if typeof! (fn = $scope.$eval $expr) is \Function
        fn ...

  \x-text : ($element, $scope, $expr) ->
    set = ->
     ($scope.$eval $expr) |> ~>
          $element.inner-text = it 
          $element.text-content = it
          
    $expr |> objs-list |> each ->
      (it |> $scope.$eval |> observed)
        .on \update, ->
          set!
    set-timeout ~>
      set!
    , 1 # workaround
          

  \x-html : ($element, $scope, $expr) ->
    set = -> $element.inner-html = $scope.$eval $expr
    set!
    $expr |> objs-list |> each ->
      (it |> $scope.$eval |> observed)
        .on \update, ->
          set!

  \x-bind : ($element, $scope, $expr) ->
    if /^this\.?([a-z0-9_\.\[\]]+)?\.([a-z0-9_]+)$/gim == $expr #TODO whitespaces
      [path, svar] = [that.1, that.2]
      parent =
          | path? => $scope.$eval "this.#path"
          | _ => $scope

      obj = parent[svar]
          
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
              
        | \FORM is it => do ->
            ## console.log \FORM, obj, $expr
            ## form2js = require \form2js
            ## if typeof! obj isnt \Object
            ##   throw "[x-bind] FORM need Object as model"
            ## set-model = ->
            ## set-value = ->
            ## $element.on 'change', ->
            ##   console.log it, $element
            ##   console.log (form2js)


    else      
      throw "[dna-bind] Invalid model: #{$expr}"
      
  \x-model : ($element, $scope, $expr) ->  #TODO Test it
    set = ->
      $element.scope?.model = $scope.$eval $expr
    if typeof! ($scope.$eval $expr) in <[ Object Array ]>
      set!
    else
      obj = $scope.$eval ($expr |> initial-str)
      var-name = ($expr |> var-str)
      if obj and var-name
        (obj |> observed)
          .on "update #{var-name}", ->
            set!
      set-timeout ~>
        set!
      , 1 # workaround for FF on slow render with disabled console
            
      ## $expr |> objs-list |> each ->
      ##   (it |> $scope.$eval |> observed).on \update, ->
      ##     set!
          
  \x-class : ($element, $scope, $expr) ->
    set = ->
      expr = $scope.$eval "(#{$expr})"
      for key, value of expr
        if value
          $element.class-list.add key
        else
          $element.class-list.remove key
    set-timeout ~>
      set!
    , 1 # workaround for FF on slow render with disabled console
    
    $expr |> objs-list |> each ->  # TODO test on "this.value" with not observed this
      (it |> $scope.$eval |> observed)
        .on \update, ->
          set!

  \x-show : ($element, $scope, $expr) ->
    display-style = computed-style $element, \display
    set = ->
      if $scope.$eval "(#{$expr})"
        $element.style.display = display-style or \block
      else
        $element.style.display = \none

    $expr |> objs-list |> each ->  # TODO test on "this.value" with not observed this
      (it |> $scope.$eval |> observed)
        .on \update, ->
          set!
    set-timeout ~>
      set!
    , 1 # workaround for FF on slow render with disabled console

  \x-disabled : ($element, $scope, $expr) ->
    set = ->
      if $scope.$eval "(#{$expr})"
        $element.set-attribute \disabled, ''
      else
        $element.remove-attribute \disabled

    $expr |> objs-list |> each ->  # TODO test on "this.value" with not observed this
      (it |> $scope.$eval |> observed)
        .on \update, ->
          set!
    set-timeout ~>
      set!
    , 1 # workaround for FF on slow render with disabled console
          

  \x-template : ($element, $scope, $expr) ->
    if $template = $scope.$eval $expr
      $element.template = $template
      $element.render = (template = $element.template) ->
                             render-fn $element, $scope, $template
      set-timeout ->
        $element.render!
      , 50 # TODO test it with controller

  \x-controller : ($element, $scope, $expr) ->
    ## console.log \x-controller
    if Ctrl = ($scope.$eval $expr)
      set-timeout ~>
        $element.controller = new Ctrl $element $scope
      , 50 # TODO test to all-attrs initialized before this
      
  \x-render-on-splice : ($element, $scope, $expr) ->
    ## console.log \x-render-on-splice
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
      
  \x-render-on-update : ($element, $scope, $expr) ->
    ## console.log \x-render-on-update
    if /^this\.?([a-z0-9_\.]+)?\.([a-z0-9_]+)$/gim == $expr #TODO whitespaces
      [path, svar] = [that.1, that.2]
      parent =
          | path => $scope.$eval "this.#path"
          | _ => $scope
      
      ## if typeof! (array = $scope.$eval $expr) in <[String Number Boolean]>
      (parent |> observed)
        .on "update #{svar}", -> $element.render?!
      ## else
      ##   throw "[dna-render-on-update] Not an simple variable: #{$expr}"
    else
      throw "[dna-render-on-update] Invalid model: #{$expr}"
      
