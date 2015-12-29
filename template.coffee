Template = Blaze.Template

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

share.EVENT_HANDLER_REGEX = /^on[A-Z]/

share.isEventHandler = (fun) ->
  _.isFunction(fun) and fun.eventHandler

# When event handlers are provided directly as args they are not passed through
# Spacebars.event by the template compiler, so we have to do it ourselves.
originalFlattenAttributes = HTML.flattenAttributes
HTML.flattenAttributes = (attrs) ->
  if attrs = originalFlattenAttributes attrs
    for name, value of attrs when share.EVENT_HANDLER_REGEX.test name
      # Already processed by Spacebars.event.
      continue if share.isEventHandler value
      continue if _.isArray(value) and _.some value, share.isEventHandler

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
      # as template helpers and are already bound. We bind event handlers
      # in dynamic attributes already as well.
      eventHandler.apply null, [event].concat args, eventArgs

  fun.eventHandler = true

  fun

# When converting the component to the static HTML, remove all event handlers.
originalVisitTag = HTML.ToHTMLVisitor::visitTag
HTML.ToHTMLVisitor::visitTag = (tag) ->
  if attrs = tag.attrs
    attrs = HTML.flattenAttributes attrs
    for name of attrs when share.EVENT_HANDLER_REGEX.test name
      delete attrs[name]
    tag.attrs = attrs

  originalVisitTag.call @, tag
