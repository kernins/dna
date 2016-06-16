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
   cleanElement $element #TODO: is it really needed here?

   #console.log 'rendering '+$element.tagName
   $element.innerHTML = switch typeof $template
      case 'function' then $template $scope
      case 'string' then $template
      default throw new Error 'DNA.tag['+$element.tagName+']: invalid template: neither a function, nor a string'
   
   attrs $element, attributes
   $element.rendered = true
   $element.emit \rendered

checkOverrideBool = (val, valOvr)->
   if valOvr != undefined
      if /^(?:0|no|false)$/i.test valOvr then val=false
      else if /^(?:1|yes|true)$/i.test valOvr then val=true
      else throw new Error 'DNA.tag: Invalid opt-bool override value: '+valOvr
   return val


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

            isolated = checkOverrideBool (props.isolated ? null), (@data 'cmpIsolated')
            forceRenderOnAttach = checkOverrideBool (props.forceRenderOnAttach ? null), (@data 'cmpForceRenderOnAttach')

            propsScope = {} <<< (props.scope || {})
            if isolated || !scopeParent.get! then scope = new Scope propsScope
            else scope = scopeParent.get!.$new propsScope

            #TODO: remove $scope, rename $scopeParent to $scope? Probably no sense to pass component's own scope here
            if (tmp=@data 'cmpTemplate') then @template = (($scope, $scopeParent)-> eval tmp).apply window, [@scope, scopeParent.get!]
            else if props.template then @template = that

            scope._viewOpts = (tmp=@data 'cmpViewOpts') && ((($scopeParent)-> eval '('+tmp+')').apply window, [scopeParent.get!]) || {}

            observed (@scope=scope) #assigning this.scope after tpl stuff to ensure correct scopeParent
        

            if props.render then @render = that
            else @render = (template=@template)-> renderFn @, @scope, template, props.attributes
            if props.controller then @controller = new that @, @scope

            @on \attached, !~> (if !@rendered || forceRenderOnAttach then @render?!)
            if forceRenderOnAttach then @on \detached, !~> (cleanElement @) #to prevent old child elems from generating attach-detach ev seq (as @ is first attached with old content)

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
