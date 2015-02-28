Scope = require \../scope
attrs = require \../attrs

module.exports = (name = '', props = {}) ->
  element = document.query-selector "[dna-app=#{name or ''}]"
  if element
    element.scope = new Scope (props.scope or {})
    if props.controller
      element.controller = new that element, element.scope
    attrs element
