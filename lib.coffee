# We override the original lookup method with a similar one, which supports components as well.
#
# Now the order of the lookup will be, in order:
#   a helper of the current template
#   a property of the current component
#   the name of a component
#   the name of a template
#   global helper
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

  # TODO: Blaze.View::lookup should not introduce any reactive dependencies. Can we simply ignore reactivity here? Can this template instance or parent template instances change without reconstructing the component as well? I don't think so. Only data context is changing and this is why templateInstance or .get() are reactive and we do not care about data context here.
  component = Tracker.nonreactive ->
    templateInstance = templateInstance()
    templateInstance.get 'component'

  # Component.
  if component
    if name of component
      return wrapHelper component, component[name]

    if mixin = component.getFirstMixin name
      return wrapHelper mixin, mixin[name]

  null

wrapHelper = (component, helper) ->
  if _.isFunction helper
    _.bind helper, component
  else
    helper

viewToTemplateInstance = (view) ->
  # We skip contentBlock views which are injected by Meteor when using
  # block helpers (in addition to block helper view). This matches more
  # the visual structure of templates and not the internal implementation.
  while view and (not view.template or view.name is '(contentBlock)')
    view = view.originalParentView or view.parentView

  # Body view has template field, but not templateInstance. We return null in that case.
  return null unless view?.templateInstance

  _.bind view.templateInstance, view

addEvents = (view, component) ->
  for events in component.events()
    eventMap = {}

    for spec, handler of events
      do (spec, handler) ->
        eventMap[spec] = (args...) ->
          event = args[0]

          currentView = Blaze.getView event.currentTarget
          templateInstance = viewToTemplateInstance currentView

          # We set template instance based on the current target so that inside event handlers
          # BlazeComponent.currentComponent() returns the component of event target.
          Template._withTemplateInstanceFunc templateInstance, ->
            # We set view based on the current target so that inside event handlers
            # BlazeComponent.currentData() (and Blaze.getData() and Template.currentData())
            # returns data context of event target and not component/template.
            Blaze._withCurrentView currentView, ->
              handler.apply component, args

          # Make sure CoffeeScript does not return anything. Returning from event
          # handlers is deprecated.
          return

    Blaze._addEventMap view, eventMap

  return

originalGetTemplate = Blaze._getTemplate
Blaze._getTemplate = (name) ->
  if component = BlazeComponent.getComponent(name)?.renderComponent()
    return component

  originalGetTemplate name

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

class BlazeComponent extends BaseComponent
  mixins: ->
    []

  # When a component is used as a mixin, createMixins will call this method to set the parent
  # component using this mixin. Extend this method if you want to do any action when parent is
  # set, for example, add dependency mixins to the parent. Make sure you call super as well.
  # TODO: Should this be a list of parents? So that the same mixin instance could be reused across components? And serve to communicate across them?
  mixinParent: (mixinParent) ->
    # Setter.
    if mixinParent
      @_mixinParent = mixinParent
      # To allow chaining.
      return @

    # Getter.
    @_mixinParent or null

  addMixin: (nameOrMixin) ->
    # Do not do anything if mixin is already added. This allows multiple mixins to call addMixin in
    # mixinParent method to add dependencies, but if dependencies are already there, nothing happens.
    return if @getMixin nameOrMixin

    if _.isString nameOrMixin
      # It could be that the component is not a real instance of the BlazeComponent class, so it might not have a constructor.
      mixinInstanceComponent = (@constructor or BlazeComponent).getComponent nameOrMixin
      throw new Error "Unknown mixin '#{ nameOrMixin }'." unless mixinInstanceComponent
      mixinInstance = new mixinInstanceComponent()
    else if _.isFunction nameOrMixin
      mixinInstance = new nameOrMixin()
    else
      mixinInstance = nameOrMixin

    # We add mixin before we call mixinParent so that dependencies come after this mixin,
    # and that we prevent possible loops because of circular dependencies.
    # TODO: For now we do not provide an official API to add dependencies before the mixin itself.
    @_mixins.push mixinInstance

    # We allow mixins to not be components, so methods are not necessary available.

    # Set mixin parent.
    if mixinInstance.mixinParent
      mixinInstance.mixinParent @
      assert.equal mixinInstance.mixinParent(), @

    # Maybe mixin has its own mixins as well.
    mixinInstance.createMixins?()

    # To allow chaining.
    @

  # Method to instantiate all mixins.
  createMixins: ->
    # To allow calling it multiple times, but non-first calls are simply ignored.
    return if @_mixins
    @_mixins = []

    for mixin in @mixins()
      @addMixin mixin

    # To allow chaining.
    @

  getMixin: (nameOrMixin) ->
    assert @_mixins

    if _.isString nameOrMixin
      for mixin in @_mixins
        # We do not require mixins to be components, but if they are, they can
        # be referenced based on their component name.
        mixinComponentName = mixin.componentName?() or null
        return mixin if mixinComponentName and mixinComponentName is nameOrMixin

    else
      for mixin in @_mixins
        # nameOrMixin is a class.
        if mixin.constructor is nameOrMixin
          return mixin

        # nameOrMixin is an instance, or something else.
        else if mixin is nameOrMixin
          return mixin

    return null

  # Calls all mixins in order and collect all results into an array.
  callMixins: (propertyName, args...) ->
    assert @_mixins

    # We return an array of results from each mixin.
    for mixin in @_mixins when propertyName of mixin
      if _.isFunction mixin[propertyName]
        mixin[propertyName] args...
      else
        mixin[propertyName]

  # Calls the first mixin it finds, and returns the result.
  callFirstMixin: (propertyName, args...) ->
    assert @_mixins

    for mixin in @_mixins when propertyName of mixin
      if _.isFunction mixin[propertyName]
        return mixin[propertyName] args...
      else
        return mixin[propertyName]

    # TODO: Should we throw an error here? Something like calling a function which does not exist?
    return

  getFirstMixin: (propertyName) ->
    assert @_mixins

    for mixin in @_mixins when propertyName of mixin
      return mixin

    return

  # Calls all mixins in order and gives initial arguments to the first, and then results of that
  # call to the second, and so on, until all mixins were called, when the result is returned. If
  # there are no mixins matching, initial arguments are returned. Mixins should always return an
  # array to pass to the next mixin.
  foldMixins: (propertyName, args...) ->
    assert @_mixins

    currentArguments = args

    for mixin in @_mixins when propertyName of mixin
      if _.isFunction mixin[propertyName]
        currentArguments = mixin[propertyName] currentArguments...
      else
        currentArguments = mixin[propertyName]

      # We ignore results if there were not an array.
      currentArguments = [] unless _.isArray currentArguments

    currentArguments

  # This class method more or less just creates an instance of a component and calls its renderComponent
  # method. But because we want to allow passing arguments to the component in templates, we have some
  # complicated code around to extract and pass those arguments.
  # TODO: This should be really made less hacky. See https://github.com/meteor/meteor/issues/3913
  @renderComponent: ->
    componentClass = @

    # Blaze.View::lookup should not introduce any reactive dependencies, so we are returning
    # a function which can then be run in a reactive context. This allows template method to
    # be reactive, together with reactivity of component arguments.
    new Blaze.Template "BlazeComponent.#{ componentClass.componentName() or 'unnamed' } (reactive wrapper)", ->
      try
        # We check data context in a non-reactive way, because we want just to peek into it
        # and determine if data context contains component arguments or not. We do not want
        # to register a reactive dependency unnecessary because then the component would be
        # recreated every time data context changes. We want that it is recreated only when
        # component arguments change, if there are any.
        data = Tracker.nonreactive ->
          Template.currentData()
      catch error
        # The exception can be thrown when there is no current view which happens when
        # there is no data context yet, thus also no arguments were provided through
        # "args" template helper, so we just continue normally.
        data = null

      if data?.constructor is argumentsConstructor
        argumentsProvided = true
        # Arguments were provided through "args" template helper, use them with the constructor.
        component = new componentClass data._arguments...
      else
        argumentsProvided = false
        component = new componentClass()

      template = component.renderComponent()

      return template unless argumentsProvided

      if Tracker.active
        # Register a dependency on the data context, component arguments.
        # TODO: This dependency makes component be recreated when its data context changes. We should recreate a component only when component arguments change. Probably by not passing component arguments through intermediary data context.
        Template.currentData()

      # Arguments were provided through "args" template helper and passed in as a data
      # context. Restore original (parent) data context and render the component in it.
      new Blaze.Template ->
        Blaze._TemplateWith (-> Template.parentData()), (-> template)

  # This method potentially registers a reactive dependency if template method registers a reactive dependency.
  renderComponent: ->
    component = @

    # If mixins have not yet been created.
    component.createMixins()

    componentTemplate = component.template()
    if _.isString componentTemplate
      templateBase = Template[componentTemplate]
      throw new Error "Template '#{ componentTemplate }' cannot be found." unless templateBase
    else
      templateBase = componentTemplate
      assert templateBase

    # Create a new component template based on the Blaze template. We want our own template
    # because the same Blaze template could be reused between multiple components.
    # TODO: Should we cache these templates based on (componentName, templateBase) pair? We could use tow levels of ES6 Maps, componentName -> templateBase -> template. What about component arguments changing?
    template = new Blaze.Template "BlazeComponent.#{ component.componentName() or 'unnamed' }", templateBase.renderFunction

    # We on purpose do not reuse helpers, events, and hooks. Templates are used only for HTML rendering.

    template.onCreated ->
      # @ is a template instance.

      @view._onViewRendered =>
        # Attach events the first time template instance renders.
        return unless @view.renderCount is 1

        assert @component._mixins

        # We manually go over _mixins instead of using getMixin because we also need
        # the mixin itself so that we can bind events correctly.
        for mixin in @component._mixins when 'events' of mixin
          addEvents @view, mixin

        # We first add event handlers from mixins, then the component.
        addEvents @view, @component

      @component = component
      @component.templateInstance = @
      @component.onCreated()

    template.onRendered ->
      # @ is a template instance.
      @component.onRendered()

    template.onDestroyed ->
      # @ is a template instance.
      @component.onDestroyed()

    template

  template: ->
    # You have to override this method with a method which returns a template name or template itself.
    throw new Error "Component method 'template' not overridden."

  onCreated: ->
    @callMixins 'onCreated'

  onRendered: ->
    @callMixins 'onRendered'

  onDestroyed: ->
    @callMixins 'onDestroyed'

  insertDOMElement: (parent, node, before, alreadyInserted=false) ->
    [parent, node, before, alreadyInserted] = @foldMixins 'insertDOMElement', parent, node, before, alreadyInserted

    if not alreadyInserted and parent and node
      parent.insertBefore node, (before or null)
      return [parent, node, before, true]

    [parent, node, before, alreadyInserted]

  moveDOMElement: (parent, node, before, alreadyMoved=false) ->
    [parent, node, before, alreadyMoved] = @foldMixins 'moveDOMElement', parent, node, before, alreadyMoved

    if not alreadyMoved and parent and node
      parent.insertBefore node, (before or null)
      return [parent, node, before, true]

    [parent, node, before, alreadyMoved]

  removeDOMElement: (parent, node, alreadyRemoved=false) ->
    [parent, node, alreadyRemoved] = @foldMixins 'removeDOMElement', parent, node, alreadyRemoved

    if not alreadyRemoved and parent and node
      parent.removeChild node
      return [parent, node, true]

    [parent, node, alreadyRemoved]

  events: ->
    []

  # Component-level data context. Reactive. Use this to always get the
  # top-level data context used to render the component.
  data: ->
    # Only components themselves have template instance. If we are called from inside a
    # mixin, find a component.
    component = @
    while component.mixinParent()
      component = component.mixinParent()

    Blaze.getData(component.templateInstance.view) or null

  # Caller-level data context. Reactive. Use this to get in event handlers the data
  # context at the place where event originated (target context). In template helpers
  # the data context where template helpers were called. In onCreated, onRendered,
  # and onDestroyed, the same as @data(). Inside a template this is the same as this.
  currentData: ->
    Blaze.getData() or null

  # Caller-level component. Reactive. In most cases the same as @, but in event handlers
  # it returns the component at the place where event originated (target component).
  currentComponent: ->
    Template.instance()?.get('component') or null

  firstNode: ->
    @templateInstance.firstNode

  lastNode: ->
    @templateInstance.lastNode

# We copy utility methods ($, findAll, autorun, subscribe, etc.) from the template instance prototype.
for methodName, method of Blaze.TemplateInstance::
  BlazeComponent::[methodName] = (args...) ->
    @templateInstance[methodName] args...

argumentsConstructor = ->
  # This class should never really be created.
  assert false

# TODO: Find a way to pass arguments to the component without having to introduce one intermediary data context into the data context hierarchy (in fact two data contexts, because we add one more when restoring the original one).
Template.registerHelper 'args', ->
  obj = {}
  # We use custom constructor to know that it is not a real data context.
  obj.constructor = argumentsConstructor
  obj._arguments = arguments
  obj
