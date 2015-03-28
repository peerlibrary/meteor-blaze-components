### Auto-select demo ###

Template.autoSelectDemo.helpers
  value: ->
    Values.findOne(@id)?.value

### Auto-select input ###

Template.autoSelectInput.helpers
  value: ->
    console.log @
    # Read value from collection.
    Values.findOne(@id)?.value

Template.autoSelectInput.events
  # Save value to collection when it changes.
  'change input': (event, template) ->
    Values.upsert @id,
      value: event.target.value

  # Auto-select text when user clicks in the input.
  'click input': (event, template) ->
    $(event.target).select()

### Auto-select input component ###

class AutoSelectInputComponent extends BlazeComponent
  template: ->
    'autoSelectInput'

  value: ->
    console.log "UPDATED"
    Values.findOne(@data().id)?.value

  events: ->
    super.concat
      'change input': @onChange
      'click input': @onClick

  onChange: (event) ->
    Values.upsert @data().id, value: event.target.value

  onClick: (event) ->
    $(event.target).select()

BlazeComponent.register 'AutoSelectInputComponent', AutoSelectInputComponent

### Auto-select textarea component ###

class AutoSelectTextareaComponent extends AutoSelectInputComponent
  template: ->
    'autoSelectTextarea'

  events: ->
    super.concat
      'change textarea': @onChange
      'click textarea': @onClick

BlazeComponent.register 'AutoSelectTextareaComponent', AutoSelectTextareaComponent

### Real-time input component ###

class RealTimeInputComponent extends AutoSelectInputComponent
  events: ->
    super.concat
      'keyup input': @onKeyup

  onKeyup: (event) ->
    $(event.target).change()

BlazeComponent.register 'RealTimeInputComponent', RealTimeInputComponent


### Frozen input component ###

class FrozenInputComponent extends AutoSelectInputComponent

  # TODO: Write the code here! :)

BlazeComponent.register 'FrozenInputComponent', FrozenInputComponent

### Real-time input

RealTimeInputVar = new ReactiveVar 'Meteor'

Template.realTimeInput.created = ->
  @_previousValue = new ReactiveVar ''

Template.realTimeInput.helpers
  value: ->
    RealTimeInputVar.get()

Template.realTimeInput.events
  'change input': (event, template) ->
    RealTimeInputVar.set event.target.value

  'keyup input': (event, template) ->
    $(event.target).change()

  'click input': (event, template) ->
    $(event.target).select()

  'focus input': (event, template) ->
    template._previousValue.set event.target.value

  'keydown input': (event, template) ->
    # Undo renaming on escape.
    if event.keyCode is 27
      previousValue = template._previousValue.get()
      $(event.target).val(previousValue).change().blur()

Template.realTimeInputDemo.helpers
  value: ->
    RealTimeInputVar.get()

###