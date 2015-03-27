class MainComponent extends BlazeComponent
  @calls: []

  @template: ->
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
    @constructor.calls.push @componentName(), 'MainComponent.onClick', @data(), @currentData(), @currentComponent().componentName()

  events: ->
    super.concat
      'click': @onClick

BlazeComponent.register 'MainComponent', MainComponent

class @FooComponent extends BlazeComponent
  @template: ->
    'FooComponent'

BlazeComponent.register 'FooComponent', FooComponent

class SubComponent extends MainComponent
  @calls: []

  foobar: ->
    "#{ @componentName() }/SubComponent.foobar/#{ EJSON.stringify @data() }/#{ EJSON.stringify @currentData() }/#{ @currentComponent().componentName() }"

  foobar2: ->
    "#{ @componentName() }/SubComponent.foobar2/#{ EJSON.stringify @data() }/#{ EJSON.stringify @currentData() }/#{ @currentComponent().componentName() }"

  # We on purpose to not override foobar3.

  onClick: (event) ->
    @constructor.calls.push @componentName(), 'SubComponent.onClick', @data(), @currentData(), @currentComponent().componentName()

BlazeComponent.register 'SubComponent', SubComponent

class BasicTestCase extends ClassyTestCase
  @testName: 'blaze-components - basic'

  FOO_COMPONENT_CONTENT = """
    <p>Other component: FooComponent</p>
    <button>Foo1</button>
    <p></p>
    <button>Foo2</button>
    <p></p>
    <p></p>
  """

  SUB_COMPONENT_CONTENT = """
    <p>Main component: SubComponent</p>
    <button>Foo1</button>
    <p>SubComponent/SubComponent.foobar/{"top":"42"}/{"top":"42"}/SubComponent</p>
    <button>Foo2</button>
    <p>SubComponent/SubComponent.foobar2/{"top":"42"}/{"a":"1","b":"2"}/SubComponent</p>
    <p>SubComponent/MainComponent.foobar3/{"top":"42"}/{"top":"42"}/SubComponent</p>
    <p>Subtemplate</p>
    <button>Foo1</button>
    <p>SubComponent/SubComponent.foobar/{"top":"42"}/{"top":"42"}/SubComponent</p>
    <button>Foo2</button>
    <p>SubComponent/SubComponent.foobar2/{"top":"42"}/{"a":"3","b":"4"}/SubComponent</p>
    <p>SubComponent/MainComponent.foobar3/{"top":"42"}/{"top":"42"}/SubComponent</p>
    #{ FOO_COMPONENT_CONTENT }
  """

  trim: (html) =>
    html = html.replace />\s+/g, '>'
    html = html.replace /\s+</g, '<'
    html.trim()

  testComponents: =>
    componentTemplate = BlazeComponent.getComponentTemplate 'MainComponent'

    @assertTrue componentTemplate

    output = Blaze.toHTMLWithData componentTemplate,
      top: '42'

    @assertEqual @trim(output), @trim """
      <p>Main component: MainComponent</p>
      <button>Foo1</button>
      <p>MainComponent/MainComponent.foobar/{"top":"42"}/{"top":"42"}/MainComponent</p>
      <button>Foo2</button>
      <p>MainComponent/MainComponent.foobar2/{"top":"42"}/{"a":"1","b":"2"}/MainComponent</p>
      <p>MainComponent/MainComponent.foobar3/{"top":"42"}/{"top":"42"}/MainComponent</p>
      <p>Subtemplate</p>
      <button>Foo1</button>
      <p>MainComponent/MainComponent.foobar/{"top":"42"}/{"top":"42"}/MainComponent</p>
      <button>Foo2</button>
      <p>MainComponent/MainComponent.foobar2/{"top":"42"}/{"a":"3","b":"4"}/MainComponent</p>
      <p>MainComponent/MainComponent.foobar3/{"top":"42"}/{"top":"42"}/MainComponent</p>
      #{ FOO_COMPONENT_CONTENT }
      <hr>
      #{ SUB_COMPONENT_CONTENT }
    """

    componentTemplate = BlazeComponent.getComponentTemplate 'FooComponent'

    @assertTrue componentTemplate

    output = Blaze.toHTMLWithData componentTemplate,
      top: '42'

    @assertEqual @trim(output), @trim FOO_COMPONENT_CONTENT

    componentTemplate = BlazeComponent.getComponentTemplate 'SubComponent'

    @assertTrue componentTemplate

    output = Blaze.toHTMLWithData componentTemplate,
      top: '42'

    @assertEqual @trim(output), @trim SUB_COMPONENT_CONTENT

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

ClassyTestCase.addTest new BasicTestCase()
