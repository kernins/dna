#
# Takes: <String> tag name and { controller: ->, scope: {} }
#
# Register custom element with given controller and scope
#

{ find } = require \prelude-ls

observed = require \../observed
attrs = require \../attrs
Scope = require \../scope

clean-element = (element) ->
  if element?.tag-name
    while element.first-child
      element.remove-child element.first-child

render-fn = ($element, $scope, $template = '', attributes = {}) ->
  clean-element $element

  $element.innerHTML = do ~>
       | typeof! $template is \String   => $template
       | typeof! $template is \Function => $scope |> $template
       | _                              => ''

  $element.rendered = yes
  $element.emit \rendered

instances = []

create-tag = ( tag-name, props = {} ) ->

  self = @

  if not tag-name
    throw new Error "No tag name given"

  document.register-element tag-name , do
  
    prototype: Object.create HTMLElement:: , do
    
      created-callback: value: ->
        self = @
        
        if props.single or @id
          if (instances |> find -> it.tag-name == self.tag-name and it.id == self.id)
            that |> self.replace
            self = that
            return

        scope = null
        scopeParent =
          scope: undefined
          get: ->
            if @scope == undefined
              try
                @scope = Scope::$get self
              catch
                @scope = null
            return @scope

        isolated = props.isolated ? null
        if (tmp=@data 'cmpIsolated') != undefined
          if /^(?:0|no|false)$/i.test tmp then isolated=false
          else if /^(?:1|yes|true)$/i.test tmp then isolated=true

        propsScope = {} <<< (props.scope or {})
        if isolated || !scopeParent.get! then scope = new Scope propsScope
        else scope = scopeParent.get!.$new propsScope
        
        if (tmp=@data 'cmpTemplate')
          @template = (($scope, $scopeParent)-> eval tmp).apply window, [@scope, scopeParent.get!]
        else if props.template
          @template = that

        observed (@scope=scope) #assigning this.scope after tpl stuff to ensure correct scopeParent
        
        if props.render then @render = that
        else @render = (template=@template)-> renderFn @, @scope, template

        if props.controller then @controller = new that @, @scope

        @on \attached, ~>
          if not @rendered then @render?!
          
        @on \rendered, ~>
          @rendered = yes
          attrs @, (props.attributes or {})

        instances.push @

        @emit \created, it
        
      attached-callback: value: ->
        @attached = yes
        (@emit \attached, it)
      
      detached-callback: value: ->
        @attached = no
        (@emit \detached, it)
      
      attribute-changed-callback: value: (-> (@emit \attribute-changed, it))

module.exports = create-tag
