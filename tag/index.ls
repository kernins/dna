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
          
        props-scope = {} <<<< (props.scope or {})
        
        if props.isolated
          @scope = new Scope (props.scope or {})
        else
          @scope = (Scope::$get @)?.$new props-scope
          
        @scope |> observed

        if props.template
          @template = that
        
        if props.render?
          @render = that
        else
          @render = (template = @template) ->
                                  render-fn @, @scope, template

        if props.controller
          @controller = new that @, @scope

        @on \attached, ~>
          if not @rendered
            @render?!
          
        @on \rendered, ~>
          @rendered = yes
          attrs @, (props.attributes or {})

        instances.push @

        @emit \created, it
        
          
      attached-callback: value: ->
        @attached = yes
        (@emit \attached, it)
      
      detached-callback: value: ->
        @attached = yes
        (@emit \detached, it)
      
      attribute-changed-callback: value: (-> (@emit \attribute-changed, it))

module.exports = create-tag
