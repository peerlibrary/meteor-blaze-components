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

# We make Template.dynamic resolve to the component if component name is specified as a template name, and not
# to the non-component template which is probably used only for the content. We simply reuse Blaze._getTemplate.
# TODO: How to pass args?
#       Maybe simply by using Spacebars nested expressions (https://github.com/meteor/meteor/pull/4101)?
#       Template.dynamic template="..." data=(args ...)? But this exposes the fact that args are passed as data context.
#       Maybe we should simply override Template.dynamic and add "args" argument?
# TODO: This can be removed once https://github.com/meteor/meteor/pull/4036 is merged in.
# TODO: Move this to the server side as well.
Template.__dynamicWithDataContext.__helpers.set 'chooseTemplate', (name) ->
  Blaze._getTemplate name, =>
    Template.instance()

WHITESPACE_REGEX = /^\s+$/

EventHandler = Blaze._AttributeHandler.extend
  update: (element, oldValue, value) ->
    oldValue = [] unless oldValue
    oldValue = [oldValue] unless _.isArray oldValue

    value = [] unless value
    value = [value] unless _.isArray value

    assert _.every(oldValue, share.isEventHandler), oldValue
    assert _.every(value, share.isEventHandler), value

    $element = $(element)
    eventName = @name.substr(2).toLowerCase()

    $element.off eventName, fun for fun in oldValue
    $element.on eventName, fun for fun in value

originalMakeAttributeHandler = Blaze._makeAttributeHandler
Blaze._makeAttributeHandler = (elem, name, value) ->
  if share.EVENT_HANDLER_REGEX.test name
    new EventHandler name, value
  else
    originalMakeAttributeHandler elem, name, value

originalToText = Blaze._toText
Blaze._toText = (htmljs, parentView, textMode) ->
  # If it is an event handler function, we pass it as it is and do not try to convert it to text.
  # Our EventHandler knows how to handle such attribute values - functions.
  if share.isEventHandler htmljs
    htmljs
  else if _.isArray(htmljs) and _.some htmljs, share.isEventHandler
    # Remove whitespace in onEvent="{{onEvent1}} {{onEvent2}}".
    _.filter htmljs, (fun) ->
      return true if share.isEventHandler fun
      return false if WHITESPACE_REGEX.test fun

      # We do not support anything fancy besides whitespace.
      throw new Error "Invalid event handler: #{fun}"
  else
    originalToText htmljs, parentView, textMode

share.inExpandAttributes = false

originalExpandAttributes = Blaze._expandAttributes
Blaze._expandAttributes = (attrs, parentView) ->
  previousInExpandAttributes = share.inExpandAttributes
  share.inExpandAttributes = true
  try
    originalExpandAttributes attrs, parentView
  finally
    share.inExpandAttributes = previousInExpandAttributes
