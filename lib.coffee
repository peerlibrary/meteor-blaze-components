# We override the original lookup method with a similar one, which supports components as well.
#
# Now the order of the lookup will be, in order:
#   a helper of the current template
#   a property of the current component
#   global helper
#   the name of a template
#   a property of the data context
#
# Returns a function, a non-function value, or null. If a function is found, it is bound appropriately.
#
# NOTE: This function must not establish any reactive dependencies itself.  If there is any reactivity
# in the value, lookup should return a function.
#
# TODO: Should we also lookup for a property of the component-level data context (and template-level data context)?

Blaze._getTemplateHelper = (template, name, templateInstance) ->
  isKnownOldStyleHelper = false
  if template.__helpers.has name
    helper = template.__helpers.get name
    if helper is Blaze._OLDSTYLE_HELPER
      isKnownOldStyleHelper = true
    else
      return helper

  # Old-style helper.
  if name of template
    # Only warn once per helper.
    unless isKnownOldStyleHelper
      template.__helpers.set name, Blaze._OLDSTYLE_HELPER
      unless template._NOWARN_OLDSTYLE_HELPERS
        Blaze._warn "Assigning helper with `" + template.viewName + "." + name + " = ...` is deprecated.  Use `" + template.viewName + ".helpers(...)` instead."
    return template[name]

  # TODO: Can we simply ignore reactivity here? Can this template instance or parent template instances change without reconstructing the component as well? I don't think so. Only data context is changing and this is why templateInstance or .get() are reactive and we do not care about data context here.
  component = Tracker.nonreactive ->
    templateInstance = templateInstance()
    templateInstance.get 'component'

  # Component.
  if component and name of component
    return _.bind component[name], component

  null

addEvents = (view, component) ->
  for events in component.events()
    eventMap = {}

    for spec, handler of events
      do (spec, handler) ->
        eventMap[spec] = (args...) ->
          event = args[0]

          # We set view based on the current target so that inside event handlers
          # BlazeComponent.currentData() (and Blaze.getData() and Template.currentData())
          # returns data context of event target and not component/template.
          Blaze._withCurrentView Blaze.getView(event.currentTarget), ->
            handler.apply component, args

          # Make sure CoffeeScript does not return anything. Returning from event
          # handlers is deprecated.
          return

    Blaze._addEventMap view, eventMap

  return

class BlazeComponent
  @template: (template) ->
    componentClass = @

    template = Template[template] if _.isString template

    template.onCreated ->
      @view._onViewRendered =>
        # Attach events the first time template instance renders.
        addEvents @view, @component if @view.renderCount is 1

      # @ is a template instance.
      @component = new componentClass()
      @component.templateInstance = @
      @component.onCreated()

    template.onRendered ->
      # @ is a template instance.
      @component.onRendered()

    template.onDestroyed ->
      # @ is a template instance.
      @component.onDestroyed()

  onCreated: ->

  onRendered: ->

  onDestroyed: ->

  events: ->
    []

  # Component-level data context. Reactive. Use this to always get the
  # top-level data context used to render the component.
  data: ->
    Blaze.getData @templateInstance.view

  # Caller-level data context. Reactive. Use this to get in event handlers the data
  # context at the place where event originated (target context). In template helpers
  # the data context where template helpers were called. In onCreated, onRendered,
  # or onDestroyed, the same as @data(). Inside a template this is the same as this.
  currentData: ->
    Blaze.getData()

# We copy utility methods ($, findAll, autorun, subscribe, etc.) from the template instance prototype.
for methodName, method of Blaze.TemplateInstance::
  BlazeComponent::[methodName] = (args...) ->
    @templateInstance[methodName] args...
