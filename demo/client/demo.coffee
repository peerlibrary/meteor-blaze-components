### Auto-select demo ###

Template.autoSelectDemo.helpers
  value: ->
    Values.findOne(@id)?.value

### Auto-select input ###

Template.autoSelectInput.helpers
  value: ->
    # Read value from the collection.
    Values.findOne(@id)?.value

Template.autoSelectInput.events
  # Save value to the collection when it changes.
  'change input': (event, template) ->
    Values.upsert @id, $set: value: event.target.value

  # Auto-select text when user clicks in the input.
  'click input': (event, template) ->
    $(event.target).select()

### Auto-select input component ###

class AutoSelectInputComponent extends BlazeComponent
  @register 'AutoSelectInputComponent'

  template: ->
    'autoSelectInput'

  value: ->
    Values.findOne(@data().id)?.value

  events: ->
    super.concat
      'change input': @onChange
      'click input': @onClick

  onChange: (event) ->
    Values.upsert @data().id, $set: value: event.target.value

  onClick: (event) ->
    $(event.target).select()

### Auto-select textarea component ###

class AutoSelectTextareaComponent extends AutoSelectInputComponent
  @register 'AutoSelectTextareaComponent'

  template: ->
    'autoSelectTextarea'

  events: ->
    super.concat
      'change textarea': @onChange
      'click textarea': @onClick

### Real-time input component ###

class RealTimeInputComponent extends AutoSelectInputComponent
  @register 'RealTimeInputComponent'

  events: ->
    super.concat
      'keyup input': @onKeyup

  onKeyup: (event) ->
    $(event.target).change()

### Frozen input component ###

class FrozenInputComponent extends AutoSelectInputComponent
  @register 'FrozenInputComponent'

  onCreated: ->
    super
    # We need to know when we are editing the input so that the user's entry is preserved during editing (even if meteor
    # would have to replace it with a newer value). To do this we will supply a frozen value (set at the start of
    # editing) to the rendering engine, so it will not re-render our input box, until we empty the frozen value.
    @frozenValue = new ReactiveVar()

  value: ->
    # Return frozen value if it is set (it will be during editing, thanks to focus and blur event handlers).
    @frozenValue.get() or super

  events: ->
    super.concat
      'focus input': @onFocus
      'blur input': @onBlur

  onFocus: (event) ->
    # Initialize the starting value when starting to edit.
    @frozenValue.set @value()

  onBlur: (event) ->
    # We are no longer editing, so we can return to displaying the reactive source of the value (parent implementation).
    @frozenValue.set null

### Smart (auto-select, real-time, frozen) input component ###

class SmartInputComponent extends BlazeComponent
  @register 'SmartInputComponent'

  template: ->
    'smartInput'

  mixins: ->
    [AutoSelectInputMixin, RealTimeInputMixin, FrozenInputMixin]

  value: ->
    @callMixinWith(@, 'value') or Values.findOne(@data().id)?.value

  events: ->
    super.concat
      'change input': @onChange

  onChange: (event) ->
    Values.upsert @data().id, $set: value: event.target.value

class AutoSelectInputMixin extends BlazeComponent
  events: ->
    super.concat
      'click input': @onClick

  onClick: (event) ->
    $(event.target).select()

class RealTimeInputMixin extends BlazeComponent
  events: ->
    super.concat
      'keyup input': @onKeyUp

  onKeyUp: (event) ->
    $(event.target).change()

class FrozenInputMixin extends BlazeComponent
  onCreated: ->
    @frozenValue = new ReactiveVar()

  value: ->
    @frozenValue.get()

  events: ->
    super.concat
      'focus input': @onFocus
      'blur input': @onBlur

  onFocus: (event) ->
    @frozenValue.set @mixinParent().value()

  onBlur: (event) ->
    @frozenValue.set null

### Even smarter (auto-select, real-time, frozen, cancelable) input component ###

class EvenSmarterInputComponent extends SmartInputComponent
  @register 'EvenSmarterInputComponent'

  mixins: ->
    [CancelableInputMixin]

class CancelableInputMixin extends BlazeComponent
  onCreated: ->
    # We rely on the frozen input mixin for obtaining the initial value.
    @mixinParent().addMixin FrozenInputMixin

  events: ->
    super.concat
      'keydown input': @onKeyDown

  onKeyDown: (event) ->
    # Undo renaming on escape.
    if event.keyCode is 27
      previousValue = @mixinParent().getMixin(FrozenInputMixin).frozenValue.get()
      $(event.target).val(previousValue).change().blur()
