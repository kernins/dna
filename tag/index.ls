#
# Takes: <String> tag name and { controller: ->, scope: {} }
#
# Register custom element with given controller and scope
#

$ = require
{find} = $ \prelude-ls

observed = $ \../observed
attrs = $ \../attrs
Scope = $ \../scope



cleanElement = (element)!->
   if element?.tagName
      while element.firstChild
         element.removeChild element.firstChild

renderFn = ($element, $scope, $template='', attributes={})!->
   cleanElement $element

   $element.innerHTML = switch typeof $template
      case 'function' then $template $scope
      case 'string' then $template
      default throw new Error 'DNA.tag['+$element.tagName+']: invalid template: neither a function, nor a string'
   
   attrs $element, attributes
   $element.rendered = true
   $element.emit \rendered

class ParentScopeGetter
   (element)-> (@element=element)

   scope: undefined
   get: ->
      if @scope == undefined
         try
            @scope = Scope::$get @element
         catch
            @scope = null
      return @scope



instances = []
module.exports = (tagName, props={})->
   if !tagName then throw new Error 'No tag name given'

   document.registerElement tagName, do
      prototype: Object.create HTMLElement::, do
         createdCallback: value: ->
            if (props.single || @id) && (instances |> find ~>(it.tagName==@tagName && it.id==@id))
               @replace that
               return


            scope = null
            scopeParent = new ParentScopeGetter @

            isolated = props.isolated ? null
            if (tmp=@data 'cmpIsolated') != undefined
               if /^(?:0|no|false)$/i.test tmp then isolated=false
               else if /^(?:1|yes|true)$/i.test tmp then isolated=true

            propsScope = {} <<< (props.scope || {})
            if isolated || !scopeParent.get! then scope = new Scope propsScope
            else scope = scopeParent.get!.$new propsScope

            #TODO: remove $scope, rename $scopeParent to $scope? Probably no sense to pass component's own scope here
            if (tmp=@data 'cmpTemplate') then @template = (($scope, $scopeParent)-> eval tmp).apply window, [@scope, scopeParent.get!]
            else if props.template then @template = that

            if (tmp=@data 'cmpViewOpts') then scope._viewOpts = (($scopeParent)-> eval '('+tmp+')').apply window, [scopeParent.get!]

            observed (@scope=scope) #assigning this.scope after tpl stuff to ensure correct scopeParent
        

            if props.render then @render = that
            else @render = (template=@template)-> renderFn @, @scope, template, props.attributes
            if props.controller then @controller = new that @, @scope

            @on \attached, !~> (if !@rendered then @render?!)

            instances.push @
            @emit \created
        
         attachedCallback: value: ->
            @attached = true
            @emit \attached
      
         detachedCallback: value: ->
            @attached = false
            @emit \detached
      
         attributeChangedCallback: value: -> 
            @emit \attribute-changed
