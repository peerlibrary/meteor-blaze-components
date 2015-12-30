originalInsertNodeWithHooks = Blaze._DOMRange._insertNodeWithHooks
Blaze._DOMRange._insertNodeWithHooks = (node, parent, next) ->
  node._uihooks = _.extend {}, parent._uihooks, parentNode: node unless node._uihooks
  originalInsertNodeWithHooks node, parent, next

originalMoveNodeWithHooks = Blaze._DOMRange._moveNodeWithHooks
Blaze._DOMRange._moveNodeWithHooks = (node, parent, next) ->
  node._uihooks = _.extend {}, parent._uihooks, parentNode: node unless node._uihooks
  originalMoveNodeWithHooks node, parent, next

createUIHooks = (component, parentNode) ->
  parentNode: parentNode

  insertElement: (node, before) ->
    component.insertDOMElement @parentNode, node, before

  moveElement: (node, before) ->
    component.moveDOMElement @parentNode, node, before

  removeElement: (node) ->
    component.removeDOMElement node.parentNode, node

originalDOMRangeAttach = Blaze._DOMRange::attach
Blaze._DOMRange::attach = (parentElement, nextNode, _isMove, _isReplace) ->
  if component = @view?._templateInstance?.component
    for member in @members when member not instanceof Blaze._DOMRange
      member._uihooks = createUIHooks component, member

    oldUIHooks = parentElement._uihooks
    try
      parentElement._uihooks = createUIHooks component, parentElement
      return originalDOMRangeAttach.apply @, arguments
    finally
      if oldUIHooks
        parentElement._uihooks = oldUIHooks
      else
        delete parentElement._uihooks

  originalDOMRangeAttach.apply @, arguments

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

originalExpandAttributes = Blaze._expandAttributes
Blaze._expandAttributes = (attrs, parentView) ->
  previousInExpandAttributes = share.inExpandAttributes
  share.inExpandAttributes = true
  try
    originalExpandAttributes attrs, parentView
  finally
    share.inExpandAttributes = previousInExpandAttributes
