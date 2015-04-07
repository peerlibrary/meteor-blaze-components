### Auto-select demo ###

Template.autoSelectDemo.helpers
  value: ->
    Values.findOne(@id)?.value

### Auto-select input ###

Template.input.helpers
  value: ->
    # Read value from the collection.
    Values.findOne(@id)?.value

Template.input.events
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
    'input'

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
    'AutoSelectTextareaComponent'

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

### Persistent input component ###

class PersistentInputComponent extends AutoSelectInputComponent
  @register 'PersistentInputComponent'

  onCreated: ->
    super
    # This will store the value at the start of editing.
    @storedValue = new ReactiveVar()

  value: ->
    # Return stored value during editing or normal otherwise.
    @storedValue.get() or super

  events: ->
    super.concat
      'focus input': @onFocus
      'blur input': @onBlur

  onFocus: (event) ->
    # Store the current value when starting to edit.
    @storedValue.set @value()

  onBlur: (event) ->
    # We are no longer editing, so return to normal.
    @storedValue.set null

### Smart (auto-select, real-time, persistent) input component ###

class SmartInputComponent extends BlazeComponent
  @register 'SmartInputComponent'

  template: ->
    'input'

  mixins: ->
    [AutoSelectInputMixin, RealTimeInputMixin, PersistentInputMixin]

  value: ->
    @callFirstWith(@, 'value') or Values.findOne(@data().id)?.value

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

class PersistentInputMixin extends BlazeComponent
  onCreated: ->
    @storedValue = new ReactiveVar()

  value: ->
    @storedValue.get()

  events: ->
    super.concat
      'focus input': @onFocus
      'blur input': @onBlur

  onFocus: (event) ->
    @storedValue.set @mixinParent().value()

  onBlur: (event) ->
    @storedValue.set null

### Extreme decomposition (auto-select, real-time, persistent, cancelable, form field, storage) input component ###

class PersistentInputMixin2 extends BlazeComponent
  onCreated: ->
    @storedValue = new ReactiveVar()

  value: ->
    @storedValue.get() or @mixinParent().callFirstWith(@, 'value')

  events: ->
    super.concat
      'focus input': @onFocus
      'blur input': @onBlur

  onFocus: (event) ->
    @storedValue.set @mixinParent().callFirstWith(null, 'value')

  onBlur: (event) ->
    @storedValue.set null

class ExtremeInputComponent extends BlazeComponent
  @register 'ExtremeInputComponent'

  template: ->
    'input'

  mixins: -> [
    AutoSelectInputMixin, RealTimeInputMixin,
    CancelableInputMixin, FormFieldMixin,
    new StorageMixin Values, 'value', => @data().id
  ]

class FormFieldMixin extends BlazeComponent
  value: ->
    @mixinParent().callFirstWith(null, 'getValue')

  events: ->
    super.concat
      'change input': @onChange

  onChange: (event) ->
    @mixinParent().callFirstWith(null, 'setValue', event.target.value)

class StorageMixin extends BlazeComponent
  constructor: (@collection, @fieldName, @selector) ->

  getValue: ->
    @collection.findOne(@selector())?[@fieldName]

  setValue: (value) ->
    modifier = $set: {}
    modifier.$set[@fieldName] = value
    @collection.upsert @selector(), modifier

class CancelableInputMixin extends BlazeComponent
  mixinParent: (mixinParent) ->
    # We rely on the persistent input mixin to obtain the stored value.
    mixinParent.requireMixin PersistentInputMixin2 if mixinParent
    super

  events: ->
    super.concat
      'keydown input': @onKeyDown

  onKeyDown: (event) ->
    # Undo renaming on escape.
    if event.keyCode is 27
      storedValue = @mixinParent().getMixin(PersistentInputMixin2).storedValue.get()
      $(event.target).val(storedValue).change().blur()
