#
# dna-ctrl
#

dna-attrs = (require \../dna-attrs)

clean-element = (element) ->
  if element?.tag-name
    while element.first-child
      element.remove-child element.first-child

module.exports = class
  (@element, @scope) ->
       
  here: -> @element.query-selector it

  here-all: -> @element.query-selector-all it

  log: (...vars) ->
    vars.unshift "[#{@element.tag-name}]"
    console?.log?.apply console, vars
    window.dna-log?.apply @, vars
    
