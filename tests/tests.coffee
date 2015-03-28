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

  events: ->
    super.concat
      'click': @onClick

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
    @_list = new ReactiveVar [0, 1, 2, 3, 4]
    @_handle = Meteor.setInterval =>
      @_list.set [@_list.get()[4]].concat @_list.get()[0...4]
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

  removeDOMElement: (node) ->
    @constructor.calls.push ['removeDOMElement', @componentName(), trim(node.outerHTML)]
    super

BlazeComponent.register 'AnimatedListComponent', AnimatedListComponent

class ArgumentsComponent extends BlazeComponent
  @calls: []

  template: ->
    'ArgumentsComponent'

  constructor: ->
    @constructor.calls.push 'ArgumentsComponent constructor'
    @arguments = arguments

  dataContext: ->
    EJSON.stringify @data()

  currentDataContext: ->
    EJSON.stringify @currentData()

  constructorArguments: ->
    EJSON.stringify @arguments

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

_.extend ExistingClassHierarchyBaseComponent, BlazeComponent
_.extend ExistingClassHierarchyBaseComponent::, BlazeComponent::

class ExistingClassHierarchyComponent extends ExistingClassHierarchyBaseComponent
  template: ->
    'MainComponent'

  foobar: ->
    "#{ @componentName() }/ExistingClassHierarchyComponent.foobar/#{ EJSON.stringify @data() }/#{ EJSON.stringify @currentData() }/#{ @currentComponent().componentName() }"

  foobar2: ->
    "#{ @componentName() }/ExistingClassHierarchyComponent.foobar2/#{ EJSON.stringify @data() }/#{ EJSON.stringify @currentData() }/#{ @currentComponent().componentName() }"

  # We on purpose do not override foobar3.

ExistingClassHierarchyComponent.register 'ExistingClassHierarchyComponent', ExistingClassHierarchyComponent

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
        ['insertDOMElement', 'AnimatedListComponent', '<div class="animationTestTemplate"></div>', '<ul><li>0</li><li>1</li><li>2</li><li>3</li><li>4</li></ul>', '']
        ['removeDOMElement', 'AnimatedListComponent', '<li>0</li>']
        ['moveDOMElement', 'AnimatedListComponent', '<ul><li>1</li><li>2</li><li>3</li><li>4</li></ul>', '<li>4</li>', '']
        ['insertDOMElement', 'AnimatedListComponent', '<ul><li>4</li><li>1</li><li>2</li><li>3</li></ul>', '<li>1</li>', '']
        ['removeDOMElement', 'AnimatedListComponent', '<li>1</li>']
        ['moveDOMElement', 'AnimatedListComponent', '<ul><li>4</li><li>0</li><li>2</li><li>3</li></ul>', '<li>3</li>', '']
        ['moveDOMElement', 'AnimatedListComponent', '<ul><li>3</li><li>4</li><li>0</li><li>2</li></ul>', '<li>2</li>', '']
        ['insertDOMElement', 'AnimatedListComponent', '<ul><li>3</li><li>4</li><li>2</li><li>0</li></ul>', '<li>2</li>', '']
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

      @renderedComponent = Blaze.render Template.argumentsTestTemplate, $('body').get(0)

      Tracker.afterFlush @expect()
  ,
    ->
      @assertEqual trim($('.argumentsTestTemplate').html()), trim """
        <p>Component data context: {"a":"1","b":"2"}</p>
        <p>Current data context: {"a":"1","b":"2"}</p>
        <p>Arguments: []</p>
        <p>Component data context: {"a":"3a","b":"4a"}</p>
        <p>Current data context: {"a":"3a","b":"4a"}</p>
        <p>Arguments: []</p>
        <p>Component data context: {"a":"5","b":"6"}</p>
        <p>Current data context: {"a":"5","b":"6"}</p>
        <p>Arguments: ["7",{"hash":{"a":"8","b":"9"}}]</p>
        <p>Component data context: {}</p>
        <p>Current data context: {}</p>
        <p>Arguments: [{},{"hash":{}}]</p>
      """

      reactiveContext.set {a: '10', b: '11'}

      Tracker.afterFlush @expect()
  ,
    ->
      @assertEqual trim($('.argumentsTestTemplate').html()), trim """
        <p>Component data context: {"a":"1","b":"2"}</p>
        <p>Current data context: {"a":"1","b":"2"}</p>
        <p>Arguments: []</p>
        <p>Component data context: {"a":"3a","b":"4a"}</p>
        <p>Current data context: {"a":"3a","b":"4a"}</p>
        <p>Arguments: []</p>
        <p>Component data context: {"a":"5","b":"6"}</p>
        <p>Current data context: {"a":"5","b":"6"}</p>
        <p>Arguments: ["7",{"hash":{"a":"8","b":"9"}}]</p>
        <p>Component data context: {"a":"10","b":"11"}</p>
        <p>Current data context: {"a":"10","b":"11"}</p>
        <p>Arguments: [{},{"hash":{}}]</p>
      """

      reactiveArguments.set {a: '12', b: '13'}

      Tracker.afterFlush @expect()
  ,
    ->
      @assertEqual trim($('.argumentsTestTemplate').html()), trim """
        <p>Component data context: {"a":"1","b":"2"}</p>
        <p>Current data context: {"a":"1","b":"2"}</p>
        <p>Arguments: []</p>
        <p>Component data context: {"a":"3a","b":"4a"}</p>
        <p>Current data context: {"a":"3a","b":"4a"}</p>
        <p>Arguments: []</p>
        <p>Component data context: {"a":"5","b":"6"}</p>
        <p>Current data context: {"a":"5","b":"6"}</p>
        <p>Arguments: ["7",{"hash":{"a":"8","b":"9"}}]</p>
        <p>Component data context: {"a":"10","b":"11"}</p>
        <p>Current data context: {"a":"10","b":"11"}</p>
        <p>Arguments: [{"a":"12","b":"13"},{"hash":{}}]</p>
      """

      Blaze.remove @renderedComponent

      # TODO: This should be 5, not 6, because we have 3 components with static arguments, and we change arguments twice. But because we are passing arguments through a data context, component is created once more.
      @assertEqual ArgumentsComponent.calls.length, 6
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

ClassyTestCase.addTest new BasicTestCase()
