class MainComponent extends BlazeComponent
  @template: ->
    'MainComponent'

  foobar: ->
    console.log "foobar", @data(), @currentData()
    "Works"

  foobar2: ->
    console.log "foobar2", @data(), @currentData()
    "Works2"

  onClick: (event) ->
    console.log "onClick", @data(), @currentData()

  events: ->
    super.concat
      'click': @onClick

BlazeComponent.register 'MainComponent', MainComponent

class @FooComponent extends BlazeComponent
  @template: ->
    'FooComponent'

BlazeComponent.register 'FooComponent', FooComponent
