class MainComponent extends BlazeComponent
  @template: ->
    'MainComponent'

  onCreated: ->
    @_seconds = new ReactiveVar parseInt new Date().valueOf() / 1000
    @_handle = Meteor.setInterval =>
      @_seconds.set parseInt new Date().valueOf() / 1000
    , 5000 # ms

  onDestroyed: ->
    Meteor.clearInterval @_handle

  list: ->
    # To register dependency.
    @_seconds.get()
    _.shuffle (_id: i for i in [0...5])

  foobar: ->
    "#{ @componentName() }/MainComponent.foobar/#{ EJSON.stringify @data() }/#{ EJSON.stringify @currentData() }/#{ @currentComponent().componentName() }"

  foobar2: ->
    "#{ @componentName() }/MainComponent.foobar2/#{ EJSON.stringify @data() }/#{ EJSON.stringify @currentData() }/#{ @currentComponent().componentName() }"

  foobar3: ->
    "#{ @componentName() }/MainComponent.foobar3/#{ EJSON.stringify @data() }/#{ EJSON.stringify @currentData() }/#{ @currentComponent().componentName() }"

  isMainComponent: ->
    @constructor is MainComponent

  onClick: (event) ->
    console.log @componentName(), 'MainComponent.onClick', @data(), @currentData(), @currentComponent().componentName()

  events: ->
    super.concat
      'click': @onClick

BlazeComponent.register 'MainComponent', MainComponent

class @FooComponent extends BlazeComponent
  @template: ->
    'FooComponent'

BlazeComponent.register 'FooComponent', FooComponent

class SubComponent extends MainComponent
  foobar: ->
    "#{ @componentName() }/SubComponent.foobar/#{ EJSON.stringify @data() }/#{ EJSON.stringify @currentData() }/#{ @currentComponent().componentName() }"

  foobar2: ->
    "#{ @componentName() }/SubComponent.foobar2/#{ EJSON.stringify @data() }/#{ EJSON.stringify @currentData() }/#{ @currentComponent().componentName() }"

  # We on purpose do not override foobar3.

  onClick: (event) ->
    console.log @componentName(), 'SubComponent.onClick', @data(), @currentData(), @currentComponent().componentName()

BlazeComponent.register 'SubComponent', SubComponent
