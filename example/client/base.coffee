class MainComponent extends BlazeComponent
  @template: ->
    'MainComponent'

  foobar: ->
    console.log "foobar", @data(), @currentData(), @currentComponent()
    "Works"

  foobar2: ->
    console.log "foobar2", @data(), @currentData(), @currentComponent()
    "Works2"

  isMainComponent: ->
    @constructor is MainComponent

  onClick: (event) ->
    console.log "onClick", @data(), @currentData(), @currentComponent()

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
    console.log "sub-foobar", @data(), @currentData(), @currentComponent()
    "sub-Works"

  foobar2: ->
    console.log "sub-foobar2", @data(), @currentData(), @currentComponent()
    "sub-Works2"

  onClick: (event) ->
    console.log "onClick2", @data(), @currentData(), @currentComponent()

BlazeComponent.register 'SubComponent', SubComponent
