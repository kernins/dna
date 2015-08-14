#
# default attrs
#

{ map, each, keys, unique, initial, last, Str } = require \prelude-ls

observed = require \../observed

computed-style = require \computed-style

apply-attr = require \./apply-attr

var-str = -> it |> (Str.split \.) |> last

initial-str = -> it |> (Str.split \.) |> initial |> Str.join \.

objs-list = ($expr) ->
  vars = $expr.match //
                     (?:^|[^a-z0-9_$\.])
                     ((?:[a-z_$][a-z0-9_$]+\.)+[a-z0-9_$]+)
                     (?:$|[^a-z0-9_$\.])
                     //gi
  vars = (vars |> map -> it.replace /[^a-z0-9_$\.]/gi, '')
  return [] if not vars
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
       
  $element.rendered = yes
  set-timeout ~>
    try
      $element.emit \rendered
    catch
      console.warn '[render-fn] There is no eddy or other event emitter'
  , 150

module.exports = default-attrs =

  \x-click : ($element,$scope,$expr) ->
    $element.on \click, ($event)->
      $scope.$eval $expr

  \x-hover : ($element,$scope,$expr) ->
    $element.on \hover, ->
      $scope.$eval $expr

  \x-focus : ($element,$scope,$expr) ->
    $element.on \focus, ->
      set-timeout ->
        $scope.$eval $expr
      , 300      

  \x-blur : ($element,$scope,$expr) ->
    $element.on \blur, ->
      set-timeout ->
        $scope.$eval $expr
      , 300
      
  \x-submit : ($element,$scope,$expr) ->
    $element.on \submit, ->
      $element.elements |> each ->
                        if it.tag-name?.to-lower-case! is \input
                          it.emit \change
      $scope.$eval $expr
      it.prevent-default!

  \x-key-enter : ($element,$scope,$expr) ->
    $element.on \keydown, ->
      if it.key-code is 13
        $scope.$eval $expr

  \x-keydown : ($element,$scope,$expr) ->
    $element.on \keydown, (ev) ->
      $scope.$eval $expr, (\$event : ev)
        
  \x-keyup : ($element,$scope,$expr) ->
    $element.on \keyup, (ev) -> 
      $scope.$eval $expr, (\$event : ev)

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
        .on \update, ->  # TODO 'update var'
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

  \x-href : ($element, $scope, $expr) ->
    set = -> $element.set-attribute \href, ($scope.$eval $expr)
    
    $expr |> objs-list |> each ->
      (it |> $scope.$eval |> observed)
        .on \update, ->
          set!
          
    set!
          

  \x-bind : ($element, $scope, $expr) ->
    
    if // 
       ^\s*
       ((?:[a-z_$][a-z0-9_$\[\]\'\"]+\.?)+)  # some.path
       [\.]                                  # .
       ((?:[a-z_$][a-z0-9_$\[\]\'\"]*))      # variable
       \s*$
       //gim == $expr  
       
      [path, svar] = [that.1, that.2]
      parent =
          | path? => $scope.$eval "#path"
          | _ => $scope

      obj = parent[svar]
          
      $element.tag-name.to-lower-case! |> ~>
      
        | \input is it or \textarea is it => do ->
            set-model = ->
              parent[svar] = it
              
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
              
            
        | \select is it => do ->
            
            set-model = ->
              parent[svar] = it
              
            set-value = ->
              $element.value = it
            
            if parent[svar]?
              $element.value = that
            else if $element.value?
              parent[svar] = that
              
            $element
              .on \change, ->
                set-model $element.value
                
            (parent |> observed)
              .on "update #svar", ->
                if $element.value != "#{it}"
                  set-value it
              
        | \form is it => do ->
            ## form2js = require \form2js
            ## if typeof! obj isnt \Object
            ##   throw "[x-bind] FORM need Object as model"
            ## set-model = ->
            ## set-value = ->
            ## $element.on 'change', ->


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

  \x-style : ($element, $scope, $expr) ->
    set = ->
      expr = $scope.$eval "(#{$expr})"
      
      for key, value of expr
        $element.style[key] = value
    set-timeout ~>
      set!
    , 1 # workaround for FF on slow render with disabled console
    $expr |> objs-list |> each ->  # TODO test on "this.value" with not observed this
      (it |> $scope.$eval |> observed)
        .on \update, ->
          set!

  \x-show : ($element, $scope, $expr) ->

    display-style = computed-style $element, \display
    if display-style is \none
      display-style = \block
      
    set = ->
      if $scope.$eval $expr
        $element.style.display = display-style or \block
      else
        $element.style.display = \none


    $expr |> objs-list |> each ->  # TODO test on "this.value" with not observed this
                # 
        (it |> $scope.$eval |> observed)
          .on \update, ->
            set!
    set-timeout ~>
      set!
    , 1 # workaround for FF on slow render with disabled console

  \x-visible : ($element, $scope, $expr) ->
    set = ->
      if $scope.$eval $expr
        $element.style.visibility = \visible
      else
        $element.style.visibility = \hidden

    $expr |> objs-list |> each ->  
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

      $element
        .on \rendered, ~>
          attrs = {} <<<< default-attrs 

          attrs |> keys |> each (key) ->
            ($element.query-selector-all "[#{key}]") |> each ->
              apply-attr it, attrs, key

      set-timeout ->
        $element.render!
      , 100 # TODO test it with controller
      $element.emit \x-template

  \x-controller : ($element, $scope, $expr) ->
    if Ctrl = ($scope.$eval $expr)
      set-timeout ~>
        $element.controller = new Ctrl $element, $scope
      , 50 # TODO test to all-attrs initialized before this
      
  \x-render-on-splice : ($element, $scope, $expr) ->
    if // 
       ^\s*
       ((?:[a-z_$][a-z0-9_$\[\]\'\"]+\.?)+)  # some.path
       [\.]                                  # .
       ((?:[a-z_$][a-z0-9_$\[\]\'\"]*))      # variable
       \s*$
       //gim == $expr

      [path, svar] = [that.1, that.2]
      
      parent =
          | path => $scope.$eval path
          | _ => $scope
      
      if typeof! (array = $scope.$eval $expr) is \Array
        (parent |> observed)
          .on "splice #{svar}", -> $element.render?!
      else
        throw "[dna-render-on-splice] Not an Array: #{$expr}"
    else
      throw "[dna-render-on-splice] Invalid model: #{$expr}"
      
  \x-render-on-update : ($element, $scope, $expr) ->
    if //
       ^\s*
       ((?:[a-z_$][a-z0-9_$\[\]\'\"]+\.?)+)
       [\.]
       ((?:[a-z_$][a-z0-9_$\[\]\'\"]*)+)
       \s*$
       //gim == $expr
    
      [path, svar] = [that.1, that.2]

      parent =
          | path => $scope.$eval "#path"
          | _ => $scope
      
      ## if typeof! (array = $scope.$eval $expr) in <[String Number Boolean]>
      (parent |> observed)
        .on "update #{svar}", -> $element.render?!
      ## else
      ##   throw "[dna-render-on-update] Not an simple variable: #{$expr}"
    else
      throw "[dna-render-on-update] Invalid model: #{$expr}"

  \x-validate-expr : ($element, $scope, $expr) ->
    rx = new RegExp $expr, \i

    validate = ->
      if $scope.$eval $expr
        $element.class-list.remove \invalid
        $element.class-list.add \valid        
      else
        $element.class-list.add \invalid
        $element.class-list.remove \valid        
    
    if $element.tag-name is \INPUT
      $element.on \keyup, -> validate!
      $element.on \change, -> validate!
      $element.on \blur, -> validate!
      
      
  \x-validate : ($element, $scope, $expr) ->
    rx = new RegExp $expr, \i

    validate = ->
      if (rx.test $element.value)
        $element.class-list.remove \invalid
        $element.class-list.add \valid        
      else
        $element.class-list.add \invalid
        $element.class-list.remove \valid        
    
    if $element.tag-name is \INPUT
      $element.on \keyup, -> validate!
      $element.on \change, -> validate!
      $element.on \blur, -> validate!

  \x-drag : ($element, $scope, $expr) ->

    startX = null
    startY = null
    lastMoveTime = null
    dragTimeout = 10

    handler = ($event) ->

      t = Date.now!

      if t < (lastMoveTime + dragTimeout)
        return

      ## if startX == null or startY == null
      ##   window.off \mousemove, handler

      lastMoveTime := t

      dx = $event.clientX - startX
      dy = $event.clientY - startY
      
      $drag = { dx, dy }

      $scope.$eval $expr, { $drag, $event }

    mouseup-handler = ($event) ->

      window.off \mousemove, handler

      [startX, startY] := [null, null]

    
    $element.on \mousedown,  ($event) ->

      lastMoveTime := Date.now!

      [startX, startY] := [ $event.clientX, $event.clientY ]

      window.on \mousemove,  handler

      window.once \mouseup,  mouseup-handler
      
      window.once \dragend,  mouseup-handler      
      

  \x-dragstart : ($element, $scope, $expr) ->
  
    handler = ($event) ->
      window.off \mousemove, handler
      $scope.$eval $expr, { $event }

    $element.on \mousedown ,  ($event) ->
      
      window.on \mousemove , handler

      window.once \mouseup ,  ($event) ->
        window.off \mousemove, handler        

  \x-dragend : ($element, $scope, $expr) ->

    up-handler = ($event) ->
      window.off \mouseup ,  up-handler      
      $scope.$eval $expr, { $event }
      
    move-handler = ($event) ->
      window.off \mousemove, move-handler
      window.on \mouseup ,  up-handler
  
    $element.on \mousedown ,  ($event) ->
      window.on \mousemove , move-handler

