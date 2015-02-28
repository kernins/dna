#
# Takes: <String> tag name and { controller: ->, scope: {} }
#
# Register custom element with given controller and scope
#

clone = require \../clone
observed = require \../observed
attrs = require \../attrs
Scope = require \../scope

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

  $element.emit \rendered

create-tag = ( tag-name, props = {} ) ->

  self = @

  if not tag-name
    throw new Error "No tag name given"

  document.register-element tag-name , do
  
    prototype: Object.create HTMLElement:: , do
    
      created-callback: value: ->
        ## console.log \created-callback tag-name
        props-scope = clone (props.scope or {})
        
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
          
        @on \rendered, ~> attrs @, (props.attrs or {})

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
