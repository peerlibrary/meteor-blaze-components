createUIHooks = (component, parentNode) ->
  insertElement: (node, before) =>
    node._uihooks ?= createUIHooks component, node
    component.insertDOMElement parentNode, node, before

  moveElement: (node, before) =>
    node._uihooks ?= createUIHooks component, node
    component.moveDOMElement parentNode, node, before

  removeElement: (node) =>
    node._uihooks ?= createUIHooks component, node
    component.removeDOMElement node.parentNode, node

originalDOMRangeAttach = Blaze._DOMRange::attach
Blaze._DOMRange::attach = (parentElement, nextNode, _isMove, _isReplace) ->
  if component = @view._templateInstance?.component
    oldUIHooks = parentElement._uihooks
    try
      parentElement._uihooks = createUIHooks component, parentElement
      return originalDOMRangeAttach.apply @, arguments
    finally
      parentElement._uihooks = oldUIHooks if oldUIHooks

  originalDOMRangeAttach.apply @, arguments

share.argumentsConstructor = ->
  # This class should never really be created.
  assert false

# TODO: Find a way to pass arguments to the component without having to introduce one intermediary data context into the data context hierarchy.
#       (In fact two data contexts, because we add one more when restoring the original one.)
Template.registerHelper 'args', ->
  obj = {}
  # We use custom constructor to know that it is not a real data context.
  obj.constructor = share.argumentsConstructor
  obj._arguments = arguments
  obj

# We make Template.dynamic resolve to the component if component name is specified as a template name, and not
# to the non-component template which is probably used only for the content. We simply reuse Blaze._getTemplate.
# TODO: How to pass args?
#       Maybe simply by using Spacebars nested expressions (https://github.com/meteor/meteor/pull/4101)?
#       Template.dynamic template="..." data=(args ...)? But this exposes the fact that args are passed as data context.
#       Maybe we should simply override Template.dynamic and add "args" argument?
# TODO: This can be removed once https://github.com/meteor/meteor/pull/4036 is merged in.
Template.__dynamicWithDataContext.__helpers.set 'chooseTemplate', (name) ->
  Blaze._getTemplate name, =>
    Template.instance()
