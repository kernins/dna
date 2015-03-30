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
        if props.single
          if (instances |> find -> it.tag-name == self.tag-name)
            that |> self.replace
            return
          
        props-scope = {} <<<< (props.scope or {})
        
        if props.isolated
          @scope = new Scope (props.scope or {})
        else
          @scope = (Scope::$get @).$new props-scope
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
          
        @on \rendered, ~>
          attrs @, (props.attributes or {})

        instances.push @

        @emit \created, it
        
      attached-callback: value: ->
        ## console.log \attached-callback tag-name
        
        ## @scope:: = @scope.$parent @
        
        ## if not @rendered
        @render?!
        
        ## @rendered = yes

        (@emit \attached, it)
      
      detached-callback: value: (-> (@emit \detached, it))
      
      attribute-changed-callback: value: (-> (@emit \attribute-changed, it))

module.exports = create-tag
