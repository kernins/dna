#
# dna-ctrl
#

dna-attrs = (require \../attrs)

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
    window.dna-log?.apply @, vars
