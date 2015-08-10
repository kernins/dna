Scope = require \../scope

module.exports = (element, attrs, key) ->
  element.$$dna-attrs = element.$$dna-attrs or {}

  if not (element.$$dna-attrs[key])
      element.$$dna-attrs[key] = yes
      expr = element.get-attribute key
      scope = (element |> Scope::$get)
      if not scope
        ## console.warn "[apply-attr] #{key} = #{expr}: there is no scope here", element
        return
      try
        if attrs[key]
          new that element, scope, expr
      catch e
        ## console.error "[apply-attr] #{key} = #{expr}", element, e
          
