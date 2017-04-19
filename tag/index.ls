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


            @getData = (name)-> #safari 10 fix (returns undef for data attrs containing json formatted string)
               ((tmp=@data name)==undefined) && (@getAttribute ('data-'+(name.replace /([a-z])([A-Z])/g, '$1-$2').toLowerCase!)) || tmp


            scope = null
            scopeParent = new ParentScopeGetter @

            isolated = checkOverrideBool (props.isolated ? null), (@getData 'cmpIsolated')
            forceRenderOnAttach = checkOverrideBool (props.forceRenderOnAttach ? null), (@getData 'cmpForceRenderOnAttach')
            noRenderOnAttach = checkOverrideBool (props.noRenderOnAttach ? null), (@getData 'cmpNoRenderOnAttach')
            if forceRenderOnAttach && noRenderOnAttach then throw new Error 'forceRenderOnAttach and noRenderOnAttach options are mutually exclusive'

            propsScope = {} <<< (props.scope || {})
            if isolated || !scopeParent.get! then scope = new Scope propsScope
            else scope = scopeParent.get!.$new propsScope

            #TODO: remove $scope, rename $scopeParent to $scope? Probably no sense to pass component's own scope here
            if (tmp=@getData 'cmpTemplate') then @template = (($scope, $scopeParent)-> eval tmp).apply window, [@scope, scopeParent.get!]
            else if props.template then @template = that

            scope._viewOpts = (tmp=@getData 'cmpViewOpts') && ((($scopeParent)-> eval '('+tmp+')').apply window, [scopeParent.get!]) || {}

            observed (@scope=scope) #assigning this.scope after tpl stuff to ensure correct scopeParent
        

            if props.render then @render = that
            else @render = (template=@template)-> renderFn @, @scope, template, props.attributes
            if props.controller then @controller = new that @, @scope

            if !noRenderOnAttach
               @on \attached, !~> 
                  if !@rendering && (!@rendered || forceRenderOnAttach)
                     @rendering=true; res=@render?!
                     if res instanceof Promise then res.then !~>(@rendering=false; @rendered=true)
                     else
                        @rendering = false
                        @rendered = true
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
