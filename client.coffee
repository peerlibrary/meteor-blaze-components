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

EVENT_HANDLER_REGEX = /^on[A-Z]/
WHITESPACE_REGEX = /^\s+$/

isEventHandler = (fun) ->
  _.isFunction(fun) and fun.eventHandler

EventHandler = Blaze._AttributeHandler.extend
  update: (element, oldValue, value) ->
    oldValue = [] unless oldValue
    oldValue = [oldValue] unless _.isArray oldValue

    value = [] unless value
    value = [value] unless _.isArray value

    assert _.every(oldValue, isEventHandler), oldValue
    assert _.every(value, isEventHandler), value

    $element = $(element)
    eventName = @name.substr(2).toLowerCase()

    $element.off eventName, fun for fun in oldValue
    $element.on eventName, fun for fun in value

originalMakeAttributeHandler = Blaze._makeAttributeHandler
Blaze._makeAttributeHandler = (elem, name, value) ->
  if EVENT_HANDLER_REGEX.test name
    new EventHandler name, value
  else
    originalMakeAttributeHandler elem, name, value

originalToText = Blaze._toText
Blaze._toText = (htmljs, parentView, textMode) ->
  # If it is an event handler function, we pass it as it is and do not try to convert it to text.
  # Our EventHandler knows how to handle such attribute values - functions.
  if isEventHandler htmljs
    htmljs
  else if _.isArray(htmljs) and _.some htmljs, isEventHandler
    # Remove whitespace in onEvent="{{onEvent1}} {{onEvent2}}".
    _.filter htmljs, (fun) ->
      return true if isEventHandler fun
      return false if WHITESPACE_REGEX.test fun

      # We do not support anything fancy besides whitespace.
      throw new Error "Invalid event handler: #{fun}"
  else
    originalToText htmljs, parentView, textMode

# When event handlers are provided directly as args they are not passed through
# Spacebars.event by the template compiler, so we have to do it ourselves.
originalFlattenAttributes = HTML.flattenAttributes
HTML.flattenAttributes = (attrs) ->
  if attrs = originalFlattenAttributes attrs
    for name, value of attrs when EVENT_HANDLER_REGEX.test name
      # Already processed by Spacebars.event.
      continue if isEventHandler value
      continue if _.isArray(value) and _.some value, isEventHandler

      # When event handlers are provided directly as args,
      # we require them to be just event handlers.
      if _.isArray value
        attrs[name] = _.map value, Spacebars.event
      else
        attrs[name] = Spacebars.event value

  attrs

Spacebars.event = (eventHandler, args...) ->
  throw new Error "Event handler not a function: #{eventHandler}" unless _.isFunction eventHandler

  # Execute all arguments.
  args = Spacebars.mustacheImpl ((xs...) -> xs), args...

  fun = (event, eventArgs...) ->
    currentView = Blaze.getView event.currentTarget
    share.wrapViewAndTemplate currentView, ->
      # We do not have to bind "this" because event handlers are resolved
      # as template helpers and are already bound.
      eventHandler.apply null, [event].concat args, eventArgs

  fun.eventHandler = true

  fun

# When converting the component to the static HTML, remove all event handlers.
originalVisitTag = HTML.ToHTMLVisitor::visitTag
HTML.ToHTMLVisitor::visitTag = (tag) ->
  if attrs = tag.attrs
    attrs = HTML.flattenAttributes attrs
    for name of attrs when EVENT_HANDLER_REGEX.test name
      delete attrs[name]
    tag.attrs = attrs

  originalVisitTag.call @, tag
