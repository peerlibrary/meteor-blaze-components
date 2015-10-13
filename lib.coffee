getTemplateInstance = (view) ->
  while view and not view._templateInstance
    view = view.parentView

  view?._templateInstance

# More or less the same as aldeed:template-extension's template.get('component') just specialized.
# It allows us to not have a dependency on template-extension package and that we can work with Iron
# Router which has its own DynamicTemplate class which is not patched by template-extension and thus
# does not have .get() method.
templateInstanceToComponent = (templateInstanceFunc) ->
  templateInstance = templateInstanceFunc?()

  # Iron Router uses its own DynamicTemplate which is not a proper template instance, but it is
  # passed in as such, so we want to find the real one before we start searching for the component.
  templateInstance = getTemplateInstance templateInstance?.view

  while templateInstance
    return templateInstance.component if 'component' of templateInstance

    templateInstance = getTemplateInstance templateInstance.view.parentView

  null

getTemplateInstanceFunction = (view) ->
  templateInstance = getTemplateInstance view
  ->
    templateInstance

class ComponentsNamespaceReference
  constructor: (@namespace, @templateInstance) ->

# We extend the original dot operator to support {{> Foo.Bar}}. This goes through a getTemplateHelper path, but
# we want to redirect it to the getTemplate path. So we mark it in getTemplateHelper and then here call getTemplate.
originalDot = Spacebars.dot
Spacebars.dot = (value, args...) ->
  if value instanceof ComponentsNamespaceReference
    return Blaze._getTemplate "#{ value.namespace }.#{ args.join '.' }", value.templateInstance

  originalDot value, args...

originalInclude = Spacebars.include
Spacebars.include = (templateOrFunction, args...) ->
  # If ComponentsNamespaceReference gets all the way to the Spacebars.include it means that we are in the situation
  # where there is both namespace and component with the same name, and user is including a component. But namespace
  # reference is created instead (because we do not know in advance that there is no Spacebars.dot call around lookup
  # call). So we dereference the reference and try to resolve a template. Of course, a component might not really exist.
  if templateOrFunction instanceof ComponentsNamespaceReference
    templateOrFunction = Blaze._getTemplate templateOrFunction.namespace, templateOrFunction.templateInstance

  originalInclude templateOrFunction, args...

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

  # Do not resolve component helpers if inside Template.dynamic. The reason is that Template.dynamic uses a data context
  # value with name "template" internally. But when used inside a component the data context lookup is then resolved
  # into a current component's template method and not the data context "template". To force the data context resolving
  # Template.dynamic should use "this.template" in its templates, but it does not, so we have a special case here for it.
  return null if template.viewName in ['Template.__dynamicWithDataContext', 'Template.__dynamic']

  # Blaze.View::lookup should not introduce any reactive dependencies, but we can simply ignore reactivity here because
  # template instance probably cannot change without reconstructing the component as well.
  component = Tracker.nonreactive ->
    templateInstanceToComponent templateInstance

  # Component.
  if component
    # This will first search on the component and then continue with mixins.
    if mixinOrComponent = component.getFirstWith null, name
      return wrapHelper bindComponent(mixinOrComponent, mixinOrComponent[name]), templateInstance

  # A special case to support {{> Foo.Bar}}. This goes through a getTemplateHelper path, but we want to redirect
  # it to the getTemplate path. So we mark it and leave to Spacebars.dot to call getTemplate.
  # TODO: We should provide a BaseComponent.getComponentsNamespace method instead of accessing components directly.
  if name and name of BlazeComponent.components
    return new ComponentsNamespaceReference name, templateInstance

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

if Blaze.Template._withTemplateInstanceFunc
  withTemplateInstanceFunc = Blaze.Template._withTemplateInstanceFunc
else
  # XXX COMPAT WITH METEOR 1.0.3.2.
  withTemplateInstanceFunc = (templateInstance, f) ->
    f()

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
          templateInstance = getTemplateInstanceFunction currentView

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
    componentParent = templateInstanceToComponent templateInstance
    BlazeComponent.getComponent(name)?.renderComponent componentParent
  return template if template and (template instanceof Blaze.Template or _.isFunction template)

  originalGetTemplate name

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
  # TODO: Figure out how to do at the BaseComponent level?
  @getComponentForElement: (domElement) ->
    return null unless domElement

    # This uses the same check if the argument is a DOM element that Blaze._DOMRange.forElement does.
    throw new Error "Expected DOM element." unless domElement.nodeType is Node.ELEMENT_NODE

    templateInstanceToComponent =>
      getTemplateInstance Blaze.getView domElement

  mixins: ->
    []

  # When a component is used as a mixin, createMixins will call this method to set the parent
  # component using this mixin. Extend this method if you want to do any action when parent is
  # set, for example, add dependency mixins to the parent. Make sure you call super as well.
  mixinParent: (mixinParent) ->
    @_componentInternals ?= {}

    # Setter.
    if mixinParent
      @_componentInternals.mixinParent = mixinParent
      # To allow chaining.
      return @

    # Getter.
    @_componentInternals.mixinParent or null

  requireMixin: (nameOrMixin) ->
    assert @_componentInternals?.mixins

    Tracker.nonreactive =>
      # Do not do anything if mixin is already required. This allows multiple mixins to call requireMixin
      # in mixinParent method to add dependencies, but if dependencies are already there, nothing happens.
      return if @getMixin nameOrMixin

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
      @_componentInternals.mixins.push mixinInstance

      # We allow mixins to not be components, so methods are not necessary available.

      # Set mixin parent.
      if mixinInstance.mixinParent
        mixinInstance.mixinParent @

      # Maybe mixin has its own mixins as well.
      mixinInstance.createMixins?()

      @_componentInternals.templateInstance ?= new ReactiveField null, (a, b) -> a is b

      # If a mixin is adding a dependency using requireMixin after its mixinParent class (for example, in onCreate)
      # and this is this dependency mixin, the view might already be created or rendered and callbacks were
      # already called, so we should call them manually here as well. But only if he view has not been destroyed
      # already. For those mixins we do not call anything, there is little use for them now.
      unless @_componentInternals.templateInstance()?.view.isDestroyed
        mixinInstance.onCreated?() if not @_componentInternals.inOnCreated and @_componentInternals.templateInstance()?.view.isCreated
        mixinInstance.onRendered?() if not @_componentInternals.inOnRendered and @_componentInternals.templateInstance()?.view.isRendered

    # To allow chaining.
    @

  # Method to instantiate all mixins.
  createMixins: ->
    @_componentInternals ?= {}

    # To allow calling it multiple times, but non-first calls are simply ignored.
    return if @_componentInternals.mixins
    @_componentInternals.mixins = []

    for mixin in @mixins()
      @requireMixin mixin

    # To allow chaining.
    @

  getMixin: (nameOrMixin) ->
    assert @_componentInternals?.mixins

    if _.isString nameOrMixin
      for mixin in @_componentInternals.mixins
        # We do not require mixins to be components, but if they are, they can
        # be referenced based on their component name.
        mixinComponentName = mixin.componentName?() or null
        return mixin if mixinComponentName and mixinComponentName is nameOrMixin

    else
      for mixin in @_componentInternals.mixins
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
    assert @_componentInternals?.mixins

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
    for mixin in @_componentInternals.mixins
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

      if Blaze.currentView
        # We check data context in a non-reactive way, because we want just to peek into it
        # and determine if data context contains component arguments or not. And while
        # component arguments might change through time, the fact that they are there at
        # all or not ("args" template helper was used or not) does not change through time.
        # So we can check that non-reactively.
        data = Template.currentData()
      else
        # There is no current view when there is no data context yet, thus also no arguments
        # were provided through "args" template helper, so we just continue normally.
        data = null

      if data?.constructor isnt share.argumentsConstructor
        templateInstance = getTemplateInstanceFunction Blaze.currentView

        # So that currentComponent in the constructor can return the component inside which this component has been constructed.
        return withTemplateInstanceFunc templateInstance, ->
          component = new componentClass()

          return component.renderComponent componentParent

      # Arguments were provided through "args" template helper.

      # We want to reactively depend on the data context for arguments, so we return a function
      # instead of a template. Function will be run inside an autorun, a reactive context.
      ->
        assert Tracker.active

        # We cannot use Template.getData() inside a normal autorun because current view is not defined inside
        # a normal autorun. But we do not really have to depend reactively on the current view, only on the
        # data context of a known (the closest Blaze.With) view. So we get this view by ourselves.
        currentWith = Blaze.getView 'with'

        # By default dataVar in the Blaze.With view uses ReactiveVar with default equality function which
        # sees all objects as different. So invalidations are triggered for every data context assignments
        # even if data has not really changed. This is why wrap it into a ComputedField with EJSON.equals.
        # Because it uses EJSON.equals it will invalidate our function only if really changes.
        # See https://github.com/meteor/meteor/issues/4073
        reactiveArguments = new ComputedField ->
          data = currentWith.dataVar.get()
          assert.equal data?.constructor, share.argumentsConstructor
          data._arguments
        ,
          EJSON.equals

        # Here we register a reactive dependency on the ComputedField.
        nonreactiveArguments = reactiveArguments()

        Tracker.nonreactive ->
          # Arguments were passed in as a data context. We want currentData in the constructor to return the
          # original (parent) data context. Like we were not passing in arguments as a data context.
          template = Blaze._withCurrentView Blaze.currentView.parentView.parentView, =>
            templateInstance = getTemplateInstanceFunction Blaze.currentView

            # So that currentComponent in the constructor can return the component inside which this component has been constructed.
            return withTemplateInstanceFunc templateInstance, ->
              # Use arguments for the constructor.
              component = new componentClass nonreactiveArguments...

              return component.renderComponent componentParent

          # It has to be the first callback so that other have a correct data context.
          registerFirstCreatedHook template, ->
            # Arguments were passed in as a data context. Restore original (parent) data
            # context. Same logic as in Blaze._InOuterTemplateScope.
            @view.originalParentView = @view.parentView
            @view.parentView = @view.parentView.parentView.parentView

          template

  renderComponent: (componentParent) ->
    # To make sure we do not introduce any reactive dependency. This is a conscious design decision.
    # Reactivity should be changing data context, but components should be more stable, only changing
    # when structure change in rendered DOM. You can change the component you are including (or pass
    # different arguments) reactively though.
    Tracker.nonreactive =>
      component = @

      # If mixins have not yet been created.
      component.createMixins()

      # We do not allow template to be a reactive method.
      componentTemplate = component.template()
      if _.isString componentTemplate
        templateBase = Template[componentTemplate]
        throw new Error "Template '#{ componentTemplate }' cannot be found." unless templateBase
      else if componentTemplate
        templateBase = componentTemplate
      else
        throw new Error "Template for the component '#{ component.componentName() or 'unnamed' }' not provided."

      # Create a new component template based on the Blaze template. We want our own template
      # because the same Blaze template could be reused between multiple components.
      # TODO: Should we cache these templates based on (componentName, templateBase) pair? We could use two levels of ES2015 Maps, componentName -> templateBase -> template. What about component arguments changing?
      template = new Blaze.Template "BlazeComponent.#{ component.componentName() or 'unnamed' }", templateBase.renderFunction

      # We on purpose do not reuse helpers, events, and hooks. Templates are used only for HTML rendering.

      @component._componentInternals ?= {}

      registerHooks template,
        onCreated: ->
          # @ is a template instance.

          if componentParent
            # component.componentParent is reactive, so we use Tracker.nonreactive just to make sure we do not leak any reactivity here.
            Tracker.nonreactive =>
              # TODO: Should we support that the same component can be rendered multiple times in parallel? How could we do that? For different component parents or only the same one?
              assert not component.componentParent()

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
          assert not Tracker.nonreactive => @component._componentInternals.templateInstance?()

          @component._componentInternals.templateInstance ?= new ReactiveField @, (a, b) -> a is b
          @component._componentInternals.templateInstance @

          try
            # We have to know if we should call onCreated on the mixin inside the requireMixin or not. We want to call
            # it only once. If it requireMixin is called from onCreated of another mixin, then it will be added at the
            # end and we will get it here at the end. So we should not call onCreated inside requireMixin because then
            # onCreated would be called twice.
            @component._componentInternals.inOnCreated = true
            componentOrMixin = null
            while componentOrMixin = @component.getFirstWith componentOrMixin, 'onCreated'
              componentOrMixin.onCreated()
          finally
            delete @component._componentInternals.inOnCreated

          @component._componentInternals.isCreated ?= new ReactiveField true
          @component._componentInternals.isCreated true

          # Maybe we are re-rendering the component. So let's initialize variables just to be sure.

          @component._componentInternals.isRendered ?= new ReactiveField false
          @component._componentInternals.isRendered false

          @component._componentInternals.isDestroyed ?= new ReactiveField false
          @component._componentInternals.isDestroyed false

        onRendered: ->
          # @ is a template instance.

          try
            # Same as for onCreated above.
            @component._componentInternals.inOnRendered = true
            componentOrMixin = null
            while componentOrMixin = @component.getFirstWith componentOrMixin, 'onRendered'
              componentOrMixin.onRendered()
          finally
            delete @component._componentInternals.inOnRendered

          @component._componentInternals.isRendered ?= new ReactiveField true
          @component._componentInternals.isRendered true

          Tracker.nonreactive =>
            assert.equal @component._componentInternals.isCreated(), true

        onDestroyed: ->
          @autorun (computation) =>
            # @ is a template instance.

            # We wait for all children components to be destroyed first.
            # See https://github.com/meteor/meteor/issues/4166
            return if @component.componentChildren().length
            computation.stop()

            Tracker.nonreactive =>
              assert.equal @component._componentInternals.isCreated(), true

              @component._componentInternals.isCreated false

              @component._componentInternals.isRendered ?= new ReactiveField false
              @component._componentInternals.isRendered false

              @component._componentInternals.isDestroyed ?= new ReactiveField true
              @component._componentInternals.isDestroyed true

              componentOrMixin = null
              while componentOrMixin = @component.getFirstWith componentOrMixin, 'onDestroyed'
                componentOrMixin.onDestroyed()

              if componentParent
                # The component has been destroyed, clear up the parent.
                component.componentParent null
                componentParent.removeComponentChild component

              # Remove the reference so that it is clear that template instance is not available anymore.
              @component._componentInternals.templateInstance null

      template

  removeComponent: ->
    Blaze.remove @_componentInternals.templateInstance().view if @isRendered()

  template: ->
    @callFirstWith(@, 'template') or @constructor.componentName()

  onCreated: ->

  onRendered: ->

  onDestroyed: ->

  isCreated: ->
    @_componentInternals ?= {}
    @_componentInternals.isCreated ?= new ReactiveField false

    @_componentInternals.isCreated()

  isRendered: ->
    @_componentInternals ?= {}
    @_componentInternals.isRendered ?= new ReactiveField false

    @_componentInternals.isRendered()

  isDestroyed: ->
    @_componentInternals ?= {}
    @_componentInternals.isDestroyed ?= new ReactiveField false

    @_componentInternals.isDestroyed()

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
    @_componentInternals ?= {}
    @_componentInternals.templateInstance ?= new ReactiveField null, (a, b) -> a is b

    if view = @_componentInternals.templateInstance()?.view
      return Blaze.getData view

    undefined

  # Caller-level data context. Reactive. Use this to get in event handlers the data
  # context at the place where event originated (target context). In template helpers
  # the data context where template helpers were called. In onCreated, onRendered,
  # and onDestroyed, the same as @data(). Inside a template this is the same as this.
  @currentData: ->
    return Blaze.getData() if Blaze.currentView

    undefined

  # Method should never be overridden. The implementation should always be exactly the same as class method implementation.
  currentData: ->
    @constructor.currentData()

  # Useful in templates to get a reference to the component.
  component: ->
    @

  # Caller-level component. In most cases the same as @, but in event handlers
  # it returns the component at the place where event originated (target component).
  @currentComponent: ->
    # Template.instance() registers a dependency on the template instance data context,
    # but we do not need that. We just need a template instance to resolve a component.
    Tracker.nonreactive =>
      templateInstanceToComponent Template.instance

  # Method should never be overridden. The implementation should always be exactly the same as class method implementation.
  currentComponent: ->
    @constructor.currentComponent()

  firstNode: ->
    return @_componentInternals.templateInstance().view._domrange.firstNode() if @isRendered()

    undefined

  lastNode: ->
    return @_componentInternals.templateInstance().view._domrange.lastNode() if @isRendered()

    undefined

SUPPORTS_REACTIVE_INSTANCE = [
  'subscriptionsReady'
]

REQUIRE_RENDERED_INSTANCE = [
  '$',
  'find',
  'findAll'
]

# We copy utility methods ($, findAll, autorun, subscribe, etc.) from the template instance prototype.
for methodName, method of Blaze.TemplateInstance::
  do (methodName, method) ->
    if methodName in SUPPORTS_REACTIVE_INSTANCE
      BlazeComponent::[methodName] = (args...) ->
        @_componentInternals ?= {}
        @_componentInternals.templateInstance ?= new ReactiveField null, (a, b) -> a is b

        if templateInstance = @_componentInternals.templateInstance()
          return templateInstance[methodName] args...

        undefined

    else if methodName in REQUIRE_RENDERED_INSTANCE
      BlazeComponent::[methodName] = (args...) ->
        return @_componentInternals.templateInstance()[methodName] args... if @isRendered()

        undefined

    else
      BlazeComponent::[methodName] = (args...) ->
        templateInstance = Tracker.nonreactive =>
          @_componentInternals?.templateInstance?()

        throw new Error "The component has to be created before calling '#{methodName}'." unless templateInstance

        templateInstance[methodName] args...
