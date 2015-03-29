class MainComponent extends BlazeComponent
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
    console.log @componentName(), 'MainComponent.onClick', @data(), @currentData(), @currentComponent().componentName()

  events: ->
    super.concat
      'click': @onClick

BlazeComponent.register 'MainComponent', MainComponent

class @FooComponent extends BlazeComponent
  template: ->
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

class AnimatedListComponent extends BlazeComponent
  template: ->
    'AnimatedListComponent'

  onCreated: ->
    @_counter = new ReactiveVar 0
    @_handle = Meteor.setInterval =>
      @_counter.set @_counter.get() + 1
    , 1000 # ms

  onDestroyed: ->
    Meteor.clearInterval @_handle

  list: ->
    # To register dependency.
    @_counter.get()
    _.shuffle (_id: i for i in [0...5])

  insertDOMElement: (parent, node, before) ->
    return super unless before

    $(node).insertBefore(before).velocity('transition.slideLeftIn',
      duration: 500
    )

    [parent, node, before, true]

  moveDOMElement: (parent, node, before) ->
    @insertDOMElement parent, node, before

    [parent, node, before, true]

  removeDOMElement: (parent, node) ->
    $(node).velocity('transition.slideRightOut',
      duration: 500,
      complete: =>
        $(node).remove()
    )

    [parent, node, true]

BlazeComponent.register 'AnimatedListComponent', AnimatedListComponent
