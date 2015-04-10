trim = (html) =>
  html = html.replace />\s+/g, '>'
  html = html.replace /\s+</g, '<'
  html.trim()

class MainComponent extends BlazeComponent
  @calls: []

  template: ->
    'MainComponent'

  foobar: ->
    "#{ @componentName() }/MainComponent.foobar/#{ EJSON.stringify @data() }/#{ EJSON.stringify @currentData() }/#{ @currentComponent().componentName() }"

  foobar2: ->
    "#{ @componentName() }/MainComponent.foobar2/#{ EJSON.stringify @data() }/#{ EJSON.stringify @currentData() }/#{ @currentComponent().componentName() }"

  foobar3: ->
    "#{ @componentName() }/MainComponent.foobar3/#{ EJSON.stringify @data() }/#{ EJSON.stringify @currentData() }/#{ @currentComponent().componentName() }"

  isMainComponent: ->
    @constructor is MainComponent

  onClick: (event) ->
    @constructor.calls.push [@componentName(), 'MainComponent.onClick', @data(), @currentData(), @currentComponent().componentName()]

  events: -> [
    'click': @onClick
  ]

BlazeComponent.register 'MainComponent', MainComponent

class FooComponent extends BlazeComponent
  template: ->
    'FooComponent'

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
    'AnimatedListComponent'

  onCreated: ->
    # To test inserts, moves, and removals.
    @_list = new ReactiveVar [1, 2, 3, 4, 5]
    @_handle = Meteor.setInterval =>
      list = @_list.get()

      # Moves the last number to the first place.
      list = [list[4]].concat list[0...4]

      # Removes the smallest number.
      list = _.without list, _.min list

      # Adds one more number, one larger than the current largest.
      list = list.concat [_.max(list) + 1]

      @_list.set list
    , 1000 # ms

  onDestroyed: ->
    Meteor.clearInterval @_handle

  list: ->
    _id: i for i in @_list.get()

  insertDOMElement: (parent, node, before) ->
    @constructor.calls.push ['insertDOMElement', @componentName(), trim(parent.outerHTML), trim(node.outerHTML), trim(before?.outerHTML or '')]
    super

  moveDOMElement: (parent, node, before) ->
    @constructor.calls.push ['moveDOMElement', @componentName(), trim(parent.outerHTML), trim(node.outerHTML), trim(before?.outerHTML or '')]
    super

  removeDOMElement: (parent, node) ->
    @constructor.calls.push ['removeDOMElement', @componentName(), trim(parent.outerHTML), trim(node.outerHTML)]
    super

BlazeComponent.register 'AnimatedListComponent', AnimatedListComponent

class ArgumentsComponent extends BlazeComponent
  @calls: []

  template: ->
    'ArgumentsComponent'

  constructor: ->
    @constructor.calls.push arguments[0]
    @arguments = arguments

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

reactiveContext = new ReactiveVar {}
reactiveArguments = new ReactiveVar {}

Template.argumentsTestTemplate.helpers
  reactiveContext: ->
    reactiveContext.get()

  reactiveArguments: ->
    reactiveArguments.get()

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
    'MainComponent'

  foobar: ->
    "#{ @componentName() }/ExistingClassHierarchyComponent.foobar/#{ EJSON.stringify @data() }/#{ EJSON.stringify @currentData() }/#{ @currentComponent().componentName() }"

  foobar2: ->
    "#{ @componentName() }/ExistingClassHierarchyComponent.foobar2/#{ EJSON.stringify @data() }/#{ EJSON.stringify @currentData() }/#{ @currentComponent().componentName() }"

  # We on purpose do not override foobar3.

ExistingClassHierarchyComponent.register 'ExistingClassHierarchyComponent', ExistingClassHierarchyComponent

class FirstMixin extends BlazeComponent
  @calls: []

  foobar: ->
    "#{ @mixinParent().componentName() }/FirstMixin.foobar/#{ EJSON.stringify @data() }/#{ EJSON.stringify @currentData() }/#{ @currentComponent().componentName() }"

  foobar2: ->
    "#{ @mixinParent().componentName() }/FirstMixin.foobar2/#{ EJSON.stringify @data() }/#{ EJSON.stringify @currentData() }/#{ @currentComponent().componentName() }"

  foobar3: ->
    "#{ @mixinParent().componentName() }/FirstMixin.foobar3/#{ EJSON.stringify @data() }/#{ EJSON.stringify @currentData() }/#{ @currentComponent().componentName() }"

  isMainComponent: ->
    @mixinParent().constructor is WithMixinsComponent

  onClick: (event) ->
    @constructor.calls.push [@mixinParent().componentName(), 'FirstMixin.onClick', @data(), @currentData(), @currentComponent().componentName()]

  events: -> [
    'click': @onClick
  ]

class SecondMixin extends BlazeComponent
  @calls: []

  foobar: ->
    "#{ @mixinParent().componentName() }/SecondMixin.foobar/#{ EJSON.stringify @data() }/#{ EJSON.stringify @currentData() }/#{ @currentComponent().componentName() }"

  foobar2: ->
    "#{ @mixinParent().componentName() }/SecondMixin.foobar2/#{ EJSON.stringify @data() }/#{ EJSON.stringify @currentData() }/#{ @currentComponent().componentName() }"

  # We on purpose do not provide foobar3.

  onClick: (event) ->
    @constructor.calls.push [@mixinParent().componentName(), 'SecondMixin.onClick', @data(), @currentData(), @currentComponent().componentName()]

  events: -> [
    'click': @onClick
  ]

  onCreated: ->
    # To test if adding a dependency during onCreated will make sure
    # to call onCreated on the added dependency as well.
    @mixinParent().requireMixin DependencyMixin

class DependencyMixin extends BlazeComponent
  @calls: []

  onCreated: ->
    @constructor.calls.push true

class WithMixinsComponent extends BlazeComponent
  template: ->
    'MainComponent'

  mixins: ->
    [SecondMixin, FirstMixin]

BlazeComponent.register 'WithMixinsComponent', WithMixinsComponent

class AfterCreateValueComponent extends BlazeComponent
  template: ->
    'AfterCreateValueComponent'

  onCreated: ->
    @foobar = '42'
    @_foobar = '43'

BlazeComponent.register 'AfterCreateValueComponent', AfterCreateValueComponent

class PostMessageButtonComponent extends BlazeComponent
  template: ->
    'PostMessageButtonComponent'

  onCreated: ->
    @color = new ReactiveVar "Red"

    $(window).on 'message.buttonComponent', (event) =>
      if color = event.originalEvent.data?.color
        @color.set color

  onDestroyed: ->
    $(window).off '.buttonComponent'

BlazeComponent.register 'PostMessageButtonComponent', PostMessageButtonComponent

class TableWrapperBlockComponent extends BlazeComponent
  template: ->
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

reactiveChild1 = new ReactiveVar false
reactiveChild2 = new ReactiveVar false

class ChildComponent extends BlazeComponent
  template: ->
    'ChildComponent'

  constructor: (@childName) ->

  onCreated: ->
    @domChanged = new ReactiveVar 0

  insertDOMElement: (parent, node, before) ->
    super

    @domChanged.set Tracker.nonreactive =>
      @domChanged.get() + 1

  moveDOMElement: (parent, node, before) ->
    super

    @domChanged.set Tracker.nonreactive =>
      @domChanged.get() + 1

  removeDOMElement: (parent, node) ->
    super

    @domChanged.set Tracker.nonreactive =>
      @domChanged.get() + 1

BlazeComponent.register 'ChildComponent', ChildComponent

class ParentComponent extends BlazeComponent
  template: ->
    'ParentComponent'

  child1: ->
    reactiveChild1.get()

  child2: ->
    reactiveChild2.get()

BlazeComponent.register 'ParentComponent', ParentComponent

class CaseComponent extends BlazeComponent
  @register 'CaseComponent'

  template: ->
    'CaseComponent'

  constructor: (kwargs) ->
    @cases = kwargs.hash

  renderCase: ->
    caseComponent = @cases[@data().case]
    return null unless caseComponent
    BlazeComponent.getComponent(caseComponent).renderComponent @

class LeftComponent extends BlazeComponent
  @register 'LeftComponent'

  template: ->
    'LeftComponent'

class MiddleComponent extends BlazeComponent
  @register 'MiddleComponent'

  template: ->
    'MiddleComponent'

class RightComponent extends BlazeComponent
  @register 'RightComponent'

  template: ->
    'RightComponent'

class MyComponent extends BlazeComponent
  @register 'MyComponent'

  template: ->
    'MyComponent'

  mixins: -> [FirstMixin2, new SecondMixin2 'foobar']

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
    super.concat
      'click': @onClick

  onCreated: ->
    @valuesPredicton = 'bc'

class SecondMixin2
  constructor: (@name) ->

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

  # Which template to use for this component.
  template: ->
    # Convention is to name the template the same as the component.
    'ExampleComponent'

  # Life-cycle hook to initialize component's state.
  onCreated: ->
    @counter = new ReactiveVar 0

  # Mapping between events and their handlers.
  events: -> [
    # You could inline the handler, but the best is to make
    # it a method so that it can be extended later on.
    'click .increment': @onClick
  ]

  onClick: (event) ->
    @counter.set @counter.get() + 1

  # Any component's method is available as a template helper in the template.
  customHelper: ->
    if @counter.get() > 10
      "Too many times"
    else if @counter.get() is 10
      "Just enough"
    else
      "Click more"

class OuterComponent extends BlazeComponent
  @register 'OuterComponent'

  @calls: []

  template: ->
    'OuterComponent'

  onCreated: ->
    OuterComponent.calls.push 'OuterComponent onCreated'

  onRendered: ->
    OuterComponent.calls.push 'OuterComponent onRendered'

  onDestroyed: ->
    OuterComponent.calls.push 'OuterComponent onDestroyed'

class InnerComponent extends BlazeComponent
  @register 'InnerComponent'

  template: ->
    'InnerComponent'

  onCreated: ->
    OuterComponent.calls.push 'InnerComponent onCreated'

  onRendered: ->
    OuterComponent.calls.push 'InnerComponent onRendered'

  onDestroyed: ->
    OuterComponent.calls.push 'InnerComponent onDestroyed'

class BasicTestCase extends ClassyTestCase
  @testName: 'blaze-components - basic'

  FOO_COMPONENT_CONTENT = ->
    """
      <p>Other component: FooComponent</p>
      <button>Foo1</button>
      <p></p>
      <button>Foo2</button>
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
      @componentName 'WithoutTemplateComponent'

    @assertThrows =>
      Blaze.toHTML WithoutTemplateComponent.renderComponent()
    ,
      /Component method 'template' not overridden/

    @assertThrows =>
      Blaze.toHTML new WithoutTemplateComponent().renderComponent()
    ,
      /Component method 'template' not overridden/

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

  testEvents: =>
    MainComponent.calls = []
    SubComponent.calls = []

    renderedComponent = Blaze.render Template.eventsTestTemplate, $('body').get(0)

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

    Blaze.remove renderedComponent

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

  testArguments: [
    ->
      ArgumentsComponent.calls = []

      reactiveContext.set {}
      reactiveArguments.set {}

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

      reactiveContext.set {a: '10', b: '11'}

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

      reactiveArguments.set {a: '12', b: '13'}

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
      reactiveChild1.set false
      reactiveChild2.set false

      @component = new ParentComponent()

      @componentChildren = []
      @handle = Tracker.autorun (computation) =>
        @componentChildren.push @component.componentChildren()

      @componentChildrenChild1 = []
      @handleChild1 = Tracker.autorun (computation) =>
        @componentChildrenChild1.push @component.componentChildrenWith childName: 'child1'

      @componentChildrenChild1DOM = []
      @handleChild1DOM = Tracker.autorun (computation) =>
        @componentChildrenChild1DOM.push @component.componentChildrenWith (child) ->
          # We can search also based on DOM. We use domChanged to be sure check is called
          # every time DOM changes. But it does not seem to be really necessary in this
          # particular test (it passes without it as well). On the other hand domChanged
          # also does not capture all changes. We are searching for an element by CSS class
          # and domChanged is not changed when a class changes on a DOM element.
          #child.domChanged.get()
          child.$('.child1').length

      @renderedComponent = Blaze.render @component.renderComponent(), $('body').get(0)

      Tracker.afterFlush @expect()
  ,
    ->
      @assertEqual @component.componentChildren(), []

      reactiveChild1.set true

      Tracker.afterFlush @expect()
  ,
    ->
      @assertEqual @component.componentChildren().length, 1

      @child1Component = @component.componentChildren()[0]

      @assertEqual @child1Component.componentParent(), @component

      reactiveChild2.set true

      Tracker.afterFlush @expect()
  ,
    ->
      @assertEqual @component.componentChildren().length, 2

      @child2Component = @component.componentChildren()[1]

      @assertEqual @child2Component.componentParent(), @component

      reactiveChild1.set false

      Tracker.afterFlush @expect()
  ,
    ->
      @assertEqual @component.componentChildren(), [@child2Component]
      @assertEqual @child1Component.componentParent(), null

      reactiveChild2.set false

      Tracker.afterFlush @expect()
  ,
    ->
      @assertEqual @component.componentChildren(), []
      @assertEqual @child2Component.componentParent(), null

      Blaze.remove @renderedComponent

      @handle.stop()
      @handleChild1.stop()
      @handleChild1DOM.stop()

      @assertEqual @componentChildren, [
        []
        [@child1Component]
        [@child1Component, @child2Component]
        [@child2Component]
        []
      ]

      @assertEqual @componentChildrenChild1, [
        []
        [@child1Component]
        []
      ]

      @assertEqual @componentChildrenChild1DOM, [
        []
        [@child1Component]
        []
      ]
  ]

  testCases: [
    ->
      @dataContext = new ReactiveVar {case: 'left'}

      @renderedComponent = Blaze.renderWithData Template.useCaseTemplate, (=> @dataContext.get()), $('body').get(0)

      Tracker.afterFlush @expect()
    ->
      @assertEqual trim($('.useCaseTemplate').html()), trim """
        <p>Left</p>
      """

      @dataContext.set {case: 'middle'}

      Tracker.afterFlush @expect()
    ->
      @assertEqual trim($('.useCaseTemplate').html()), trim """
        <p>Middle</p>
      """

      @dataContext.set {case: 'right'}

      Tracker.afterFlush @expect()
    ->
      @assertEqual trim($('.useCaseTemplate').html()), trim """
        <p>Right</p>
      """

      @dataContext.set {case: 'unknown'}

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

  testReadmeExampleES6: [
    ->
      @renderedComponent = Blaze.render BlazeComponent.getComponent('ExampleComponentES6').renderComponent(), $('body').get(0)

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

  testMixinsExampleWithES6: [
    ->
      @renderedComponent = Blaze.renderWithData BlazeComponent.getComponent('OurComponentES6').renderComponent(), {top: '42'}, $('body').get(0)

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

      @renderedComponent = Blaze.render BlazeComponent.getComponent('OuterComponent').renderComponent(), $('body').get(0)

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
  ]

ClassyTestCase.addTest new BasicTestCase()
