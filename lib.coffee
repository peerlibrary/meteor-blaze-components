# TODO: Deduplicate between base component, blaze component, and common component packages.
createMatcher = (propertyOrMatcherOrFunction) ->
  if _.isString propertyOrMatcherOrFunction
    property = propertyOrMatcherOrFunction
    propertyOrMatcherOrFunction = (child, parent) =>
      # If child is parent, we might get into an infinite loop if this is
      # called from getFirstWith, so in that case we do not use getFirstWith.
      if child isnt parent and child.getFirstWith
        !!child.getFirstWith null, property
      else
        property of child

  else if not _.isFunction propertyOrMatcherOrFunction
    assert _.isObject propertyOrMatcherOrFunction
    matcher = propertyOrMatcherOrFunction
    propertyOrMatcherOrFunction = (child, parent) =>
      for property, value of matcher
        # If child is parent, we might get into an infinite loop if this is
        # called from getFirstWith, so in that case we do not use getFirstWith.
        if child isnt parent and child.getFirstWith
          childWithProperty = child.getFirstWith null, property
        else
          childWithProperty = child if property of child
        return false unless childWithProperty

        if _.isFunction childWithProperty[property]
          return false unless childWithProperty[property]() is value
        else
          return false unless childWithProperty[property] is value

      true

  propertyOrMatcherOrFunction

getTemplateInstance = (view, skipBlockHelpers) ->
  while view and not view._templateInstance
    if skipBlockHelpers
      view = view.parentView
    else
      view = view.originalParentView or view.parentView

  view?._templateInstance

# More or less the same as aldeed:template-extension's template.get('component') just specialized.
# It allows us to not have a dependency on template-extension package and that we can work with Iron
# Router which has its own DynamicTemplate class which is not patched by template-extension and thus
# does not have .get() method.
templateInstanceToComponent = (templateInstanceFunc, skipBlockHelpers) ->
  templateInstance = templateInstanceFunc?()

  # Iron Router uses its own DynamicTemplate which is not a proper template instance, but it is
  # passed in as such, so we want to find the real one before we start searching for the component.
  templateInstance = getTemplateInstance templateInstance?.view, skipBlockHelpers

  while templateInstance
    return templateInstance.component if 'component' of templateInstance

    if skipBlockHelpers
      templateInstance = getTemplateInstance templateInstance.view.parentView, skipBlockHelpers
    else
      templateInstance = getTemplateInstance (templateInstance.view.originalParentView or templateInstance.view.parentView), skipBlockHelpers

  null

getTemplateInstanceFunction = (view, skipBlockHelpers) ->
  templateInstance = getTemplateInstance view, skipBlockHelpers
  ->
    templateInstance

class ComponentsNamespaceReference
  constructor: (@namespace, @templateInstance) ->

# We extend the original dot operator to support {{> Foo.Bar}}. This goes through a getTemplateHelper path, but
# we want to redirect it to the getTemplate path. So we mark it in getTemplateHelper and then here call getTemplate.
originalDot = Spacebars.dot
Spacebars.dot = (value, args...) ->
  if value instanceof ComponentsNamespaceReference
    return Blaze._getTemplate "#{value.namespace}.#{args.join '.'}", value.templateInstance

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
#   a property of the current component (not the BlazeComponent.currentComponent() though, but @component())
#   a helper of the current component's base template (not the BlazeComponent.currentComponent() though, but @component())
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
    # We want to skip any block helper. {{method}} should resolve to
    # {{component.method}} and not to {{currentComponent.method}}.
    templateInstanceToComponent templateInstance, true

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

  # Maybe a preexisting template helper on the component's base template.
  if component
    if (helper = component._componentInternals?.templateBase?.__helpers.get name)?
      return wrapHelper bindDataContext(helper), templateInstance

  null

share.inExpandAttributes = false

bindComponent = (component, helper) ->
  if _.isFunction helper
    (args...) ->
      result = helper.apply component, args

      # If we are expanding attributes and this is an object with dynamic attributes,
      # then we want to bind all possible event handlers to the component as well.
      if share.inExpandAttributes and _.isObject result
        for name, value of result when share.EVENT_HANDLER_REGEX.test name
          if _.isFunction value
            result[name] = _.bind value, component
          else if _.isArray value
            result[name] = _.map value, (fun) ->
              if _.isFunction fun
                _.bind fun, component
              else
                fun

      result
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

getTemplateBase = (component) ->
  # We do not allow template to be a reactive method.
  Tracker.nonreactive ->
    componentTemplate = component.template()
    if _.isString componentTemplate
      templateBase = Template[componentTemplate]
      throw new Error "Template '#{componentTemplate}' cannot be found." unless templateBase
    else if componentTemplate
      templateBase = componentTemplate
    else
      throw new Error "Template for the component '#{component.componentName() or 'unnamed'}' not provided."

    templateBase

callTemplateBaseHooks = (component, hookName) ->
  component._componentInternals ?= {}

  # In mixins we do not have a template instance. There is also
  # no reason for a template instance to extend a Blaze template.
  return unless component._componentInternals.templateInstance

  templateInstance = Tracker.nonreactive ->
    component._componentInternals.templateInstance()
  callbacks = component._componentInternals.templateBase._getCallbacks hookName
  Template._withTemplateInstanceFunc(
    ->
      templateInstance
  ,
    ->
      for callback in callbacks
        callback.call templateInstance
  )

  return

wrapViewAndTemplate = (currentView, f) ->
  # For template content wrapped inside the block helper, we want to skip the block
  # helper when searching for corresponding template. This means that Template.instance()
  # will return the component's template, while BlazeComponent.currentComponent() will
  # return the component inside.
  templateInstance = getTemplateInstanceFunction currentView, true

  # We set template instance to match the current view (mostly, only not when inside
  # the block helper). The latter we use for BlazeComponent.currentComponent(), but
  # it is good that both template instance and current view correspond to each other
  # as much as possible.
  withTemplateInstanceFunc templateInstance, ->
    # We set view based on the current view so that inside event handlers
    # BlazeComponent.currentData() (and Blaze.getData() and Template.currentData())
    # returns data context of event target and not component/template. Moreover,
    # inside event handlers BlazeComponent.currentComponent() returns the component
    # of event target.
    Blaze._withCurrentView currentView, ->
      f()

addEvents = (view, component) ->
  eventsList = component.events()

  throw new Error "'events' method from the component '#{component.componentName() or 'unnamed'}' did not return a list of event maps." unless _.isArray eventsList

  for events in eventsList
    eventMap = {}

    for spec, handler of events
      do (spec, handler) ->
        eventMap[spec] = (args...) ->
          event = args[0]

          currentView = Blaze.getView event.currentTarget
          wrapViewAndTemplate currentView, ->
            handler.apply component, args

          # Make sure CoffeeScript does not return anything.
          # Returning from event handlers is deprecated.
          return

    Blaze._addEventMap view, eventMap, view

  return

originalGetTemplate = Blaze._getTemplate
Blaze._getTemplate = (name, templateInstance) ->
  # Blaze.View::lookup should not introduce any reactive dependencies, so we are making sure it is so.
  template = Tracker.nonreactive ->
    if Blaze.currentView
      parentComponent = BlazeComponent.currentComponent()
    else
      # We do not skip block helpers to assure that when block helpers are used,
      # component tree integrates them nicely into a tree.
      parentComponent = templateInstanceToComponent templateInstance, false

    BlazeComponent.getComponent(name)?.renderComponent parentComponent
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

argumentsConstructor = ->
  # This class should never really be created.
  assert false

# TODO: Find a way to pass arguments to the component without having to introduce one intermediary data context into the data context hierarchy.
#       (In fact two data contexts, because we add one more when restoring the original one.)
Template.registerHelper 'args', ->
  obj = {}
  # We use custom constructor to know that it is not a real data context.
  obj.constructor = argumentsConstructor
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
    wrapViewAndTemplate currentView, ->
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

currentViewIfRendering = ->
  view = Blaze.currentView
  if view?._isInRender
    view
  else
    null

contentAsFunc = (content) ->
  # We do not check content for validity.

  if !_.isFunction content
    return ->
      content

  content

contentAsView = (content) ->
  # We do not check content for validity.

  if content instanceof Blaze.Template
    content.constructView()
  else if content instanceof Blaze.View
    content
  else
    Blaze.View 'render', contentAsFunc content

HTMLJSExpander = Blaze._HTMLJSExpander.extend()
HTMLJSExpander.def
  # Based on Blaze._HTMLJSExpander, but calls our expandView.
  visitObject: (x) ->
    if x instanceof Blaze.Template
      x = x.constructView()
    if x instanceof Blaze.View
      return expandView x, @parentView

    HTML.TransformingVisitor.prototype.visitObject.call @, x

# Based on Blaze._expand, but uses our HTMLJSExpander.
expand = (htmljs, parentView) ->
  parentView = parentView or currentViewIfRendering()

  (new HTMLJSExpander parentView: parentView).visit htmljs

# Based on Blaze._expandView, but with flushing.
expandView = (view, parentView) ->
  Blaze._createView view, parentView, true

  view._isInRender = true
  htmljs = Blaze._withCurrentView view, ->
    view._render()
  view._isInRender = false

  Tracker.flush()

  result = expand htmljs, view

  Tracker.flush()

  if Tracker.active
    Tracker.onInvalidate ->
      Blaze._destroyView view
  else
    Blaze._destroyView view

  Tracker.flush()

  result

class BlazeComponent extends BaseComponent
  # TODO: Figure out how to do at the BaseComponent level?
  @getComponentForElement: (domElement) ->
    return null unless domElement

    # This uses the same check if the argument is a DOM element that Blaze._DOMRange.forElement does.
    throw new Error "Expected DOM element." unless domElement.nodeType is Node.ELEMENT_NODE

    # For DOM elements we want to return the component which matches the template
    # with that DOM element and not the component closest in the component tree.
    # So we skip the block helpers. (If DOM element is rendered by the block helper
    # this will find that block helper template/component.)
    templateInstance = getTemplateInstanceFunction Blaze.getView(domElement), true
    templateInstanceToComponent templateInstance, true

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
        throw new Error "Unknown mixin '#{nameOrMixin}'." unless mixinInstanceComponent
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
    if _.isString nameOrMixin
      # By passing @ as the first argument, we traverse only mixins.
      @getFirstWith @, (child, parent) =>
        # We do not require mixins to be components, but if they are, they can
        # be referenced based on their component name.
        mixinComponentName = child.componentName?() or null
        return mixinComponentName and mixinComponentName is nameOrMixin
    else
      # By passing @ as the first argument, we traverse only mixins.
      @getFirstWith @, (child, parent) =>
        # nameOrMixin is a class.
        return true if child.constructor is nameOrMixin

        # nameOrMixin is an instance, or something else.
        return true if child is nameOrMixin

        false

  # Calls the component (if afterComponentOrMixin is null) or the first next mixin
  # after afterComponentOrMixin it finds, and returns the result.
  callFirstWith: (afterComponentOrMixin, propertyName, args...) ->
    assert _.isString propertyName

    componentOrMixin = @getFirstWith afterComponentOrMixin, propertyName

    # TODO: Should we throw an error here? Something like calling a function which does not exist?
    return unless componentOrMixin

    # If it is current component, we do not call callFirstWith, to prevent an infinite loop.
    # componentOrMixin might not have callFirstWith if it is a mixin which does not inherit
    # from the Blaze Component.
    if componentOrMixin is @ or not componentOrMixin.callFirstWith
      if _.isFunction componentOrMixin[propertyName]
        return componentOrMixin[propertyName] args...
      else
        return componentOrMixin[propertyName]
    else
      return componentOrMixin.callFirstWith null, propertyName, args...

  getFirstWith: (afterComponentOrMixin, propertyOrMatcherOrFunction) ->
    assert @_componentInternals?.mixins

    propertyOrMatcherOrFunction = createMatcher propertyOrMatcherOrFunction

    # If afterComponentOrMixin is not provided, we start with the component.
    if not afterComponentOrMixin
      return @ if propertyOrMatcherOrFunction.call @, @, @
      # And continue with mixins.
      found = true
    # If afterComponentOrMixin is the component, we start with mixins.
    else if afterComponentOrMixin and afterComponentOrMixin is @
      found = true
    else
      found = false

    # TODO: Implement with a map between mixin -> position, so that we do not have to seek to find a mixin.
    for mixin in @_componentInternals.mixins
      return mixin if found and propertyOrMatcherOrFunction.call @, mixin, @

      found = true if mixin is afterComponentOrMixin

    null

  # This class method more or less just creates an instance of a component and calls its renderComponent
  # method. But because we want to allow passing arguments to the component in templates, we have some
  # complicated code around to extract and pass those arguments. It is similar to how data context is
  # passed to block helpers. In a data context visible only to the block helper template.
  # TODO: This could be made less hacky. See https://github.com/meteor/meteor/issues/3913
  @renderComponent: (parentComponent) ->
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

      if data?.constructor isnt argumentsConstructor
        # So that currentComponent in the constructor can return the component
        # inside which this component has been constructed.
        return wrapViewAndTemplate Blaze.currentView, =>
          component = new componentClass()

          return component.renderComponent parentComponent

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
          assert.equal data?.constructor, argumentsConstructor
          data._arguments
        ,
          EJSON.equals

        # Here we register a reactive dependency on the ComputedField.
        nonreactiveArguments = reactiveArguments()

        Tracker.nonreactive ->
          # Arguments were passed in as a data context. We want currentData in the constructor to return the
          # original (parent) data context. Like we were not passing in arguments as a data context.
          template = Blaze._withCurrentView Blaze.currentView.parentView.parentView, =>
            # So that currentComponent in the constructor can return the component
            # inside which this component has been constructed.
            return wrapViewAndTemplate Blaze.currentView, =>
              # Use arguments for the constructor.
              component = new componentClass nonreactiveArguments...

              return component.renderComponent parentComponent

          # It has to be the first callback so that other have a correct data context.
          registerFirstCreatedHook template, ->
            # Arguments were passed in as a data context. Restore original (parent) data
            # context. Same logic as in Blaze._InOuterTemplateScope.
            @view.originalParentView = @view.parentView
            @view.parentView = @view.parentView.parentView.parentView

          template

  renderComponent: (parentComponent) ->
    # To make sure we do not introduce any reactive dependency. This is a conscious design decision.
    # Reactivity should be changing data context, but components should be more stable, only changing
    # when structure change in rendered DOM. You can change the component you are including (or pass
    # different arguments) reactively though.
    Tracker.nonreactive =>
      component = @

      # If mixins have not yet been created.
      component.createMixins()

      templateBase = getTemplateBase component

      # Create a new component template based on the Blaze template. We want our own template
      # because the same Blaze template could be reused between multiple components.
      # TODO: Should we cache these templates based on (componentName, templateBase) pair? We could use two levels of ES2015 Maps, componentName -> templateBase -> template. What about component arguments changing?
      template = new Blaze.Template "BlazeComponent.#{component.componentName() or 'unnamed'}", templateBase.renderFunction

      # We lookup preexisting template helpers in Blaze._getTemplateHelper, if the component does not have
      # a property with the same name. Preexisting event handlers and life-cycle hooks are taken care of
      # in the related methods in the base class.

      component._componentInternals ?= {}
      component._componentInternals.templateBase = templateBase

      registerHooks template,
        onCreated: ->
          # @ is a template instance.

          if parentComponent
            # component.parentComponent is reactive, so we use Tracker.nonreactive just to make sure we do not leak any reactivity here.
            Tracker.nonreactive =>
              # TODO: Should we support that the same component can be rendered multiple times in parallel? How could we do that? For different component parents or only the same one?
              assert not component.parentComponent()

              # We set the parent only when the component is created, not just constructed.
              component.parentComponent parentComponent
              parentComponent.addChildComponent component

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

          @component._componentInternals.isCreated ?= new ReactiveField true
          @component._componentInternals.isCreated true

          # Maybe we are re-rendering the component. So let's initialize variables just to be sure.

          @component._componentInternals.isRendered ?= new ReactiveField false
          @component._componentInternals.isRendered false

          @component._componentInternals.isDestroyed ?= new ReactiveField false
          @component._componentInternals.isDestroyed false

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

        onRendered: ->
          # @ is a template instance.

          @component._componentInternals.isRendered ?= new ReactiveField true
          @component._componentInternals.isRendered true

          Tracker.nonreactive =>
            assert.equal @component._componentInternals.isCreated(), true

          try
            # Same as for onCreated above.
            @component._componentInternals.inOnRendered = true
            componentOrMixin = null
            while componentOrMixin = @component.getFirstWith componentOrMixin, 'onRendered'
              componentOrMixin.onRendered()
          finally
            delete @component._componentInternals.inOnRendered

        onDestroyed: ->
          @autorun (computation) =>
            # @ is a template instance.

            # We wait for all children components to be destroyed first.
            # See https://github.com/meteor/meteor/issues/4166
            return if @component.childComponents().length
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

              if parentComponent
                # The component has been destroyed, clear up the parent.
                component.parentComponent null
                parentComponent.removeChildComponent component

              # Remove the reference so that it is clear that template instance is not available anymore.
              @component._componentInternals.templateInstance null

      template

  removeComponent: ->
    Blaze.remove @_componentInternals.templateInstance().view if @isRendered()

  @renderComponentToHTML: (parentComponent, parentView, data) ->
    component = Tracker.nonreactive =>
      componentClass = @

      parentView = parentView or currentViewIfRendering() or (parentComponent?.isRendered() and parentComponent._componentInternals.templateInstance().view) or null

      wrapViewAndTemplate parentView, =>
        new componentClass()

    if arguments.length > 2
      component.renderComponentToHTML parentComponent, parentView, data
    else
      component.renderComponentToHTML parentComponent, parentView

  renderComponentToHTML: (parentComponent, parentView, data) ->
    template = Tracker.nonreactive =>
      parentView = parentView or currentViewIfRendering() or (parentComponent?.isRendered() and parentComponent._componentInternals.templateInstance().view) or null

      wrapViewAndTemplate parentView, =>
        @renderComponent parentComponent

    if arguments.length > 2
      expandedView = expandView Blaze._TemplateWith(data, contentAsFunc template), parentView
    else
      expandedView = expandView contentAsView(template), parentView

    HTML.toHTML expandedView

  template: ->
    @callFirstWith(@, 'template') or @constructor.componentName()

  onCreated: ->
    callTemplateBaseHooks @, 'created'

  onRendered: ->
    callTemplateBaseHooks @, 'rendered'

  onDestroyed: ->
    callTemplateBaseHooks @, 'destroyed'

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
    @_componentInternals ?= {}

    # In mixins we do not have a template instance. There is also
    # no reason for a template instance to extend a Blaze template.
    return [] unless @_componentInternals.templateInstance

    view = Tracker.nonreactive =>
      @_componentInternals.templateInstance().view
    # We skip block helpers to match Blaze behavior.
    templateInstance = getTemplateInstanceFunction view, true

    for events in @_componentInternals.templateBase.__eventMaps
      eventMap = {}

      for spec, handler of events
        do (spec, handler) ->
          eventMap[spec] = (args...) ->
            # In template event handlers view and template instance are not based on the current target
            # (like Blaze Components event handlers are) but it is based on the template-level view.
            # In a way we are reverting here what addEvents does.
            withTemplateInstanceFunc templateInstance, ->
              Blaze._withCurrentView view, ->
                handler.apply view, args

      eventMap

  # Component-level data context. Reactive. Use this to always get the
  # top-level data context used to render the component. If path is
  # provided, it returns only the value under that path, with reactivity
  # limited to changes of that value only.
  data: (path, equalsFunc) ->
    @_componentInternals ?= {}
    @_componentInternals.templateInstance ?= new ReactiveField null, (a, b) -> a is b

    if view = @_componentInternals.templateInstance()?.view
      if path?
        return DataLookup.get =>
          Blaze.getData view
        ,
          path, equalsFunc
      else
        return Blaze.getData view

    undefined

  # Caller-level data context. Reactive. Use this to get in event handlers the data
  # context at the place where event originated (target context). In template helpers
  # the data context where template helpers were called. In onCreated, onRendered,
  # and onDestroyed, the same as @data(). Inside a template this is the same as this.
  # If path is provided, it returns only the value under that path, with reactivity
  # limited to changes of that value only. Moreover, if path is provided is also
  # looks into the current lexical scope data.
  @currentData: (path, equalsFunc) ->
    return undefined unless Blaze.currentView

    currentView = Blaze.currentView

    if _.isString path
      path = path.split '.'
    else if not _.isArray path
      return Blaze.getData currentView

    DataLookup.get =>
      if Blaze._lexicalBindingLookup and lexicalData = Blaze._lexicalBindingLookup currentView, path[0]
        # We return custom data object so that we can reuse the same
        # lookup logic for both lexical and the normal data context case.
        result = {}
        result[path[0]] = lexicalData
        return result

      Blaze.getData currentView
    ,
      path, equalsFunc

  # Method should never be overridden. The implementation should always be exactly the same as class method implementation.
  currentData: (path, equalsFunc) ->
    @constructor.currentData path, equalsFunc

  # Useful in templates to get a reference to the component.
  component: ->
    @

  # Caller-level component. In most cases the same as @, but in event handlers
  # it returns the component at the place where event originated (target component).
  # Inside template content wrapped with a block helper component, it is the closest
  # block helper component.
  @currentComponent: ->
    # We are not skipping block helpers because one of main reasons for @currentComponent()
    # is that we can get hold of the block helper component instance.
    templateInstance = getTemplateInstanceFunction Blaze.currentView, false
    templateInstanceToComponent templateInstance, false

  # Method should never be overridden. The implementation should always be exactly the same as class method implementation.
  currentComponent: ->
    @constructor.currentComponent()

  firstNode: ->
    return @_componentInternals.templateInstance().view._domrange.firstNode() if @isRendered()

    undefined

  lastNode: ->
    return @_componentInternals.templateInstance().view._domrange.lastNode() if @isRendered()

    undefined

  # The same as it would be generated automatically, only that the runFunc gets bound to the component.
  autorun: (runFunc) ->
    templateInstance = Tracker.nonreactive =>
      @_componentInternals?.templateInstance?()

    throw new Error "The component has to be created before calling 'autorun'." unless templateInstance

    templateInstance.autorun _.bind runFunc, @

SUPPORTS_REACTIVE_INSTANCE = [
  'subscriptionsReady'
]

REQUIRE_RENDERED_INSTANCE = [
  '$',
  'find',
  'findAll'
]

# We copy utility methods ($, findAll, subscribe, etc.) from the template instance prototype,
# if a method with the same name does not exist already.
for methodName, method of (Blaze.TemplateInstance::) when methodName not of (BlazeComponent::)
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
