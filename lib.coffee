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
    else if helper?
      return wrapHelper bindDataContext(helper), templateInstance
    else
      return null

  # Old-style helper.
  if name of template
    # Only warn once per helper.
    unless isKnownOldStyleHelper
      template.__helpers.set name, Blaze._OLDSTYLE_HELPER
      unless template._NOWARN_OLDSTYLE_HELPERS
        Blaze._warn "Assigning helper with `" + template.viewName + "." + name + " = ...` is deprecated.  Use `" + template.viewName + ".helpers(...)` instead."
    if template[name]?
      return wrapHelper bindDataContext(template[name]), templateInstance
    else
      return null

  return null unless templateInstance

  # TODO: Blaze.View::lookup should not introduce any reactive dependencies. Can we simply ignore reactivity here? Can this template instance or parent template instances change without reconstructing the component as well? I don't think so. Only data context is changing and this is why templateInstance or .get() are reactive and we do not care about data context here.
  component = Tracker.nonreactive ->
    templateInstance().get 'component'

  # Component.
  if component
    # This will first search on the component and then continue with mixins.
    if mixinOrComponent = component.getFirstWith null, name
      return wrapHelper bindComponent(mixinOrComponent, mixinOrComponent[name]), templateInstance

  null

bindComponent = (component, helper) ->
  if _.isFunction helper
    _.bind helper, component
  else
    helper

bindDataContext = (helper) ->
  if _.isFunction helper
    ->
      data = Blaze.getData()
      data ?= {}
      helper.apply data, arguments
  else
    helper

wrapHelper = (f, templateFunc) ->
  # XXX COMPAT WITH METEOR 1.0.3.2
  return Blaze._wrapCatchingExceptions f, 'template helper' unless Blaze.Template._withTemplateInstanceFunc

  return f unless _.isFunction f

  ->
    self = @
    args = arguments

    Blaze.Template._withTemplateInstanceFunc templateFunc, ->
      Blaze._wrapCatchingExceptions(f, 'template helper').apply self, args

viewToTemplateInstance = (view) ->
  # We skip contentBlock views which are injected by Meteor when using
  # block helpers (in addition to block helper view). This matches more
  # the visual structure of templates and not the internal implementation.
  while view and (not view.template or view.name is '(contentBlock)' or view.name is '(elseBlock)')
    view = view.originalParentView or view.parentView

  # Body view has template field, but not templateInstance. We return null in that case.
  return null unless view?.templateInstance

  _.bind view.templateInstance, view

addEvents = (view, component) ->
  eventsList = component.events()

  throw new Error "'events' method from the component '#{ component.componentName() or 'unnamed' }' did not return a list of event maps." unless _.isArray eventsList

  for events in eventsList
    eventMap = {}

    for spec, handler of events
      do (spec, handler) ->
        eventMap[spec] = (args...) ->
          event = args[0]

          currentView = Blaze.getView event.currentTarget
          templateInstance = viewToTemplateInstance currentView

          if Template._withTemplateInstanceFunc
            withTemplateInstanceFunc = Template._withTemplateInstanceFunc
          else
            # XXX COMPAT WITH METEOR 1.0.3.2.
            withTemplateInstanceFunc = (templateInstance, f) ->
              f()

          # We set template instance based on the current target so that inside event handlers
          # BlazeComponent.currentComponent() returns the component of event target.
          withTemplateInstanceFunc templateInstance, ->
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
Blaze._getTemplate = (name, templateInstance) ->
  # Blaze.View::lookup should not introduce any reactive dependencies, so we are making sure it is so.
  template = Tracker.nonreactive ->
    componentParent = templateInstance?().get 'component'
    BlazeComponent.getComponent(name)?.renderComponent componentParent
  return template if template and (template instanceof Blaze.Template or _.isFunction template)

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

registerHooks = (template, hooks) ->
  if template.onCreated
    template.onCreated hooks.onCreated
    template.onRendered hooks.onRendered
    template.onDestroyed hooks.onDestroyed
  else
    # XXX COMPAT WITH METEOR 1.0.3.2.
    template.created = hooks.onCreated
    template.rendered = hooks.onRendered
    template.destroyed = hooks.onDestroyed

registerFirstCreatedHook = (template, onCreated) ->
  if template._callbacks
    template._callbacks.created.unshift onCreated
  else
    # XXX COMPAT WITH METEOR 1.0.3.2.
    oldCreated = template.created
    template.created = ->
      onCreated.call @
      oldCreated?.call @

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

  requireMixin: (nameOrMixin) ->
    # Do not do anything if mixin is already required. This allows multiple mixins to call requireMixin
    # in mixinParent method to add dependencies, but if dependencies are already there, nothing happens.
    return @ if @getMixin nameOrMixin

    if _.isString nameOrMixin
      # It could be that the component is not a real instance of the BlazeComponent class,
      # so it might not have a constructor pointing back to a BlazeComponent subclass.
      if @constructor.getComponent
        mixinInstanceComponent = @constructor.getComponent nameOrMixin
      else
        mixinInstanceComponent = BlazeComponent.getComponent nameOrMixin
      throw new Error "Unknown mixin '#{ nameOrMixin }'." unless mixinInstanceComponent
      mixinInstance = new mixinInstanceComponent()
    else if _.isFunction nameOrMixin
      mixinInstance = new nameOrMixin()
    else
      mixinInstance = nameOrMixin

    # We add mixin before we call mixinParent so that dependencies come after this mixin,
    # and that we prevent possible infinite loops because of circular dependencies.
    # TODO: For now we do not provide an official API to add dependencies before the mixin itself.
    @_mixins.push mixinInstance

    # We allow mixins to not be components, so methods are not necessary available.

    # Set mixin parent.
    if mixinInstance.mixinParent
      mixinInstance.mixinParent @
      assert.equal mixinInstance.mixinParent(), @

    # Maybe mixin has its own mixins as well.
    mixinInstance.createMixins?()

    # If a mixin is adding a dependency using requireMixin after its mixinParent class (for example, in onCreate)
    # and this is this dependency mixin, the view might already be created or rendered and callbacks were
    # already called, so we should call them manually here as well. But only if he view has not been destroyed
    # already. For those mixins we do not call anything, there is little use for them now.
    unless @templateInstance?.view.isDestroyed
      mixinInstance.onCreated?() if not @_inOnCreated and @templateInstance?.view.isCreated
      mixinInstance.onRendered?() if not @_inOnRendered and @templateInstance?.view.isRendered

    # To allow chaining.
    @

  # Method to instantiate all mixins.
  createMixins: ->
    # To allow calling it multiple times, but non-first calls are simply ignored.
    return if @_mixins
    @_mixins = []

    for mixin in @mixins()
      @requireMixin mixin

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

    null

  # Calls the component (if afterComponentOrMixin is null) or the first next mixin
  # after afterComponentOrMixin it finds, and returns the result.
  callFirstWith: (afterComponentOrMixin, propertyName, args...) ->
    mixin = @getFirstWith afterComponentOrMixin, propertyName

    # TODO: Should we throw an error here? Something like calling a function which does not exist?
    return unless mixin

    if _.isFunction mixin[propertyName]
      return mixin[propertyName] args...
    else
      return mixin[propertyName]

  getFirstWith: (afterComponentOrMixin, propertyName) ->
    assert @_mixins

    # If afterComponentOrMixin is not provided, we start with the component.
    if not afterComponentOrMixin
      return @ if propertyName of @
      # And continue with mixins.
      found = true
    # If afterComponentOrMixin is the component, we start with mixins.
    else if afterComponentOrMixin and afterComponentOrMixin is @
      found = true
    else
      found = false

    # TODO: Implement with a map between mixin -> position, so that we do not have to seek to find a mixin.
    for mixin in @_mixins
      return mixin if found and propertyName of mixin

      found = true if mixin is afterComponentOrMixin

    null

  # This class method more or less just creates an instance of a component and calls its renderComponent
  # method. But because we want to allow passing arguments to the component in templates, we have some
  # complicated code around to extract and pass those arguments. It is similar to how data context is
  # passed to block helpers. In a data context visible only to the block helper template.
  # TODO: This could be made less hacky. See https://github.com/meteor/meteor/issues/3913
  @renderComponent: (componentParent) ->
    Tracker.nonreactive =>
      componentClass = @

      try
        # We check data context in a non-reactive way, because we want just to peek into it
        # and determine if data context contains component arguments or not. And while
        # component arguments might change through time, the fact that they are there at
        # all or not ("args" template helper was used or not) does not change through time.
        # So we can check that non-reactively.
        data = Template.currentData()
      catch error
        # The exception can be thrown when there is no current view which happens when
        # there is no data context yet, thus also no arguments were provided through
        # "args" template helper, so we just continue normally.
        data = null

      if data?.constructor isnt argumentsConstructor
        component = new componentClass()
        return component.renderComponent componentParent

      # Arguments were provided through "args" template helper.

      # We want to reactively depend on the data context for arguments, so we return a function
      # instead of a template. Function will be run inside an autorun, a reactive context.
      ->
        # We cannot use Template.getData() inside a normal autorun because current view is not defined inside
        # a normal autorun. But we do not really have to depend reactively on the current view, only on the
        # data context of a known (the closest Blaze.With) view. So we get this view by ourselves.
        currentWith = Blaze.getView 'with'

        # By default dataVar in the Blaze.With view uses ReactiveVar with default equality function which
        # sees all objects as different. So invalidations are triggered for every data context assignments
        # even if data has not really changed. This is why we use our own ReactiveVar with EJSON.equals
        # which we keep updated inside an autorun. Because it uses EJSON.equals it will invalidate our
        # function only if really changes. See https://github.com/meteor/meteor/issues/4073
        reactiveArguments = new ReactiveVar [], EJSON.equals

        # This autorun is nested in the outside autorun so it gets stopped
        # automatically when the outside autorun gets invalidated.
        assert Tracker.active
        Tracker.autorun (computation) ->
          data = currentWith.dataVar.get()
          assert.equal data?.constructor, argumentsConstructor
          reactiveArguments.set data._arguments

        # Use arguments for the constructor. Here we register a reactive dependency on our own ReactiveVar.
        component = new componentClass reactiveArguments.get()...

        template = component.renderComponent componentParent

        # It has to be the first callback so that other have a correct data context.
        registerFirstCreatedHook template, ->
          # Arguments were passed in as a data context. Restore original (parent) data
          # context. Same logic as in Blaze._InOuterTemplateScope.
          @view.originalParentView = @view.parentView
          @view.parentView = @view.parentView.parentView.parentView

        return template

  renderComponent: (componentParent) ->
    # To make sure we do not introduce any reactive dependency. This is a conscious design decision.
    # Reactivity should be changing data context, but components should be more stable, only changing
    # when structure change in rendered DOM. You can change the component you are including (or pass
    # different arguments) reactively though.
    Tracker.nonreactive =>
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

      registerHooks template,
        onCreated: ->
          # @ is a template instance.

          if componentParent
            # TODO: Should we support that the same component can be rendered multiple times in parallel? How could we do that? For different component parents or only the same one?
            assert not @componentParent()

            # We set the parent only when the component is created, not just constructed.
            component.componentParent componentParent
            componentParent.addComponentChild component

          @view._onViewRendered =>
            # Attach events the first time template instance renders.
            return unless @view.renderCount is 1

            # We first add event handlers from the component, then mixins.
            componentOrMixin = null
            while componentOrMixin = @component.getFirstWith componentOrMixin, 'events'
              addEvents @view, componentOrMixin

          @component = component

          # TODO: Should we support that the same component can be rendered multiple times in parallel? How could we do that? For different component parents or only the same one?
          assert not @component.templateInstance
          @component.templateInstance = @

          try
            # We have to know if we should call onCreated on the mixin inside the requireMixin or not. We want to call
            # it only once. If it requireMixin is called from onCreated of another mixin, then it will be added at the
            # end and we will get it here at the end. So we should not call onCreated inside requireMixin because then
            # onCreated would be called twice.
            @component._inOnCreated = true
            componentOrMixin = null
            while componentOrMixin = @component.getFirstWith componentOrMixin, 'onCreated'
              componentOrMixin.onCreated()
          finally
            delete @component._inOnCreated

        onRendered: ->
          # @ is a template instance.
          try
            # Same as for onCreated above.
            @component._inOnRendered = true
            componentOrMixin = null
            while componentOrMixin = @component.getFirstWith componentOrMixin, 'onRendered'
              componentOrMixin.onRendered()
          finally
            delete @component._inOnRendered

        onDestroyed: ->
          @autorun (computation) =>
            # We wait for all children components to be destroyed first.
            # See https://github.com/meteor/meteor/issues/4166
            return if @component.componentChildren().length
            computation.stop()

            # @ is a template instance.
            componentOrMixin = null
            while componentOrMixin = @component.getFirstWith componentOrMixin, 'onDestroyed'
              componentOrMixin.onDestroyed()

            if componentParent
              # The component has been destroyed, clear up the parent.
              component.componentParent null
              componentParent.removeComponentChild component

            # Remove the reference so that it is clear that template instance is not available anymore.
            delete @component.templateInstance

      template

  template: ->
    # You have to override this method with a method which returns a template name or template itself.
    throw new Error "Component method 'template' not overridden."

  onCreated: ->

  onRendered: ->

  onDestroyed: ->

  insertDOMElement: (parent, node, before) ->
    before ?= null
    if parent and node and (node.parentNode isnt parent or node.nextSibling isnt before)
      parent.insertBefore node, before

    return

  moveDOMElement: (parent, node, before) ->
    before ?= null
    if parent and node and (node.parentNode isnt parent or node.nextSibling isnt before)
      parent.insertBefore node, before

    return

  removeDOMElement: (parent, node) ->
    if parent and node and node.parentNode is parent
      parent.removeChild node

    return

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

  # Useful in templates to get a reference to the component.
  component: ->
    @

  # Caller-level component. In most cases the same as @, but in event handlers
  # it returns the component at the place where event originated (target component).
  currentComponent: ->
    Template.instance()?.get('component') or null

  firstNode: ->
    @templateInstance.firstNode

  lastNode: ->
    @templateInstance.lastNode

# We copy utility methods ($, findAll, autorun, subscribe, etc.) from the template instance prototype.
for methodName, method of Blaze.TemplateInstance::
  do (methodName, method) ->
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
