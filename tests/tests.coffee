trim = (html) =>
  html = html.replace />\s+/g, '>'
  html = html.replace /\s+</g, '<'
  html.trim()

class MainComponent extends BlazeComponent
  @calls: []

  template: ->
    assert not Tracker.active

    # To test when name of the component mismatches the template name. Template name should have precedence.
    'MainComponent2'

  foobar: ->
    "#{ @componentName() }/MainComponent.foobar/#{ EJSON.stringify @data() }/#{ EJSON.stringify @currentData() }/#{ @currentComponent().componentName() }"

  foobar2: ->
    "#{ @componentName() }/MainComponent.foobar2/#{ EJSON.stringify @data() }/#{ EJSON.stringify @currentData() }/#{ @currentComponent().componentName() }"

  foobar3: ->
    "#{ @componentName() }/MainComponent.foobar3/#{ EJSON.stringify @data() }/#{ EJSON.stringify @currentData() }/#{ @currentComponent().componentName() }"

  isMainComponent: ->
    @constructor is MainComponent

  onClick: (event) ->
    assert not Tracker.active

    @constructor.calls.push [@componentName(), 'MainComponent.onClick', @data(), @currentData(), @currentComponent().componentName()]

  events: ->
    assert not Tracker.active

    [
      'click': @onClick
    ]

BlazeComponent.register 'MainComponent', MainComponent

# Template should match registered name.
class FooComponent extends BlazeComponent

BlazeComponent.register 'FooComponent', FooComponent

class SelfRegisterComponent extends BlazeComponent
  # Alternative way of registering components.
  @register 'SelfRegisterComponent'

class SubComponent extends MainComponent
  @calls: []

  foobar: ->
    "#{ @componentName() }/SubComponent.foobar/#{ EJSON.stringify @data() }/#{ EJSON.stringify @currentData() }/#{ @currentComponent().componentName() }"

  foobar2: ->
    "#{ @componentName() }/SubComponent.foobar2/#{ EJSON.stringify @data() }/#{ EJSON.stringify @currentData() }/#{ @currentComponent().componentName() }"

  # We on purpose do not override foobar3.

  onClick: (event) ->
    @constructor.calls.push [@componentName(), 'SubComponent.onClick', @data(), @currentData(), @currentComponent().componentName()]

BlazeComponent.register 'SubComponent', SubComponent

class UnregisteredComponent extends SubComponent
  foobar: ->
    "#{ @componentName() }/UnregisteredComponent.foobar/#{ EJSON.stringify @data() }/#{ EJSON.stringify @currentData() }/#{ @currentComponent().componentName() }"

  foobar2: ->
    "#{ @componentName() }/UnregisteredComponent.foobar2/#{ EJSON.stringify @data() }/#{ EJSON.stringify @currentData() }/#{ @currentComponent().componentName() }"

# Name has to be set manually.
UnregisteredComponent.componentName 'UnregisteredComponent'

class SelfNameUnregisteredComponent extends UnregisteredComponent
  # Alternative way of setting the name manually.
  @componentName 'SelfNameUnregisteredComponent'

  # We do not extend any helper on purpose. So they should all use "UnregisteredComponent".

class AnimatedListComponent extends BlazeComponent
  @calls: []

  template: ->
    assert not Tracker.active

    'AnimatedListComponent'

  onCreated: ->
    assert not Tracker.active

    # To test inserts, moves, and removals.
    @_list = new ReactiveField [1, 2, 3, 4, 5]
    @_handle = Meteor.setInterval =>
      list = @_list()

      # Moves the last number to the first place.
      list = [list[4]].concat list[0...4]

      # Removes the smallest number.
      list = _.without list, _.min list

      # Adds one more number, one larger than the current largest.
      list = list.concat [_.max(list) + 1]

      @_list list
    , 1000 # ms

  onDestroyed: ->
    assert not Tracker.active

    Meteor.clearInterval @_handle

  list: ->
    _id: i for i in @_list()

  insertDOMElement: (parent, node, before) ->
    assert not Tracker.active

    @constructor.calls.push ['insertDOMElement', @componentName(), trim(parent.outerHTML), trim(node.outerHTML), trim(before?.outerHTML or '')]
    super

  moveDOMElement: (parent, node, before) ->
    assert not Tracker.active

    @constructor.calls.push ['moveDOMElement', @componentName(), trim(parent.outerHTML), trim(node.outerHTML), trim(before?.outerHTML or '')]
    super

  removeDOMElement: (parent, node) ->
    assert not Tracker.active

    @constructor.calls.push ['removeDOMElement', @componentName(), trim(parent.outerHTML), trim(node.outerHTML)]
    super

BlazeComponent.register 'AnimatedListComponent', AnimatedListComponent

class ArgumentsComponent extends BlazeComponent
  @calls: []
  @constructorStateChanges: []
  @onCreatedStateChanges: []

  template: ->
    assert not Tracker.active

    'ArgumentsComponent'

  constructor: ->
    assert not Tracker.active

    @constructor.calls.push arguments[0]
    @arguments = arguments

    @componentId = Random.id()

    @handles = []

    @collectStateChanges @constructor.constructorStateChanges

  onCreated: ->
    assert not Tracker.active

    super

    @collectStateChanges @constructor.onCreatedStateChanges

  collectStateChanges: (output) ->
    output.push
      componentId: @componentId
      view: Blaze.currentView
      templateInstance: Template.instance()

    for method in ['isCreated', 'isRendered', 'isDestroyed', 'data', 'currentData', 'component', 'currentComponent', 'firstNode', 'lastNode', 'subscriptionsReady']
      do (method) =>
        @handles.push Tracker.autorun (computation) =>
          data =
            componentId: @componentId
          data[method] = @[method]()

          output.push data

    @handles.push Tracker.autorun (computation) =>
      output.push
        componentId: @componentId
        find: @find('*')

    @handles.push Tracker.autorun (computation) =>
      output.push
        componentId: @componentId
        findAll: @findAll('*')

    @handles.push Tracker.autorun (computation) =>
      output.push
        componentId: @componentId
        $: @$('*')

  onDestroyed: ->
    assert not Tracker.active

    super

    Tracker.afterFlush =>
      while handle = @handles.pop()
        handle.stop()

  dataContext: ->
    EJSON.stringify @data()

  currentDataContext: ->
    EJSON.stringify @currentData()

  constructorArguments: ->
    EJSON.stringify @arguments

  parentDataContext: ->
    # We would like to make sure data context hierarchy
    # is without intermediate arguments data context.
    EJSON.stringify Template.parentData()

BlazeComponent.register 'ArgumentsComponent', ArgumentsComponent

class MyNamespace

class MyNamespace.Foo

class MyNamespace.Foo.ArgumentsComponent extends ArgumentsComponent
  @register 'MyNamespace.Foo.ArgumentsComponent'

  template: ->
    assert not Tracker.active

    # We could simply use "ArgumentsComponent" here and not have to copy the
    # template, but we want to test if a template name with dots works.
    'MyNamespace.Foo.ArgumentsComponent'

# We want to test if a component with the same name as the namespace can coexist.
class OurNamespace extends ArgumentsComponent
  @register 'OurNamespace'

  template: ->
    assert not Tracker.active

    # We could simply use "ArgumentsComponent" here and not have to copy the
    # template, but we want to test if a template name with dots works.
    'OurNamespace'

class OurNamespace.ArgumentsComponent extends ArgumentsComponent
  @register 'OurNamespace.ArgumentsComponent'

  template: ->
    assert not Tracker.active

    # We could simply use "ArgumentsComponent" here and not have to copy the
    # template, but we want to test if a template name with dots works.
    'OurNamespace.ArgumentsComponent'

reactiveContext = new ReactiveField {}
reactiveArguments = new ReactiveField {}

class ArgumentsTestComponent extends BlazeComponent
  @register 'ArgumentsTestComponent'

  reactiveContext: ->
    reactiveContext()

  reactiveArguments: ->
    reactiveArguments()

Template.namespacedArgumentsTestTemplate.helpers
  reactiveContext: ->
    reactiveContext()

  reactiveArguments: ->
    reactiveArguments()

Template.ourNamespacedArgumentsTestTemplate.helpers
  reactiveContext: ->
    reactiveContext()

  reactiveArguments: ->
    reactiveArguments()

Template.ourNamespaceComponentArgumentsTestTemplate.helpers
  reactiveContext: ->
    reactiveContext()

  reactiveArguments: ->
    reactiveArguments()

class ExistingClassHierarchyBase
  foobar: ->
    "#{ @componentName() }/ExistingClassHierarchyBase.foobar/#{ EJSON.stringify @data() }/#{ EJSON.stringify @currentData() }/#{ @currentComponent().componentName() }"

  foobar2: ->
    "#{ @componentName() }/ExistingClassHierarchyBase.foobar2/#{ EJSON.stringify @data() }/#{ EJSON.stringify @currentData() }/#{ @currentComponent().componentName() }"

  foobar3: ->
    "#{ @componentName() }/ExistingClassHierarchyBase.foobar3/#{ EJSON.stringify @data() }/#{ EJSON.stringify @currentData() }/#{ @currentComponent().componentName() }"

class ExistingClassHierarchyChild extends ExistingClassHierarchyBase

class ExistingClassHierarchyBaseComponent extends ExistingClassHierarchyChild

for property, value of BlazeComponent when property not in ['__super__']
  ExistingClassHierarchyBaseComponent[property] = value
for property, value of (BlazeComponent::) when property not in ['constructor']
  ExistingClassHierarchyBaseComponent::[property] = value

class ExistingClassHierarchyComponent extends ExistingClassHierarchyBaseComponent
  template: ->
    assert not Tracker.active

    'MainComponent2'

  foobar: ->
    "#{ @componentName() }/ExistingClassHierarchyComponent.foobar/#{ EJSON.stringify @data() }/#{ EJSON.stringify @currentData() }/#{ @currentComponent().componentName() }"

  foobar2: ->
    "#{ @componentName() }/ExistingClassHierarchyComponent.foobar2/#{ EJSON.stringify @data() }/#{ EJSON.stringify @currentData() }/#{ @currentComponent().componentName() }"

  # We on purpose do not override foobar3.

ExistingClassHierarchyComponent.register 'ExistingClassHierarchyComponent', ExistingClassHierarchyComponent

class FirstMixin extends BlazeComponent
  @calls: []

  foobar: ->
    "#{ @mixinParent().componentName() }/FirstMixin.foobar/#{ EJSON.stringify @mixinParent().data() }/#{ EJSON.stringify @mixinParent().currentData() }/#{ @mixinParent().currentComponent().componentName() }"

  foobar2: ->
    "#{ @mixinParent().componentName() }/FirstMixin.foobar2/#{ EJSON.stringify @mixinParent().data() }/#{ EJSON.stringify @mixinParent().currentData() }/#{ @mixinParent().currentComponent().componentName() }"

  foobar3: ->
    "#{ @mixinParent().componentName() }/FirstMixin.foobar3/#{ EJSON.stringify @mixinParent().data() }/#{ EJSON.stringify @mixinParent().currentData() }/#{ @mixinParent().currentComponent().componentName() }"

  isMainComponent: ->
    @mixinParent().constructor is WithMixinsComponent

  onClick: (event) ->
    @constructor.calls.push [@mixinParent().componentName(), 'FirstMixin.onClick', @mixinParent().data(), @mixinParent().currentData(), @mixinParent().currentComponent().componentName()]

  events: -> [
    'click': @onClick
  ]

class SecondMixin extends BlazeComponent
  @calls: []

  template: ->
    assert not Tracker.active

    'MainComponent2'

  foobar: ->
    "#{ @mixinParent().componentName() }/SecondMixin.foobar/#{ EJSON.stringify @mixinParent().data() }/#{ EJSON.stringify @mixinParent().currentData() }/#{ @mixinParent().currentComponent().componentName() }"

  foobar2: ->
    "#{ @mixinParent().componentName() }/SecondMixin.foobar2/#{ EJSON.stringify @mixinParent().data() }/#{ EJSON.stringify @mixinParent().currentData() }/#{ @mixinParent().currentComponent().componentName() }"

  # We on purpose do not provide foobar3.

  onClick: (event) ->
    @constructor.calls.push [@mixinParent().componentName(), 'SecondMixin.onClick', @mixinParent().data(), @mixinParent().currentData(), @mixinParent().currentComponent().componentName()]

  events: ->
    assert not Tracker.active

    [
      'click': @onClick
    ]

  onCreated: ->
    assert not Tracker.active

    # To test if adding a dependency during onCreated will make sure
    # to call onCreated on the added dependency as well.
    @mixinParent().requireMixin DependencyMixin

class DependencyMixin extends BlazeComponent
  @calls: []

  onCreated: ->
    assert not Tracker.active

    @constructor.calls.push true

class WithMixinsComponent extends BlazeComponent
  mixins: ->
    assert not Tracker.active

    [SecondMixin, FirstMixin]

BlazeComponent.register 'WithMixinsComponent', WithMixinsComponent

class AfterCreateValueComponent extends BlazeComponent
  template: ->
    assert not Tracker.active

    'AfterCreateValueComponent'

  onCreated: ->
    assert not Tracker.active

    @foobar = '42'
    @_foobar = '43'

BlazeComponent.register 'AfterCreateValueComponent', AfterCreateValueComponent

class PostMessageButtonComponent extends BlazeComponent
  onCreated: ->
    assert not Tracker.active

    @color = new ReactiveField "Red"

    $(window).on 'message.buttonComponent', (event) =>
      if color = event.originalEvent.data?.color
        @color color

  onDestroyed: ->
    $(window).off '.buttonComponent'

BlazeComponent.register 'PostMessageButtonComponent', PostMessageButtonComponent

class TableWrapperBlockComponent extends BlazeComponent
  template: ->
    assert not Tracker.active

    'TableWrapperBlockComponent'

  currentDataContext: ->
    EJSON.stringify @currentData()

  parentDataContext: ->
    # We would like to make sure data context hierarchy
    # is without intermediate arguments data context.
    EJSON.stringify Template.parentData()

BlazeComponent.register 'TableWrapperBlockComponent', TableWrapperBlockComponent

Template.testBlockComponent.helpers
  parentDataContext: ->
    # We would like to make sure data context hierarchy
    # is without intermediate arguments data context.
    EJSON.stringify Template.parentData()

  customersDataContext: ->
    customers: [
      name: 'Foo'
      email: 'foo@example.com'
    ]

reactiveChild1 = new ReactiveField false
reactiveChild2 = new ReactiveField false

class ChildComponent extends BlazeComponent
  template: ->
    assert not Tracker.active

    'ChildComponent'

  constructor: (@childName) ->
    assert not Tracker.active

  onCreated: ->
    assert not Tracker.active

    @domChanged = new ReactiveField 0

  insertDOMElement: (parent, node, before) ->
    assert not Tracker.active

    super

    @domChanged Tracker.nonreactive =>
      @domChanged() + 1

  moveDOMElement: (parent, node, before) ->
    assert not Tracker.active

    super

    @domChanged Tracker.nonreactive =>
      @domChanged() + 1

  removeDOMElement: (parent, node) ->
    assert not Tracker.active

    super

    @domChanged Tracker.nonreactive =>
      @domChanged() + 1

BlazeComponent.register 'ChildComponent', ChildComponent

class ParentComponent extends BlazeComponent
  template: ->
    assert not Tracker.active

    'ParentComponent'

  child1: ->
    reactiveChild1()

  child2: ->
    reactiveChild2()

BlazeComponent.register 'ParentComponent', ParentComponent

class CaseComponent extends BlazeComponent
  @register 'CaseComponent'

  constructor: (kwargs) ->
    assert not Tracker.active

    @cases = kwargs.hash

  renderCase: ->
    caseComponent = @cases[@data().case]
    return null unless caseComponent
    BlazeComponent.getComponent(caseComponent).renderComponent @

class LeftComponent extends BlazeComponent
  @register 'LeftComponent'

  template: ->
    assert not Tracker.active

    'LeftComponent'

class MiddleComponent extends BlazeComponent
  @register 'MiddleComponent'

  template: ->
    assert not Tracker.active

    'MiddleComponent'

class RightComponent extends BlazeComponent
  @register 'RightComponent'

  template: ->
    assert not Tracker.active

    'RightComponent'

class MyComponent extends BlazeComponent
  @register 'MyComponent'

  mixins: ->
    assert not Tracker.active

    [FirstMixin2, new SecondMixin2 'foobar']

  alternativeName: ->
    @callFirstWith null, 'templateHelper'

  values: ->
    'a' + (@callFirstWith(@, 'values') or '')

class FirstMixinBase extends BlazeComponent
  @calls: []

  templateHelper: ->
    "42"

  extendedHelper: ->
    1

  onClick: ->
    throw new Error() if @values() isnt @valuesPredicton
    @constructor.calls.push true

class FirstMixin2 extends FirstMixinBase
  extendedHelper: ->
    super + 2

  values: ->
    'b' + (@mixinParent().callFirstWith(@, 'values') or '')

  dataContext: ->
    EJSON.stringify @mixinParent().data()

  events: ->
    assert not Tracker.active

    super.concat
      'click': @onClick

  onCreated: ->
    assert not Tracker.active

    @valuesPredicton = 'bc'

class SecondMixin2
  constructor: (@name) ->
    assert not Tracker.active

  mixinParent: (mixinParent) ->
    @_mixinParent = mixinParent if mixinParent
    @_mixinParent

  values: ->
    'c' + (@mixinParent().callFirstWith(@, 'values') or '')

# Example from the README.
class ExampleComponent extends BlazeComponent
  # Register a component so that it can be included in templates. It also
  # gives the component the name. The convention is to use the class name.
  @register 'ExampleComponent'

  # Life-cycle hook to initialize component's state.
  onCreated: ->
    assert not Tracker.active

    @counter = new ReactiveField 0

  # Mapping between events and their handlers.
  events: ->
    assert not Tracker.active

    [
      # You could inline the handler, but the best is to make
      # it a method so that it can be extended later on.
      'click .increment': @onClick
    ]

  onClick: (event) ->
    @counter @counter() + 1

  # Any component's method is available as a template helper in the template.
  customHelper: ->
    if @counter() > 10
      "Too many times"
    else if @counter() is 10
      "Just enough"
    else
      "Click more"

class OuterComponent extends BlazeComponent
  @register 'OuterComponent'

  @calls: []

  template: ->
    assert not Tracker.active

    'OuterComponent'

  onCreated: ->
    assert not Tracker.active

    OuterComponent.calls.push 'OuterComponent onCreated'

  onRendered: ->
    assert not Tracker.active

    OuterComponent.calls.push 'OuterComponent onRendered'

  onDestroyed: ->
    assert not Tracker.active

    OuterComponent.calls.push 'OuterComponent onDestroyed'

class InnerComponent extends BlazeComponent
  @register 'InnerComponent'

  template: ->
    assert not Tracker.active

    'InnerComponent'

  onCreated: ->
    assert not Tracker.active

    OuterComponent.calls.push 'InnerComponent onCreated'

  onRendered: ->
    assert not Tracker.active

    OuterComponent.calls.push 'InnerComponent onRendered'

  onDestroyed: ->
    assert not Tracker.active

    OuterComponent.calls.push 'InnerComponent onDestroyed'

class TemplateDynamicTestComponent extends MainComponent
  @register 'TemplateDynamicTestComponent'

  @calls: []

  template: ->
    assert not Tracker.active

    'TemplateDynamicTestComponent'

  isMainComponent: ->
    @constructor is TemplateDynamicTestComponent

class ExtraTableWrapperBlockComponent extends BlazeComponent
  @register 'ExtraTableWrapperBlockComponent'

class TestBlockComponent extends BlazeComponent
  @register 'TestBlockComponent'

  nameFromComponent: ->
    "Works"

  renderRow: ->
    BlazeComponent.getComponent('RowComponent').renderComponent @currentComponent()

class RowComponent extends BlazeComponent
  @register 'RowComponent'

class FootComponent extends BlazeComponent
  @register 'FootComponent'

class CaptionComponent extends BlazeComponent
  @register 'CaptionComponent'

class RenderRowComponent extends BlazeComponent
  @register 'RenderRowComponent'

  parentComponentRenderRow: ->
    @parentComponent().renderRow()

class TestingComponentDebug extends BlazeComponentDebug
  @structure: {}

  stack = []

  @lastElement: (structure) ->
    return structure if 'children' not of structure

    stack[stack.length - 1] = structure.children
    @lastElement structure.children[structure.children.length - 1]

  @startComponent: (component) ->
    stack.push null
    element = @lastElement @structure

    element.component = component.componentName()
    element.data = component.data()
    element.children = [{}]

  @endComponent: (component) ->
    # Only the top-level stack element stays null and is not set to a children array.
    stack[stack.length - 1].push {} if stack.length > 1
    stack.pop()

  @startMarkedComponent: (component) ->
    @startComponent component

  @endMarkedComponent: (component) ->
    @endComponent component

class BasicTestCase extends ClassyTestCase
  @testName: 'blaze-components - basic'

  FOO_COMPONENT_CONTENT = ->
    """
      <p>Other component: FooComponent</p>
      <button>Foo2</button>
      <p></p>
      <button>Foo3</button>
      <p></p>
      <p></p>
    """

  COMPONENT_CONTENT = (componentName, helperComponentName, mainComponent) ->
    helperComponentName ?= componentName
    mainComponent ?= 'MainComponent'

    """
      <p>Main component: #{ componentName }</p>
      <button>Foo1</button>
      <p>#{ componentName }/#{ helperComponentName }.foobar/{"top":"42"}/{"top":"42"}/#{ componentName }</p>
      <button>Foo2</button>
      <p>#{ componentName }/#{ helperComponentName }.foobar2/{"top":"42"}/{"a":"1","b":"2"}/#{ componentName }</p>
      <p>#{ componentName }/#{ mainComponent }.foobar3/{"top":"42"}/{"top":"42"}/#{ componentName }</p>
      <p>Subtemplate</p>
      <button>Foo1</button>
      <p>#{ componentName }/#{ helperComponentName }.foobar/{"top":"42"}/{"top":"42"}/#{ componentName }</p>
      <button>Foo2</button>
      <p>#{ componentName }/#{ helperComponentName }.foobar2/{"top":"42"}/{"a":"3","b":"4"}/#{ componentName }</p>
      <p>#{ componentName }/#{ mainComponent }.foobar3/{"top":"42"}/{"top":"42"}/#{ componentName }</p>
      #{ FOO_COMPONENT_CONTENT() }
    """

  testComponents: =>
    componentTemplate = BlazeComponent.getComponent('MainComponent').renderComponent()

    @assertTrue componentTemplate

    output = Blaze.toHTMLWithData componentTemplate,
      top: '42'

    @assertEqual trim(output), trim """
      #{ COMPONENT_CONTENT 'MainComponent' }
      <hr>
      #{ COMPONENT_CONTENT 'SubComponent' }
    """

    componentTemplate = new (BlazeComponent.getComponent('MainComponent'))().renderComponent()

    @assertTrue componentTemplate

    output = Blaze.toHTMLWithData componentTemplate,
      top: '42'

    @assertEqual trim(output), trim """
      #{ COMPONENT_CONTENT 'MainComponent' }
      <hr>
      #{ COMPONENT_CONTENT 'SubComponent' }
    """

    componentTemplate = BlazeComponent.getComponent('FooComponent').renderComponent()

    @assertTrue componentTemplate

    output = Blaze.toHTMLWithData componentTemplate,
      top: '42'

    @assertEqual trim(output), trim FOO_COMPONENT_CONTENT()

    componentTemplate = new (BlazeComponent.getComponent('FooComponent'))().renderComponent()

    @assertTrue componentTemplate

    output = Blaze.toHTMLWithData componentTemplate,
      top: '42'

    @assertEqual trim(output), trim FOO_COMPONENT_CONTENT()

    componentTemplate = BlazeComponent.getComponent('SubComponent').renderComponent()

    @assertTrue componentTemplate

    output = Blaze.toHTMLWithData componentTemplate,
      top: '42'

    @assertEqual trim(output), trim COMPONENT_CONTENT 'SubComponent'

    componentTemplate = new (BlazeComponent.getComponent('SubComponent'))().renderComponent()

    @assertTrue componentTemplate

    output = Blaze.toHTMLWithData componentTemplate,
      top: '42'

    @assertEqual trim(output), trim COMPONENT_CONTENT 'SubComponent'

  testGetComponent: =>
    @assertEqual BlazeComponent.getComponent('MainComponent'), MainComponent
    @assertEqual BlazeComponent.getComponent('FooComponent'), FooComponent
    @assertEqual BlazeComponent.getComponent('SubComponent'), SubComponent
    @assertEqual BlazeComponent.getComponent('unknown'), null

  testComponentName: =>
    @assertEqual MainComponent.componentName(), 'MainComponent'
    @assertEqual FooComponent.componentName(), 'FooComponent'
    @assertEqual SubComponent.componentName(), 'SubComponent'
    @assertEqual BlazeComponent.componentName(), null

  testSelfRegister: =>
    @assertTrue BlazeComponent.getComponent 'SelfRegisterComponent'

  testUnregisteredComponent: =>
    componentTemplate = UnregisteredComponent.renderComponent()

    @assertTrue componentTemplate

    output = Blaze.toHTMLWithData componentTemplate,
      top: '42'

    @assertEqual trim(output), trim COMPONENT_CONTENT 'UnregisteredComponent'

    componentTemplate = new UnregisteredComponent().renderComponent()

    @assertTrue componentTemplate

    output = Blaze.toHTMLWithData componentTemplate,
      top: '42'

    @assertEqual trim(output), trim COMPONENT_CONTENT 'UnregisteredComponent'

    componentTemplate = SelfNameUnregisteredComponent.renderComponent()

    @assertTrue componentTemplate

    output = Blaze.toHTMLWithData componentTemplate,
      top: '42'

    # We have not extended any helper on purpose, so they should still use "UnregisteredComponent".
    @assertEqual trim(output), trim COMPONENT_CONTENT 'SelfNameUnregisteredComponent', 'UnregisteredComponent'

    componentTemplate = new SelfNameUnregisteredComponent().renderComponent()

    @assertTrue componentTemplate

    output = Blaze.toHTMLWithData componentTemplate,
      top: '42'

    # We have not extended any helper on purpose, so they should still use "UnregisteredComponent".
    @assertEqual trim(output), trim COMPONENT_CONTENT 'SelfNameUnregisteredComponent', 'UnregisteredComponent'

  testErrors: =>
    @assertThrows =>
      BlazeComponent.register()
    ,
      /Component name is required for registration/

    @assertThrows =>
      BlazeComponent.register 'MainComponent', null
    ,
      /Component 'MainComponent' already registered/

    @assertThrows =>
      BlazeComponent.register 'OtherMainComponent', MainComponent
    ,
      /Component 'OtherMainComponent' already registered under the name 'MainComponent'/

    class WithoutTemplateComponent extends BlazeComponent

    @assertThrows =>
      Blaze.toHTML WithoutTemplateComponent.renderComponent()
    ,
      /Template for the component 'unnamed' not provided/

    @assertThrows =>
      Blaze.toHTML new WithoutTemplateComponent().renderComponent()
    ,
      /Template for the component 'unnamed' not provided/

    class WithUnknownTemplateComponent extends BlazeComponent
      @componentName 'WithoutTemplateComponent'

      template: ->
        'TemplateWhichDoesNotExist'

    @assertThrows =>
      Blaze.toHTML WithUnknownTemplateComponent.renderComponent()
    ,
      /Template 'TemplateWhichDoesNotExist' cannot be found/

    @assertThrows =>
      Blaze.toHTML new WithUnknownTemplateComponent().renderComponent()
    ,
      /Template 'TemplateWhichDoesNotExist' cannot be found/

  testEvents: [
    ->
      MainComponent.calls = []
      SubComponent.calls = []

      @renderedComponent = Blaze.render Template.eventsTestTemplate, $('body').get(0)

      Tracker.afterFlush @expect()
  ,
    ->
      $('.eventsTestTemplate button').each (i, button) =>
        $(button).click()

      @assertEqual MainComponent.calls, [
        ['MainComponent', 'MainComponent.onClick', {top: '42'}, {top: '42'}, 'MainComponent']
        ['MainComponent', 'MainComponent.onClick', {top: '42'}, {a: '1', b: '2'}, 'MainComponent']
        ['MainComponent', 'MainComponent.onClick', {top: '42'}, {top: '42'}, 'MainComponent']
        ['MainComponent', 'MainComponent.onClick', {top: '42'}, {a: '3', b: '4'}, 'MainComponent']
        ['MainComponent', 'MainComponent.onClick', {top: '42'}, {top: '42'}, 'FooComponent']
        ['MainComponent', 'MainComponent.onClick', {top: '42'}, {a: '5', b: '6'}, 'FooComponent']
        ['MainComponent', 'MainComponent.onClick', {top: '42'}, {top: '42'}, 'SubComponent']
        ['MainComponent', 'MainComponent.onClick', {top: '42'}, {a: '1', b: '2'}, 'SubComponent']
        ['MainComponent', 'MainComponent.onClick', {top: '42'}, {top: '42'}, 'SubComponent']
        ['MainComponent', 'MainComponent.onClick', {top: '42'}, {a: '3', b: '4'}, 'SubComponent']
        ['MainComponent', 'MainComponent.onClick', {top: '42'}, {top: '42'}, 'FooComponent']
        ['MainComponent', 'MainComponent.onClick', {top: '42'}, {a: '5', b: '6'}, 'FooComponent']
      ]

      @assertEqual SubComponent.calls, [
        ['SubComponent', 'SubComponent.onClick', {top: '42'}, {top: '42'}, 'SubComponent']
        ['SubComponent', 'SubComponent.onClick', {top: '42'}, {a: '1', b: '2'}, 'SubComponent']
        ['SubComponent', 'SubComponent.onClick', {top: '42'}, {top: '42'}, 'SubComponent']
        ['SubComponent', 'SubComponent.onClick', {top: '42'}, {a: '3', b: '4'}, 'SubComponent']
        ['SubComponent', 'SubComponent.onClick', {top: '42'}, {top: '42'}, 'FooComponent']
        ['SubComponent', 'SubComponent.onClick', {top: '42'}, {a: '5', b: '6'}, 'FooComponent']
      ]

      Blaze.remove @renderedComponent
  ]

  testAnimation: [
    ->
      AnimatedListComponent.calls = []

      @renderedComponent = Blaze.render Template.animationTestTemplate, $('body').get(0)

      Meteor.setTimeout @expect(), 2500 # ms
  ,
    ->
      Blaze.remove @renderedComponent
      calls = AnimatedListComponent.calls
      AnimatedListComponent.calls = []

      expectedCalls = [
        ['insertDOMElement', 'AnimatedListComponent', '<div class="animationTestTemplate"></div>', '<ul><li>1</li><li>2</li><li>3</li><li>4</li><li>5</li></ul>', '']
        ['removeDOMElement', 'AnimatedListComponent', '<ul><li>1</li><li>2</li><li>3</li><li>4</li><li>5</li></ul>', '<li>1</li>']
        ['moveDOMElement', 'AnimatedListComponent', '<ul><li>2</li><li>3</li><li>4</li><li>5</li></ul>', '<li>5</li>', '']
        ['insertDOMElement', 'AnimatedListComponent', '<ul><li>5</li><li>2</li><li>3</li><li>4</li></ul>', '<li>6</li>', '']
        ['removeDOMElement', 'AnimatedListComponent', '<ul><li>5</li><li>2</li><li>3</li><li>4</li><li>6</li></ul>', '<li>2</li>']
        ['moveDOMElement', 'AnimatedListComponent', '<ul><li>5</li><li>3</li><li>4</li><li>6</li></ul>', '<li>6</li>', '']
        ['insertDOMElement', 'AnimatedListComponent', '<ul><li>6</li><li>5</li><li>3</li><li>4</li></ul>', '<li>7</li>', '']
      ]

      # There could be some more calls made, we ignore them and just take the first 8.
      @assertEqual calls[0...8], expectedCalls

      Meteor.setTimeout @expect(), 2000 # ms
  ,
    ->
      # After we removed the component no more calls should be made.

      @assertEqual AnimatedListComponent.calls, []
  ]

  assertArgumentsConstructorStateChanges: (stateChanges, wrappedInComponent=true) ->
    firstSteps = (dataContext) =>
      change = stateChanges.shift()
      componentId = change.componentId
      @assertTrue change.view
      @assertTrue change.templateInstance

      change = stateChanges.shift()
      @assertEqual change.componentId, componentId
      @assertFalse change.isCreated

      change = stateChanges.shift()
      @assertEqual change.componentId, componentId
      @assertFalse change.isRendered

      change = stateChanges.shift()
      @assertEqual change.componentId, componentId
      @assertFalse change.isDestroyed

      change = stateChanges.shift()
      @assertEqual change.componentId, componentId
      @assertIsUndefined change.data

      change = stateChanges.shift()
      @assertEqual change.componentId, componentId
      @assertEqual change.currentData, dataContext

      change = stateChanges.shift()
      @assertEqual change.componentId, componentId
      @assertInstanceOf change.component, ArgumentsComponent

      change = stateChanges.shift()
      @assertEqual change.componentId, componentId
      if wrappedInComponent
        @assertInstanceOf change.currentComponent, ArgumentsTestComponent
      else
        @assertIsNull change.currentComponent

      change = stateChanges.shift()
      @assertEqual change.componentId, componentId
      @assertIsUndefined change.firstNode

      change = stateChanges.shift()
      @assertEqual change.componentId, componentId
      @assertIsUndefined change.lastNode

      change = stateChanges.shift()
      @assertEqual change.componentId, componentId
      @assertIsUndefined change.subscriptionsReady

      change = stateChanges.shift()
      @assertEqual change.componentId, componentId
      @assertIsUndefined change.find

      change = stateChanges.shift()
      @assertEqual change.componentId, componentId
      @assertIsUndefined change.findAll

      change = stateChanges.shift()
      @assertEqual change.componentId, componentId
      @assertIsUndefined change.$

      componentId

    firstComponentId = firstSteps a: "1", b: "2"
    secondComponentId = firstSteps a:"3a", b: "4a"
    thirdComponentId = firstSteps a: "5", b: "6"
    forthComponentId = firstSteps {}

    secondSteps = (componendId, dataContext) =>
      change = stateChanges.shift()
      @assertEqual change.componentId, componendId
      @assertEqual change.data, dataContext

      change = stateChanges.shift()
      @assertEqual change.componentId, componendId
      @assertTrue change.subscriptionsReady

      change = stateChanges.shift()
      @assertEqual change.componentId, componendId
      @assertTrue change.isCreated

    secondSteps firstComponentId, a: "1", b: "2"
    secondSteps secondComponentId, a:"3a", b: "4a"
    secondSteps thirdComponentId, a: "5", b: "6"
    secondSteps forthComponentId, {}

    thirdSteps = (componentId) =>
      change = stateChanges.shift()
      @assertEqual change.componentId, componentId
      @assertTrue change.isRendered

      change = stateChanges.shift()
      @assertEqual change.componentId, componentId
      @assertEqual change.firstNode?.nodeName, "P"

      change = stateChanges.shift()
      @assertEqual change.componentId, componentId
      @assertEqual change.lastNode?.nodeName, "P"

      change = stateChanges.shift()
      @assertEqual change.componentId, componentId
      @assertEqual change.find?.nodeName, "P"

      change = stateChanges.shift()
      @assertEqual change.componentId, componentId
      @assertEqual (c?.nodeName for c in change.findAll), ["P", "P", "P", "P"]

      change = stateChanges.shift()
      @assertEqual change.componentId, componentId
      @assertEqual (c?.nodeName for c in change.$), ["P", "P", "P", "P"]

    thirdSteps firstComponentId
    thirdSteps secondComponentId
    thirdSteps thirdComponentId
    thirdSteps forthComponentId

    # TODO: This change is probably unnecessary? Could we prevent it?
    change = stateChanges.shift()
    @assertEqual change.componentId, forthComponentId
    if change.data
      # TODO: In Chrome data is set. Why?
      @assertEqual change.data, a: "10", b: "11"
    else
      # TODO: In Firefox data is undefined. Why?
      @assertIsUndefined change.data

    # TODO: Not sure why this change happens?
    change = stateChanges.shift()
    @assertEqual change.componentId, forthComponentId
    @assertIsUndefined change.currentData

    fifthComponentId = firstSteps a: "10", b: "11"

    forthSteps = (componendId) =>
      change = stateChanges.shift()
      @assertEqual change.componentId, componendId
      @assertFalse change.isCreated

      change = stateChanges.shift()
      @assertEqual change.componentId, componendId
      @assertFalse change.isRendered

      change = stateChanges.shift()
      @assertEqual change.componentId, componendId
      @assertIsUndefined change.firstNode

      change = stateChanges.shift()
      @assertEqual change.componentId, componendId
      @assertIsUndefined change.lastNode

      change = stateChanges.shift()
      @assertEqual change.componentId, componendId
      @assertIsUndefined change.find

      change = stateChanges.shift()
      @assertEqual change.componentId, componendId
      @assertIsUndefined change.findAll

      change = stateChanges.shift()
      @assertEqual change.componentId, componendId
      @assertIsUndefined change.$

      change = stateChanges.shift()
      @assertEqual change.componentId, componendId
      @assertTrue change.isDestroyed

      # TODO: Not sure why this change happens?
      change = stateChanges.shift()
      @assertEqual change.componentId, componendId
      @assertIsUndefined change.data

      change = stateChanges.shift()
      @assertEqual change.componentId, componendId
      @assertIsUndefined change.subscriptionsReady

    forthSteps forthComponentId

    change = stateChanges.shift()
    @assertEqual change.componentId, fifthComponentId
    @assertEqual change.data, a: "10", b: "11"

    change = stateChanges.shift()
    @assertEqual change.componentId, fifthComponentId
    @assertTrue change.subscriptionsReady

    change = stateChanges.shift()
    @assertEqual change.componentId, fifthComponentId
    @assertTrue change.isCreated

    forthSteps firstComponentId
    forthSteps secondComponentId
    forthSteps thirdComponentId

    change = stateChanges.shift()
    @assertEqual change.componentId, fifthComponentId
    @assertFalse change.isCreated

    # TODO: Why is isRendered not set to false and all related other fields which require it (firstNode, lastNode, find, findAll, $)?

    change = stateChanges.shift()
    @assertEqual change.componentId, fifthComponentId
    @assertTrue change.isDestroyed

    # TODO: Not sure why this change happens?
    change = stateChanges.shift()
    @assertEqual change.componentId, fifthComponentId
    @assertIsUndefined change.data

    change = stateChanges.shift()
    @assertEqual change.componentId, fifthComponentId
    @assertIsUndefined change.subscriptionsReady

    @assertEqual stateChanges, []

  assertArgumentsOnCreatedStateChanges: (stateChanges) ->
    firstSteps = (dataContext) =>
      change = stateChanges.shift()
      componentId = change.componentId
      @assertTrue change.view
      @assertTrue change.templateInstance

      change = stateChanges.shift()
      @assertEqual change.componentId, componentId
      @assertFalse change.isCreated

      change = stateChanges.shift()
      @assertEqual change.componentId, componentId
      @assertFalse change.isRendered

      change = stateChanges.shift()
      @assertEqual change.componentId, componentId
      @assertFalse change.isDestroyed

      change = stateChanges.shift()
      @assertEqual change.componentId, componentId
      @assertEqual change.data, dataContext

      change = stateChanges.shift()
      @assertEqual change.componentId, componentId
      @assertEqual change.currentData, dataContext

      change = stateChanges.shift()
      @assertEqual change.componentId, componentId
      @assertInstanceOf change.component, ArgumentsComponent

      change = stateChanges.shift()
      @assertEqual change.componentId, componentId
      @assertInstanceOf change.currentComponent, ArgumentsComponent

      change = stateChanges.shift()
      @assertEqual change.componentId, componentId
      @assertIsUndefined change.firstNode

      change = stateChanges.shift()
      @assertEqual change.componentId, componentId
      @assertIsUndefined change.lastNode

      change = stateChanges.shift()
      @assertEqual change.componentId, componentId
      @assertTrue change.subscriptionsReady

      change = stateChanges.shift()
      @assertEqual change.componentId, componentId
      @assertIsUndefined change.find

      change = stateChanges.shift()
      @assertEqual change.componentId, componentId
      @assertIsUndefined change.findAll

      change = stateChanges.shift()
      @assertEqual change.componentId, componentId
      @assertIsUndefined change.$

      componentId

    firstComponentId = firstSteps a: "1", b: "2"
    secondComponentId = firstSteps a:"3a", b: "4a"
    thirdComponentId = firstSteps a: "5", b: "6"
    forthComponentId = firstSteps {}

    change = stateChanges.shift()
    @assertEqual change.componentId, firstComponentId
    @assertTrue change.isCreated

    change = stateChanges.shift()
    @assertEqual change.componentId, secondComponentId
    @assertTrue change.isCreated

    change = stateChanges.shift()
    @assertEqual change.componentId, thirdComponentId
    @assertTrue change.isCreated

    change = stateChanges.shift()
    @assertEqual change.componentId, forthComponentId
    @assertTrue change.isCreated

    thirdSteps = (componentId) =>
      change = stateChanges.shift()
      @assertEqual change.componentId, componentId
      @assertTrue change.isRendered

      change = stateChanges.shift()
      @assertEqual change.componentId, componentId
      @assertEqual change.firstNode?.nodeName, "P"

      change = stateChanges.shift()
      @assertEqual change.componentId, componentId
      @assertEqual change.lastNode?.nodeName, "P"

      change = stateChanges.shift()
      @assertEqual change.componentId, componentId
      @assertEqual change.find?.nodeName, "P"

      change = stateChanges.shift()
      @assertEqual change.componentId, componentId
      @assertEqual (c?.nodeName for c in change.findAll), ["P", "P", "P", "P"]

      change = stateChanges.shift()
      @assertEqual change.componentId, componentId
      @assertEqual (c?.nodeName for c in change.$), ["P", "P", "P", "P"]

    thirdSteps firstComponentId
    thirdSteps secondComponentId
    thirdSteps thirdComponentId
    thirdSteps forthComponentId

    # TODO: This change is probably unnecessary? Could we prevent it?
    change = stateChanges.shift()
    @assertEqual change.componentId, forthComponentId
    @assertEqual change.data, a: "10", b: "11"

    # TODO: Not sure why this change happens?
    change = stateChanges.shift()
    @assertEqual change.componentId, forthComponentId
    @assertIsUndefined change.currentData

    fifthComponentId = firstSteps a: "10", b: "11"

    forthSteps = (componendId) =>
      change = stateChanges.shift()
      @assertEqual change.componentId, componendId
      @assertFalse change.isCreated

      change = stateChanges.shift()
      @assertEqual change.componentId, componendId
      @assertFalse change.isRendered

      change = stateChanges.shift()
      @assertEqual change.componentId, componendId
      @assertIsUndefined change.firstNode

      change = stateChanges.shift()
      @assertEqual change.componentId, componendId
      @assertIsUndefined change.lastNode

      change = stateChanges.shift()
      @assertEqual change.componentId, componendId
      @assertIsUndefined change.find

      change = stateChanges.shift()
      @assertEqual change.componentId, componendId
      @assertIsUndefined change.findAll

      change = stateChanges.shift()
      @assertEqual change.componentId, componendId
      @assertIsUndefined change.$

      change = stateChanges.shift()
      @assertEqual change.componentId, componendId
      @assertTrue change.isDestroyed

      # TODO: Not sure why this change happens?
      change = stateChanges.shift()
      @assertEqual change.componentId, componendId
      @assertIsUndefined change.data

      change = stateChanges.shift()
      @assertEqual change.componentId, componendId
      @assertIsUndefined change.subscriptionsReady

    forthSteps forthComponentId

    change = stateChanges.shift()
    @assertEqual change.componentId, fifthComponentId
    @assertTrue change.isCreated

    forthSteps firstComponentId
    forthSteps secondComponentId
    forthSteps thirdComponentId

    change = stateChanges.shift()
    @assertEqual change.componentId, fifthComponentId
    @assertFalse change.isCreated

    # TODO: Why is isRendered not set to false and all related other fields which require it (firstNode, lastNode, find, findAll, $)?

    change = stateChanges.shift()
    @assertEqual change.componentId, fifthComponentId
    @assertTrue change.isDestroyed

    # TODO: Not sure why this change happens?
    change = stateChanges.shift()
    @assertEqual change.componentId, fifthComponentId
    @assertIsUndefined change.data

    change = stateChanges.shift()
    @assertEqual change.componentId, fifthComponentId
    @assertIsUndefined change.subscriptionsReady

    @assertEqual stateChanges, []

  testArguments: [
    ->
      ArgumentsComponent.calls = []
      ArgumentsComponent.constructorStateChanges = []
      ArgumentsComponent.onCreatedStateChanges = []

      reactiveContext {}
      reactiveArguments {}

      @renderedComponent = Blaze.renderWithData Template.argumentsTestTemplate, {top: '42'}, $('body').get(0)

      Tracker.afterFlush @expect()
  ,
    ->
      @assertEqual trim($('.argumentsTestTemplate').html()), trim """
        <p>Component data context: {"a":"1","b":"2"}</p>
        <p>Current data context: {"a":"1","b":"2"}</p>
        <p>Parent data context: {"top":"42"}</p>
        <p>Arguments: []</p>
        <p>Component data context: {"a":"3a","b":"4a"}</p>
        <p>Current data context: {"a":"3a","b":"4a"}</p>
        <p>Parent data context: {"a":"3","b":"4"}</p>
        <p>Arguments: []</p>
        <p>Component data context: {"a":"5","b":"6"}</p>
        <p>Current data context: {"a":"5","b":"6"}</p>
        <p>Parent data context: {"top":"42"}</p>
        <p>Arguments: ["7",{"hash":{"a":"8","b":"9"}}]</p>
        <p>Component data context: {}</p>
        <p>Current data context: {}</p>
        <p>Parent data context: {"top":"42"}</p>
        <p>Arguments: [{},{"hash":{}}]</p>
      """

      reactiveContext {a: '10', b: '11'}

      Tracker.afterFlush @expect()
  ,
    ->
      @assertEqual trim($('.argumentsTestTemplate').html()), trim """
        <p>Component data context: {"a":"1","b":"2"}</p>
        <p>Current data context: {"a":"1","b":"2"}</p>
        <p>Parent data context: {"top":"42"}</p>
        <p>Arguments: []</p>
        <p>Component data context: {"a":"3a","b":"4a"}</p>
        <p>Current data context: {"a":"3a","b":"4a"}</p>
        <p>Parent data context: {"a":"3","b":"4"}</p>
        <p>Arguments: []</p>
        <p>Component data context: {"a":"5","b":"6"}</p>
        <p>Current data context: {"a":"5","b":"6"}</p>
        <p>Parent data context: {"top":"42"}</p>
        <p>Arguments: ["7",{"hash":{"a":"8","b":"9"}}]</p>
        <p>Component data context: {"a":"10","b":"11"}</p>
        <p>Current data context: {"a":"10","b":"11"}</p>
        <p>Parent data context: {"top":"42"}</p>
        <p>Arguments: [{},{"hash":{}}]</p>
      """

      reactiveArguments {a: '12', b: '13'}

      Tracker.afterFlush @expect()
  ,
    ->
      @assertEqual trim($('.argumentsTestTemplate').html()), trim """
        <p>Component data context: {"a":"1","b":"2"}</p>
        <p>Current data context: {"a":"1","b":"2"}</p>
        <p>Parent data context: {"top":"42"}</p>
        <p>Arguments: []</p>
        <p>Component data context: {"a":"3a","b":"4a"}</p>
        <p>Current data context: {"a":"3a","b":"4a"}</p>
        <p>Parent data context: {"a":"3","b":"4"}</p>
        <p>Arguments: []</p>
        <p>Component data context: {"a":"5","b":"6"}</p>
        <p>Current data context: {"a":"5","b":"6"}</p>
        <p>Parent data context: {"top":"42"}</p>
        <p>Arguments: ["7",{"hash":{"a":"8","b":"9"}}]</p>
        <p>Component data context: {"a":"10","b":"11"}</p>
        <p>Current data context: {"a":"10","b":"11"}</p>
        <p>Parent data context: {"top":"42"}</p>
        <p>Arguments: [{"a":"12","b":"13"},{"hash":{}}]</p>
      """

      Blaze.remove @renderedComponent

      # It is important that this is 5, not 6, because we have 3 components with static arguments, and we change
      # arguments twice. Component should not be created once more just because we changed its data context.
      # Only when we change its arguments.
      @assertEqual ArgumentsComponent.calls.length, 5

      @assertEqual ArgumentsComponent.calls, [
        undefined
        undefined
        '7'
        {}
        {a: '12', b: '13'}
      ]

      Tracker.afterFlush @expect()
  ,
    ->
      @assertArgumentsConstructorStateChanges ArgumentsComponent.constructorStateChanges
      @assertArgumentsOnCreatedStateChanges ArgumentsComponent.onCreatedStateChanges
  ]

  testExistingClassHierarchy: =>
    # We want to allow one to reuse existing class hierarchy they might already have and only
    # add the Meteor components "nature" to it. This is simply done by extending the base class
    # and base class prototype with those from a wanted base class and prototype.
    componentTemplate = BlazeComponent.getComponent('ExistingClassHierarchyComponent').renderComponent()

    @assertTrue componentTemplate

    output = Blaze.toHTMLWithData componentTemplate,
      top: '42'

    @assertEqual trim(output), trim COMPONENT_CONTENT 'ExistingClassHierarchyComponent', 'ExistingClassHierarchyComponent', 'ExistingClassHierarchyBase'

  testMixins: =>
    DependencyMixin.calls = []

    componentTemplate = BlazeComponent.getComponent('WithMixinsComponent').renderComponent()

    @assertTrue componentTemplate

    output = Blaze.toHTMLWithData componentTemplate,
      top: '42'

    @assertEqual trim(output), trim """
      #{ COMPONENT_CONTENT 'WithMixinsComponent', 'SecondMixin', 'FirstMixin' }
      <hr>
      #{ COMPONENT_CONTENT 'SubComponent' }
    """

    @assertEqual DependencyMixin.calls, [true]

    componentTemplate = new (BlazeComponent.getComponent('WithMixinsComponent'))().renderComponent()

    @assertTrue componentTemplate

    output = Blaze.toHTMLWithData componentTemplate,
      top: '42'

    @assertEqual trim(output), trim """
      #{ COMPONENT_CONTENT 'WithMixinsComponent', 'SecondMixin', 'FirstMixin' }
      <hr>
      #{ COMPONENT_CONTENT 'SubComponent' }
    """

  testMixinEvents: =>
    FirstMixin.calls = []
    SecondMixin.calls = []
    SubComponent.calls = []

    renderedComponent = Blaze.render Template.mixinEventsTestTemplate, $('body').get(0)

    $('.mixinEventsTestTemplate button').each (i, button) =>
      $(button).click()

    @assertEqual FirstMixin.calls, [
      ['WithMixinsComponent', 'FirstMixin.onClick', {top: '42'}, {top: '42'}, 'WithMixinsComponent']
      ['WithMixinsComponent', 'FirstMixin.onClick', {top: '42'}, {a: '1', b: '2'}, 'WithMixinsComponent']
      ['WithMixinsComponent', 'FirstMixin.onClick', {top: '42'}, {top: '42'}, 'WithMixinsComponent']
      ['WithMixinsComponent', 'FirstMixin.onClick', {top: '42'}, {a: '3', b: '4'}, 'WithMixinsComponent']
      ['WithMixinsComponent', 'FirstMixin.onClick', {top: '42'}, {top: '42'}, 'FooComponent']
      ['WithMixinsComponent', 'FirstMixin.onClick', {top: '42'}, {a: '5', b: '6'}, 'FooComponent']
      ['WithMixinsComponent', 'FirstMixin.onClick', {top: '42'}, {top: '42'}, 'SubComponent']
      ['WithMixinsComponent', 'FirstMixin.onClick', {top: '42'}, {a: '1', b: '2'}, 'SubComponent']
      ['WithMixinsComponent', 'FirstMixin.onClick', {top: '42'}, {top: '42'}, 'SubComponent']
      ['WithMixinsComponent', 'FirstMixin.onClick', {top: '42'}, {a: '3', b: '4'}, 'SubComponent']
      ['WithMixinsComponent', 'FirstMixin.onClick', {top: '42'}, {top: '42'}, 'FooComponent']
      ['WithMixinsComponent', 'FirstMixin.onClick', {top: '42'}, {a: '5', b: '6'}, 'FooComponent']
    ]

    # Event handlers are independent from each other among mixins. SecondMixin has its own onClick
    # handler registered, so it should be called as well.
    @assertEqual SecondMixin.calls, [
      ['WithMixinsComponent', 'SecondMixin.onClick', {top: '42'}, {top: '42'}, 'WithMixinsComponent']
      ['WithMixinsComponent', 'SecondMixin.onClick', {top: '42'}, {a: '1', b: '2'}, 'WithMixinsComponent']
      ['WithMixinsComponent', 'SecondMixin.onClick', {top: '42'}, {top: '42'}, 'WithMixinsComponent']
      ['WithMixinsComponent', 'SecondMixin.onClick', {top: '42'}, {a: '3', b: '4'}, 'WithMixinsComponent']
      ['WithMixinsComponent', 'SecondMixin.onClick', {top: '42'}, {top: '42'}, 'FooComponent']
      ['WithMixinsComponent', 'SecondMixin.onClick', {top: '42'}, {a: '5', b: '6'}, 'FooComponent']
      ['WithMixinsComponent', 'SecondMixin.onClick', {top: '42'}, {top: '42'}, 'SubComponent']
      ['WithMixinsComponent', 'SecondMixin.onClick', {top: '42'}, {a: '1', b: '2'}, 'SubComponent']
      ['WithMixinsComponent', 'SecondMixin.onClick', {top: '42'}, {top: '42'}, 'SubComponent']
      ['WithMixinsComponent', 'SecondMixin.onClick', {top: '42'}, {a: '3', b: '4'}, 'SubComponent']
      ['WithMixinsComponent', 'SecondMixin.onClick', {top: '42'}, {top: '42'}, 'FooComponent']
      ['WithMixinsComponent', 'SecondMixin.onClick', {top: '42'}, {a: '5', b: '6'}, 'FooComponent']
    ]

    @assertEqual SubComponent.calls, [
      ['SubComponent', 'SubComponent.onClick', {top: '42'}, {top: '42'}, 'SubComponent']
      ['SubComponent', 'SubComponent.onClick', {top: '42'}, {a: '1', b: '2'}, 'SubComponent']
      ['SubComponent', 'SubComponent.onClick', {top: '42'}, {top: '42'}, 'SubComponent']
      ['SubComponent', 'SubComponent.onClick', {top: '42'}, {a: '3', b: '4'}, 'SubComponent']
      ['SubComponent', 'SubComponent.onClick', {top: '42'}, {top: '42'}, 'FooComponent']
      ['SubComponent', 'SubComponent.onClick', {top: '42'}, {a: '5', b: '6'}, 'FooComponent']
    ]

    Blaze.remove renderedComponent

  testAfterCreateValue: =>
    # We want to test that also properties added in onCreated hook are available in the template.
    componentTemplate = BlazeComponent.getComponent('AfterCreateValueComponent').renderComponent()

    @assertTrue componentTemplate

    output = Blaze.toHTML componentTemplate

    @assertEqual trim(output), trim """
      <p>42</p>
      <p>43</p>
    """

  testPostMessageExample: [
    ->
      @renderedComponent = Blaze.render PostMessageButtonComponent.renderComponent(), $('body').get(0)

      Tracker.afterFlush @expect()
  ,
    ->
      @assertEqual trim($('.postMessageButtonComponent').html()), trim """
        <button>Red</button>
      """

      window.postMessage {color: "Blue"}, '*'

      # Wait a bit for a message and also wait for a flush.
      Meteor.setTimeout @expect(), 50 # ms
      Tracker.afterFlush @expect()
  ,
    ->
      @assertEqual trim($('.postMessageButtonComponent').html()), trim """
        <button>Blue</button>
      """

      Blaze.remove @renderedComponent
  ]

  testBlockComponent: =>
    output = Blaze.toHTMLWithData Template.testBlockComponent,
      top: '42'

    @assertEqual trim(output), trim """
      <table>
        <thead>
          <tr>
            <th>Name</th>
            <th>Email</th>
          </tr>
        </thead>
        <tbody>
          <p>{"top":"42"}</p>
          <p>{"customers":[{"name":"Foo","email":"foo@example.com"}]}</p>
          <p class="inside">{"top":"42"}</p>
          <td>Foo</td>
          <td>foo@example.com</td>
        </tbody>
      </table>
       <table>
        <thead>
          <tr>
            <th>Name</th>
            <th>Email</th>
          </tr>
        </thead>
        <tbody>
          <p>{"customers":[{"name":"Foo","email":"foo@example.com"}]}</p>
          <p>{"a":"3a","b":"4a"}</p>
          <p class="inside">{"top":"42"}</p>
          <td>Foo</td>
          <td>foo@example.com</td>
        </tbody>
      </table>
       <table>
        <thead>
          <tr>
            <th>Name</th>
            <th>Email</th>
          </tr>
        </thead>
        <tbody>
          <p>{"top":"42"}</p>
          <p>{"customers":[{"name":"Foo","email":"foo@example.com"}]}</p>
          <p class="inside">{"top":"42"}</p>
          <td>Foo</td>
          <td>foo@example.com</td>
        </tbody>
      </table>
       <table>
        <thead>
          <tr>
            <th>Name</th>
            <th>Email</th>
          </tr>
        </thead>
        <tbody>
          <p>{"top":"42"}</p>
          <p>{"customers":[{"name":"Foo","email":"foo@example.com"}]}</p>
          <p class="inside">{"top":"42"}</p>
          <td>Foo</td>
          <td>foo@example.com</td>
        </tbody>
      </table>
    """

  testComponentParent: [
    ->
      reactiveChild1 false
      reactiveChild2 false

      @component = new ParentComponent()

      @childrenComponents = []
      @handle = Tracker.autorun (computation) =>
        @childrenComponents.push @component.childrenComponents()

      @childrenComponentsChild1 = []
      @handleChild1 = Tracker.autorun (computation) =>
        @childrenComponentsChild1.push @component.childrenComponentsWith childName: 'child1'

      @childrenComponentsChild1DOM = []
      @handleChild1DOM = Tracker.autorun (computation) =>
        @childrenComponentsChild1DOM.push @component.childrenComponentsWith (child) ->
          # We can search also based on DOM. We use domChanged to be sure check is called
          # every time DOM changes. But it does not seem to be really necessary in this
          # particular test (it passes without it as well). On the other hand domChanged
          # also does not capture all changes. We are searching for an element by CSS class
          # and domChanged is not changed when a class changes on a DOM element.
          #child.domChanged()
          child.$('.child1')?.length

      @renderedComponent = Blaze.render @component.renderComponent(), $('body').get(0)

      Tracker.afterFlush @expect()
  ,
    ->
      @assertEqual @component.childrenComponents(), []

      reactiveChild1 true

      Tracker.afterFlush @expect()
  ,
    ->
      @assertEqual @component.childrenComponents().length, 1

      @child1Component = @component.childrenComponents()[0]

      @assertEqual @child1Component.parentComponent(), @component

      reactiveChild2 true

      Tracker.afterFlush @expect()
  ,
    ->
      @assertEqual @component.childrenComponents().length, 2

      @child2Component = @component.childrenComponents()[1]

      @assertEqual @child2Component.parentComponent(), @component

      reactiveChild1 false

      Tracker.afterFlush @expect()
  ,
    ->
      @assertEqual @component.childrenComponents(), [@child2Component]
      @assertEqual @child1Component.parentComponent(), null

      reactiveChild2 false

      Tracker.afterFlush @expect()
  ,
    ->
      @assertEqual @component.childrenComponents(), []
      @assertEqual @child2Component.parentComponent(), null

      Blaze.remove @renderedComponent

      @handle.stop()
      @handleChild1.stop()
      @handleChild1DOM.stop()

      @assertEqual @childrenComponents, [
        []
        [@child1Component]
        [@child1Component, @child2Component]
        [@child2Component]
        []
      ]

      @assertEqual @childrenComponentsChild1, [
        []
        [@child1Component]
        []
      ]

      @assertEqual @childrenComponentsChild1DOM, [
        []
        [@child1Component]
        []
      ]
  ]

  testCases: [
    ->
      @dataContext = new ReactiveField {case: 'left'}

      @renderedComponent = Blaze.renderWithData Template.useCaseTemplate, (=> @dataContext()), $('body').get(0)

      Tracker.afterFlush @expect()
    ->
      @assertEqual trim($('.useCaseTemplate').html()), trim """
        <p>Left</p>
      """

      @dataContext {case: 'middle'}

      Tracker.afterFlush @expect()
    ->
      @assertEqual trim($('.useCaseTemplate').html()), trim """
        <p>Middle</p>
      """

      @dataContext {case: 'right'}

      Tracker.afterFlush @expect()
    ->
      @assertEqual trim($('.useCaseTemplate').html()), trim """
        <p>Right</p>
      """

      @dataContext {case: 'unknown'}

      Tracker.afterFlush @expect()
    ->
      @assertEqual trim($('.useCaseTemplate').html()), trim """"""

      Blaze.remove @renderedComponent
  ]

  testMixinsExample: [
    ->
      @renderedComponent = Blaze.renderWithData BlazeComponent.getComponent('MyComponent').renderComponent(), {top: '42'}, $('body').get(0)

      Tracker.afterFlush @expect()
  ,
    ->
      @assertEqual trim($('.myComponent').html()), trim """
        <p>alternativeName: 42</p>
        <p>values: abc</p>
        <p>templateHelper: 42</p>
        <p>extendedHelper: 3</p>
        <p>name: foobar</p>
        <p>dataContext: {"top":"42"}</p>
      """

      FirstMixin2.calls = []

      $('.myComponent').click()
      @assertEqual FirstMixin2.calls, [true]

      Blaze.remove @renderedComponent
  ]

  testReadmeExample: [
    ->
      @renderedComponent = Blaze.render BlazeComponent.getComponent('ExampleComponent').renderComponent(), $('body').get(0)

      Tracker.afterFlush @expect()
  ,
    ->
      @assertEqual trim($('.exampleComponent').html()), trim """
        <button class="increment">Click me</button>
        <p>Counter: 0</p>
        <p>Message: Click more</p>
      """

      $('.exampleComponent .increment').click()

      Tracker.afterFlush @expect()
  ,
    ->
      @assertEqual trim($('.exampleComponent').html()), trim """
        <button class="increment">Click me</button>
        <p>Counter: 1</p>
        <p>Message: Click more</p>
      """

      for i in [0..15]
        $('.exampleComponent .increment').click()

      Tracker.afterFlush @expect()
  ,
    ->
      @assertEqual trim($('.exampleComponent').html()), trim """
        <button class="increment">Click me</button>
        <p>Counter: 17</p>
        <p>Message: Too many times</p>
      """

      Blaze.remove @renderedComponent
  ]

  testReadmeExampleJS: [
    ->
      @renderedComponent = Blaze.render BlazeComponent.getComponent('ExampleComponentJS').renderComponent(), $('body').get(0)

      Tracker.afterFlush @expect()
  ,
    ->
      @assertEqual trim($('.exampleComponent').html()), trim """
        <button class="increment">Click me</button>
        <p>Counter: 0</p>
        <p>Message: Click more</p>
      """

      $('.exampleComponent .increment').click()

      Tracker.afterFlush @expect()
  ,
    ->
      @assertEqual trim($('.exampleComponent').html()), trim """
        <button class="increment">Click me</button>
        <p>Counter: 1</p>
        <p>Message: Click more</p>
      """

      for i in [0..15]
        $('.exampleComponent .increment').click()

      Tracker.afterFlush @expect()
  ,
    ->
      @assertEqual trim($('.exampleComponent').html()), trim """
        <button class="increment">Click me</button>
        <p>Counter: 17</p>
        <p>Message: Too many times</p>
      """

      Blaze.remove @renderedComponent
  ]

  testMixinsExampleWithJavaScript: [
    ->
      @renderedComponent = Blaze.renderWithData BlazeComponent.getComponent('OurComponentJS').renderComponent(), {top: '42'}, $('body').get(0)

      Tracker.afterFlush @expect()
  ,
    ->
      @assertEqual trim($('.myComponent').html()), trim """
        <p>alternativeName: 42</p>
        <p>values: &gt;&gt;&gt;abc&lt;&lt;&lt;</p>
        <p>templateHelper: 42</p>
        <p>extendedHelper: 3</p>
        <p>name: foobar</p>
        <p>dataContext: {"top":"42"}</p>
      """

      FirstMixin2.calls = []

      $('.myComponent').click()
      @assertEqual FirstMixin2.calls, [true]

      Blaze.remove @renderedComponent
  ]

  testReadmeExampleES2015: [
    ->
      @renderedComponent = Blaze.render BlazeComponent.getComponent('ExampleComponentES2015').renderComponent(), $('body').get(0)

      Tracker.afterFlush @expect()
  ,
    ->
      @assertEqual trim($('.exampleComponent').html()), trim """
        <button class="increment">Click me</button>
        <p>Counter: 0</p>
        <p>Message: Click more</p>
      """

      $('.exampleComponent .increment').click()

      Tracker.afterFlush @expect()
  ,
    ->
      @assertEqual trim($('.exampleComponent').html()), trim """
        <button class="increment">Click me</button>
        <p>Counter: 1</p>
        <p>Message: Click more</p>
      """

      for i in [0..15]
        $('.exampleComponent .increment').click()

      Tracker.afterFlush @expect()
  ,
    ->
      @assertEqual trim($('.exampleComponent').html()), trim """
        <button class="increment">Click me</button>
        <p>Counter: 17</p>
        <p>Message: Too many times</p>
      """

      Blaze.remove @renderedComponent
  ]

  testMixinsExampleWithES2015: [
    ->
      @renderedComponent = Blaze.renderWithData BlazeComponent.getComponent('OurComponentES2015').renderComponent(), {top: '42'}, $('body').get(0)

      Tracker.afterFlush @expect()
  ,
    ->
      @assertEqual trim($('.myComponent').html()), trim """
        <p>alternativeName: 42</p>
        <p>values: &gt;&gt;&gt;abc&lt;&lt;&lt;</p>
        <p>templateHelper: 42</p>
        <p>extendedHelper: 3</p>
        <p>name: foobar</p>
        <p>dataContext: {"top":"42"}</p>
      """

      FirstMixin2.calls = []

      $('.myComponent').click()
      @assertEqual FirstMixin2.calls, [true]

      Blaze.remove @renderedComponent
  ]

  testOnDestroyedOrder: [
    ->
      OuterComponent.calls = []

      @outerComponent = new (BlazeComponent.getComponent('OuterComponent'))()

      @states = []

      @autorun =>
        @states.push ['outer', @outerComponent.isCreated(), @outerComponent.isRendered(), @outerComponent.isDestroyed()]

      @autorun =>
        @states.push ['inner', @outerComponent.childrenComponents()[0]?.isCreated(), @outerComponent.childrenComponents()[0]?.isRendered(), @outerComponent.childrenComponents()[0]?.isDestroyed()]

      @renderedComponent = Blaze.render @outerComponent.renderComponent(), $('body').get(0)

      Tracker.afterFlush @expect()
  ,
    ->
      Blaze.remove @renderedComponent

      Tracker.afterFlush @expect()
  ,
    ->
      @assertEqual OuterComponent.calls, [
        'OuterComponent onCreated'
        'InnerComponent onCreated'
        'InnerComponent onRendered'
        'OuterComponent onRendered'
        'InnerComponent onDestroyed'
        'OuterComponent onDestroyed'
      ]

      @assertEqual @states, [
        ['outer', false, false, false]
        ['inner', undefined, undefined, undefined]
        ['outer', true, false, false]
        ['inner', true, false, false]
        ['inner', true, true, false]
        ['outer', true, true, false]
        ['inner', undefined, undefined, undefined]
        ['outer', false, false, true]
      ]
  ]

  testNamespacedArguments: [
    ->
      MyNamespace.Foo.ArgumentsComponent.calls = []
      MyNamespace.Foo.ArgumentsComponent.constructorStateChanges = []
      MyNamespace.Foo.ArgumentsComponent.onCreatedStateChanges = []

      reactiveContext {}
      reactiveArguments {}

      @renderedComponent = Blaze.renderWithData Template.namespacedArgumentsTestTemplate, {top: '42'}, $('body').get(0)

      Tracker.afterFlush @expect()
  ,
    ->
      @assertEqual trim($('.namespacedArgumentsTestTemplate').html()), trim """
        <p>Component data context: {"a":"1","b":"2"}</p>
        <p>Current data context: {"a":"1","b":"2"}</p>
        <p>Parent data context: {"top":"42"}</p>
        <p>Arguments: []</p>
        <p>Component data context: {"a":"3a","b":"4a"}</p>
        <p>Current data context: {"a":"3a","b":"4a"}</p>
        <p>Parent data context: {"a":"3","b":"4"}</p>
        <p>Arguments: []</p>
        <p>Component data context: {"a":"5","b":"6"}</p>
        <p>Current data context: {"a":"5","b":"6"}</p>
        <p>Parent data context: {"top":"42"}</p>
        <p>Arguments: ["7",{"hash":{"a":"8","b":"9"}}]</p>
        <p>Component data context: {}</p>
        <p>Current data context: {}</p>
        <p>Parent data context: {"top":"42"}</p>
        <p>Arguments: [{},{"hash":{}}]</p>
      """

      reactiveContext {a: '10', b: '11'}

      Tracker.afterFlush @expect()
  ,
    ->
      @assertEqual trim($('.namespacedArgumentsTestTemplate').html()), trim """
        <p>Component data context: {"a":"1","b":"2"}</p>
        <p>Current data context: {"a":"1","b":"2"}</p>
        <p>Parent data context: {"top":"42"}</p>
        <p>Arguments: []</p>
        <p>Component data context: {"a":"3a","b":"4a"}</p>
        <p>Current data context: {"a":"3a","b":"4a"}</p>
        <p>Parent data context: {"a":"3","b":"4"}</p>
        <p>Arguments: []</p>
        <p>Component data context: {"a":"5","b":"6"}</p>
        <p>Current data context: {"a":"5","b":"6"}</p>
        <p>Parent data context: {"top":"42"}</p>
        <p>Arguments: ["7",{"hash":{"a":"8","b":"9"}}]</p>
        <p>Component data context: {"a":"10","b":"11"}</p>
        <p>Current data context: {"a":"10","b":"11"}</p>
        <p>Parent data context: {"top":"42"}</p>
        <p>Arguments: [{},{"hash":{}}]</p>
      """

      reactiveArguments {a: '12', b: '13'}

      Tracker.afterFlush @expect()
  ,
    ->
      @assertEqual trim($('.namespacedArgumentsTestTemplate').html()), trim """
        <p>Component data context: {"a":"1","b":"2"}</p>
        <p>Current data context: {"a":"1","b":"2"}</p>
        <p>Parent data context: {"top":"42"}</p>
        <p>Arguments: []</p>
        <p>Component data context: {"a":"3a","b":"4a"}</p>
        <p>Current data context: {"a":"3a","b":"4a"}</p>
        <p>Parent data context: {"a":"3","b":"4"}</p>
        <p>Arguments: []</p>
        <p>Component data context: {"a":"5","b":"6"}</p>
        <p>Current data context: {"a":"5","b":"6"}</p>
        <p>Parent data context: {"top":"42"}</p>
        <p>Arguments: ["7",{"hash":{"a":"8","b":"9"}}]</p>
        <p>Component data context: {"a":"10","b":"11"}</p>
        <p>Current data context: {"a":"10","b":"11"}</p>
        <p>Parent data context: {"top":"42"}</p>
        <p>Arguments: [{"a":"12","b":"13"},{"hash":{}}]</p>
      """

      Blaze.remove @renderedComponent

      # It is important that this is 5, not 6, because we have 3 components with static arguments, and we change
      # arguments twice. Component should not be created once more just because we changed its data context.
      # Only when we change its arguments.
      @assertEqual MyNamespace.Foo.ArgumentsComponent.calls.length, 5

      @assertEqual MyNamespace.Foo.ArgumentsComponent.calls, [
        undefined
        undefined
        '7'
        {}
        {a: '12', b: '13'}
      ]

      Tracker.afterFlush @expect()
  ,
    ->
      @assertArgumentsConstructorStateChanges MyNamespace.Foo.ArgumentsComponent.constructorStateChanges, false
      @assertArgumentsOnCreatedStateChanges MyNamespace.Foo.ArgumentsComponent.onCreatedStateChanges
  ,
    ->
      OurNamespace.ArgumentsComponent.calls = []
      OurNamespace.ArgumentsComponent.constructorStateChanges = []
      OurNamespace.ArgumentsComponent.onCreatedStateChanges = []

      reactiveContext {}
      reactiveArguments {}

      @renderedComponent = Blaze.renderWithData Template.ourNamespacedArgumentsTestTemplate, {top: '42'}, $('body').get(0)

      Tracker.afterFlush @expect()
  ,
    ->
      @assertEqual trim($('.ourNamespacedArgumentsTestTemplate').html()), trim """
        <p>Component data context: {"a":"1","b":"2"}</p>
        <p>Current data context: {"a":"1","b":"2"}</p>
        <p>Parent data context: {"top":"42"}</p>
        <p>Arguments: []</p>
        <p>Component data context: {"a":"3a","b":"4a"}</p>
        <p>Current data context: {"a":"3a","b":"4a"}</p>
        <p>Parent data context: {"a":"3","b":"4"}</p>
        <p>Arguments: []</p>
        <p>Component data context: {"a":"5","b":"6"}</p>
        <p>Current data context: {"a":"5","b":"6"}</p>
        <p>Parent data context: {"top":"42"}</p>
        <p>Arguments: ["7",{"hash":{"a":"8","b":"9"}}]</p>
        <p>Component data context: {}</p>
        <p>Current data context: {}</p>
        <p>Parent data context: {"top":"42"}</p>
        <p>Arguments: [{},{"hash":{}}]</p>
      """

      reactiveContext {a: '10', b: '11'}

      Tracker.afterFlush @expect()
  ,
    ->
      @assertEqual trim($('.ourNamespacedArgumentsTestTemplate').html()), trim """
        <p>Component data context: {"a":"1","b":"2"}</p>
        <p>Current data context: {"a":"1","b":"2"}</p>
        <p>Parent data context: {"top":"42"}</p>
        <p>Arguments: []</p>
        <p>Component data context: {"a":"3a","b":"4a"}</p>
        <p>Current data context: {"a":"3a","b":"4a"}</p>
        <p>Parent data context: {"a":"3","b":"4"}</p>
        <p>Arguments: []</p>
        <p>Component data context: {"a":"5","b":"6"}</p>
        <p>Current data context: {"a":"5","b":"6"}</p>
        <p>Parent data context: {"top":"42"}</p>
        <p>Arguments: ["7",{"hash":{"a":"8","b":"9"}}]</p>
        <p>Component data context: {"a":"10","b":"11"}</p>
        <p>Current data context: {"a":"10","b":"11"}</p>
        <p>Parent data context: {"top":"42"}</p>
        <p>Arguments: [{},{"hash":{}}]</p>
      """

      reactiveArguments {a: '12', b: '13'}

      Tracker.afterFlush @expect()
  ,
    ->
      @assertEqual trim($('.ourNamespacedArgumentsTestTemplate').html()), trim """
        <p>Component data context: {"a":"1","b":"2"}</p>
        <p>Current data context: {"a":"1","b":"2"}</p>
        <p>Parent data context: {"top":"42"}</p>
        <p>Arguments: []</p>
        <p>Component data context: {"a":"3a","b":"4a"}</p>
        <p>Current data context: {"a":"3a","b":"4a"}</p>
        <p>Parent data context: {"a":"3","b":"4"}</p>
        <p>Arguments: []</p>
        <p>Component data context: {"a":"5","b":"6"}</p>
        <p>Current data context: {"a":"5","b":"6"}</p>
        <p>Parent data context: {"top":"42"}</p>
        <p>Arguments: ["7",{"hash":{"a":"8","b":"9"}}]</p>
        <p>Component data context: {"a":"10","b":"11"}</p>
        <p>Current data context: {"a":"10","b":"11"}</p>
        <p>Parent data context: {"top":"42"}</p>
        <p>Arguments: [{"a":"12","b":"13"},{"hash":{}}]</p>
      """

      Blaze.remove @renderedComponent

      # It is important that this is 5, not 6, because we have 3 components with static arguments, and we change
      # arguments twice. Component should not be created once more just because we changed its data context.
      # Only when we change its arguments.
      @assertEqual OurNamespace.ArgumentsComponent.calls.length, 5

      @assertEqual OurNamespace.ArgumentsComponent.calls, [
        undefined
        undefined
        '7'
        {}
        {a: '12', b: '13'}
      ]

      Tracker.afterFlush @expect()
  ,
    ->
      @assertArgumentsConstructorStateChanges OurNamespace.ArgumentsComponent.constructorStateChanges, false
      @assertArgumentsOnCreatedStateChanges OurNamespace.ArgumentsComponent.onCreatedStateChanges
  ,
    ->
      OurNamespace.calls = []
      OurNamespace.constructorStateChanges = []
      OurNamespace.onCreatedStateChanges = []

      reactiveContext {}
      reactiveArguments {}

      @renderedComponent = Blaze.renderWithData Template.ourNamespaceComponentArgumentsTestTemplate, {top: '42'}, $('body').get(0)

      Tracker.afterFlush @expect()
  ,
    ->
      @assertEqual trim($('.ourNamespaceComponentArgumentsTestTemplate').html()), trim """
        <p>Component data context: {"a":"1","b":"2"}</p>
        <p>Current data context: {"a":"1","b":"2"}</p>
        <p>Parent data context: {"top":"42"}</p>
        <p>Arguments: []</p>
        <p>Component data context: {"a":"3a","b":"4a"}</p>
        <p>Current data context: {"a":"3a","b":"4a"}</p>
        <p>Parent data context: {"a":"3","b":"4"}</p>
        <p>Arguments: []</p>
        <p>Component data context: {"a":"5","b":"6"}</p>
        <p>Current data context: {"a":"5","b":"6"}</p>
        <p>Parent data context: {"top":"42"}</p>
        <p>Arguments: ["7",{"hash":{"a":"8","b":"9"}}]</p>
        <p>Component data context: {}</p>
        <p>Current data context: {}</p>
        <p>Parent data context: {"top":"42"}</p>
        <p>Arguments: [{},{"hash":{}}]</p>
      """

      reactiveContext {a: '10', b: '11'}

      Tracker.afterFlush @expect()
  ,
    ->
      @assertEqual trim($('.ourNamespaceComponentArgumentsTestTemplate').html()), trim """
        <p>Component data context: {"a":"1","b":"2"}</p>
        <p>Current data context: {"a":"1","b":"2"}</p>
        <p>Parent data context: {"top":"42"}</p>
        <p>Arguments: []</p>
        <p>Component data context: {"a":"3a","b":"4a"}</p>
        <p>Current data context: {"a":"3a","b":"4a"}</p>
        <p>Parent data context: {"a":"3","b":"4"}</p>
        <p>Arguments: []</p>
        <p>Component data context: {"a":"5","b":"6"}</p>
        <p>Current data context: {"a":"5","b":"6"}</p>
        <p>Parent data context: {"top":"42"}</p>
        <p>Arguments: ["7",{"hash":{"a":"8","b":"9"}}]</p>
        <p>Component data context: {"a":"10","b":"11"}</p>
        <p>Current data context: {"a":"10","b":"11"}</p>
        <p>Parent data context: {"top":"42"}</p>
        <p>Arguments: [{},{"hash":{}}]</p>
      """

      reactiveArguments {a: '12', b: '13'}

      Tracker.afterFlush @expect()
  ,
    ->
      @assertEqual trim($('.ourNamespaceComponentArgumentsTestTemplate').html()), trim """
        <p>Component data context: {"a":"1","b":"2"}</p>
        <p>Current data context: {"a":"1","b":"2"}</p>
        <p>Parent data context: {"top":"42"}</p>
        <p>Arguments: []</p>
        <p>Component data context: {"a":"3a","b":"4a"}</p>
        <p>Current data context: {"a":"3a","b":"4a"}</p>
        <p>Parent data context: {"a":"3","b":"4"}</p>
        <p>Arguments: []</p>
        <p>Component data context: {"a":"5","b":"6"}</p>
        <p>Current data context: {"a":"5","b":"6"}</p>
        <p>Parent data context: {"top":"42"}</p>
        <p>Arguments: ["7",{"hash":{"a":"8","b":"9"}}]</p>
        <p>Component data context: {"a":"10","b":"11"}</p>
        <p>Current data context: {"a":"10","b":"11"}</p>
        <p>Parent data context: {"top":"42"}</p>
        <p>Arguments: [{"a":"12","b":"13"},{"hash":{}}]</p>
      """

      Blaze.remove @renderedComponent

      # It is important that this is 5, not 6, because we have 3 components with static arguments, and we change
      # arguments twice. Component should not be created once more just because we changed its data context.
      # Only when we change its arguments.
      @assertEqual OurNamespace.calls.length, 5

      @assertEqual OurNamespace.calls, [
        undefined
        undefined
        '7'
        {}
        {a: '12', b: '13'}
      ]

      Tracker.afterFlush @expect()
  ,
    ->
      @assertArgumentsConstructorStateChanges OurNamespace.constructorStateChanges, false
      @assertArgumentsOnCreatedStateChanges OurNamespace.onCreatedStateChanges
  ]

  # Test for https://github.com/peerlibrary/meteor-blaze-components/issues/30.
  testTemplateDynamic: =>
    componentTemplate = BlazeComponent.getComponent('TemplateDynamicTestComponent').renderComponent()

    @assertTrue componentTemplate

    output = Blaze.toHTMLWithData componentTemplate,
      top: '42'

    @assertEqual trim(output), trim """
      #{ COMPONENT_CONTENT 'TemplateDynamicTestComponent', 'MainComponent' }
      <hr>
      #{ COMPONENT_CONTENT 'SubComponent' }
    """

    componentTemplate = new (BlazeComponent.getComponent('TemplateDynamicTestComponent'))().renderComponent()

    @assertTrue componentTemplate

    output = Blaze.toHTMLWithData componentTemplate,
      top: '42'

    @assertEqual trim(output), trim """
      #{ COMPONENT_CONTENT 'TemplateDynamicTestComponent', 'MainComponent' }
      <hr>
      #{ COMPONENT_CONTENT 'SubComponent' }
    """

    componentTemplate = BlazeComponent.getComponent('FooComponent').renderComponent()

    @assertTrue componentTemplate

    output = Blaze.toHTMLWithData componentTemplate,
      top: '42'

    @assertEqual trim(output), trim FOO_COMPONENT_CONTENT()

    componentTemplate = new (BlazeComponent.getComponent('FooComponent'))().renderComponent()

    @assertTrue componentTemplate

    output = Blaze.toHTMLWithData componentTemplate,
      top: '42'

    @assertEqual trim(output), trim FOO_COMPONENT_CONTENT()

    componentTemplate = BlazeComponent.getComponent('SubComponent').renderComponent()

    @assertTrue componentTemplate

    output = Blaze.toHTMLWithData componentTemplate,
      top: '42'

    @assertEqual trim(output), trim COMPONENT_CONTENT 'SubComponent'

    componentTemplate = new (BlazeComponent.getComponent('SubComponent'))().renderComponent()

    @assertTrue componentTemplate

    output = Blaze.toHTMLWithData componentTemplate,
      top: '42'

    @assertEqual trim(output), trim COMPONENT_CONTENT 'SubComponent'

  testGetComponentForElement: [
    ->
      @outerComponent = new (BlazeComponent.getComponent('OuterComponent'))()

      @renderedComponent = Blaze.render @outerComponent.renderComponent(), $('body').get(0)

      Tracker.afterFlush @expect()
  ,
    ->
      @innerComponent = @outerComponent.childrenComponents()[0]

      @assertTrue @innerComponent

      @assertEqual BlazeComponent.getComponentForElement($('.outerComponent').get(0)), @outerComponent
      @assertEqual BlazeComponent.getComponentForElement($('.innerComponent').get(0)), @innerComponent

      Blaze.remove @renderedComponent
  ]

  testBlockHelpersStructure: [
    ->
      @renderedComponent = Blaze.render Template.extraTestBlockComponent, $('body').get(0)

      Tracker.afterFlush @expect()
  ,
    ->
      @assertEqual trim($('.extraTestBlockComponent').html()), trim """
        <h2>Names and emails and components (CaptionComponent/CaptionComponent)</h2>
        <h3 class="insideBlockHelperTemplate">(ExtraTableWrapperBlockComponent/ExtraTableWrapperBlockComponent)</h3>
        <table>
          <thead>
            <tr>
              <th>Name</th>
              <th class="insideBlockHelper">Email</th>
              <th>Component (ExtraTableWrapperBlockComponent/ExtraTableWrapperBlockComponent)</th>
            </tr>
          </thead>
          <tbody>
            <tr>
              <td>Foo</td>
              <td class="insideContent">foo@example.com</td>
              <td>TestBlockComponent/TestBlockComponent</td>
            </tr>
            <tr>
              <td>Bar</td>
              <td class="insideContentComponent">bar@example.com</td>
              <td>RowComponent/RowComponent</td>
            </tr>
            <tr>
              <td>Baz</td>
              <td class="insideContentComponent">baz@example.com</td>
              <td>RowComponent/RowComponent</td>
            </tr>
            <tr>
              <td>Works</td>
              <td class="insideContentComponent">nameFromComponent1@example.com</td>
              <td>RowComponent/RowComponent</td>
            </tr>
            <tr>
              <td>Bac</td>
              <td class="insideContentComponent">bac@example.com</td>
              <td>RowComponent/RowComponent</td>
            </tr>
            <tr>
              <td>Works</td>
              <td class="insideContentComponent">nameFromComponent2@example.com</td>
              <td>RowComponent/RowComponent</td>
            </tr>
            <tr>
              <td>Works</td>
              <td class="insideContentComponent">nameFromComponent3@example.com</td>
              <td>RowComponent/RowComponent</td>
            </tr>
            <tr>
              <td>Bam</td>
              <td class="insideContentComponent">bam@example.com</td>
              <td>RowComponent/RowComponent</td>
            </tr>
            <tr>
              <td>Bav</td>
              <td class="insideContentComponent">bav@example.com</td>
              <td>RowComponent/RowComponent</td>
            </tr>
            <tr>
              <td>Bak</td>
              <td class="insideContentComponent">bak@example.com</td>
              <td>RowComponent/RowComponent</td>
            </tr>
            <tr>
              <td>Bal</td>
              <td class="insideContentComponent">bal@example.com</td>
              <td>RowComponent/RowComponent</td>
            </tr>
          </tbody>
          <tfoot>
            <tr>
              <th>Name</th>
              <th class="insideBlockHelperComponent">Email</th>
              <th>Component (FootComponent/FootComponent)</th>
            </tr>
          </tfoot>
        </table>
      """

      TestingComponentDebug.structure = {}
      TestingComponentDebug.dumpComponentTree $('.extraTestBlockComponent table').get(0)

      @assertEqual TestingComponentDebug.structure,
        component: 'TestBlockComponent'
        data: {top: '42'}
        children: [
          component: 'ExtraTableWrapperBlockComponent'
          data: {block: '43'}
          children: [
            component: 'CaptionComponent'
            data: {block: '43'}
            children: [{}]
          ,
            component: 'FootComponent'
            data: {block: '43'}
            children: [{}]
          ,
            {}
          ]
        ,
          component: 'RowComponent'
          data: {name: 'Bar', email: 'bar@example.com'}
          children: [{}]
        ,
          component: 'RowComponent'
          data: {name: 'Baz', email: 'baz@example.com'}
          children: [{}]
        ,
          component: 'RowComponent'
          data: {name: 'Works', email: 'nameFromComponent1@example.com'}
          children: [{}]
        ,
          component: 'RowComponent'
          data: {name: 'Bac', email: 'bac@example.com'}
          children: [{}]
        ,
          component: 'RowComponent'
          data: {name: 'Works', email: 'nameFromComponent2@example.com'}
          children: [{}]
        ,
          component: 'RowComponent'
          data: {name: 'Works', email: 'nameFromComponent3@example.com'}
          children: [{}]
        ,
          component: 'RowComponent'
          data: {name: 'Bam', email: 'bam@example.com'}
          children: [{}]
        ,
          component: 'RowComponent'
          data: {name: 'Bav', email: 'bav@example.com'}
          children: [{}]
        ,
          component: 'RenderRowComponent'
          data: {top: '42'}
          children: [
# TODO: Currently does not register component parent correctly because of: https://github.com/meteor/meteor/issues/4386
#            component: 'RowComponent'
#            data: {name: 'Bak', email: 'bak@example.com'}
#            children: [{}]
#          ,
            component: 'RowComponent'
            data: {name: 'Bal', email: 'bal@example.com'}
            children: [{}]
          ,
            {}
          ]
        ,
          {}
        ]

      @assertEqual BlazeComponent.getComponentForElement($('.insideContent').get(0)).componentName(), 'TestBlockComponent'
      @assertEqual BlazeComponent.getComponentForElement($('.insideContentComponent').get(0)).componentName(), 'RowComponent'
      @assertEqual BlazeComponent.getComponentForElement($('.insideBlockHelper').get(0)).componentName(), 'ExtraTableWrapperBlockComponent'
      @assertEqual BlazeComponent.getComponentForElement($('.insideBlockHelperComponent').get(0)).componentName(), 'FootComponent'
      @assertEqual BlazeComponent.getComponentForElement($('.insideBlockHelperTemplate').get(0)).componentName(), 'ExtraTableWrapperBlockComponent'

      Blaze.remove @renderedComponent
  ]

ClassyTestCase.addTest new BasicTestCase()
