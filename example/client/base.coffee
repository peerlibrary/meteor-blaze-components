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

  events: -> [
    'click': @onClick
  ]

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

# jQuery offset() returns coordinates of the content part of the element,
# ignoring any margins. outerOffset() returns outside coordinates of the
# element, including margins.
$.fn.outerOffset = ->
  marginLeft = parseFloat(this.css('margin-left'))
  marginTop = parseFloat(this.css('margin-top'))
  offset = this.offset()
  offset.left -= marginLeft
  offset.top -= marginTop
  offset

class AnimatedListComponent extends BlazeComponent
  template: ->
    'AnimatedListComponent'

  onCreated: ->
    @_list = new ReactiveVar [1...6]
    @_handle = Meteor.setInterval =>
      list = @_list.get()
      assert list.length > 1
      indexFrom = parseInt Random.fraction() * list.length
      indexTo = indexFrom
      while indexTo is indexFrom
        indexTo = parseInt Random.fraction() * list.length
      list.splice indexTo, 0, list.splice(indexFrom, 1)[0]
      @_list.set list
    , 2000 # ms

  onDestroyed: ->
    Meteor.clearInterval @_handle

  list: ->
    _id: i for i in @_list.get()

  moveDOMElement: (parent, node, before) ->
    $node = $(node)
    # Traversing until a node works better because sometimes "before" is a text node and
    # then it is not found correctly and nextUntil/prevUntil selects everything. This
    # means that we are traversing backwards so code is a bit less clear. Originally it
    # was $node.prevUntil(before).add(before) and $node.nextUntil(before).
    $prev = $(before).nextUntil(node).add(before) # node is inserted before "before", so we add "before" as well
    $next = $(before).prevUntil(node)

    nodeOuterHeight = $node.outerHeight true

    oldNodeOffset = $node.outerOffset()
    $node.detach().insertBefore(before)
    newNodeOffset = $node.outerOffset()

    $node.css(
      # We want for node to go over the other elements.
      position: 'relative'
      zIndex: 1
    ).velocity(
      translateZ: 0
      # We translate the node temporary back to the old position.
      translateY: [oldNodeOffset.top - newNodeOffset.top]
    ,
      duration: 0
    ).velocity(
      # And then animate them slowly to new position.
      translateY: [0]
    ,
      duration: 1000
      complete: ->
        $node.css(
          # After it finishes, we remove display and z-index.
          position: ''
          zIndex: ''
        )
    )

    # TODO: Find a better way to determine which elements are between node and "before", a way which does not assume order of elements in DOM tree has same direction as elements' positions
    # Currently, we store both previous and next elements and then after the move we determine
    # which are those elements we also have to move to make visually space for a moved node.
    if oldNodeOffset.top - newNodeOffset.top < 0
      # Moving node down
      $betweenElements = $next
    else
      # Moving node up
      $betweenElements = $prev

    $betweenElements = $betweenElements.filter (i, element) ->
      element.nodeType isnt Node.TEXT_NODE

    $betweenElements.velocity(
      translateZ: 0
      # We translate nodes in-between temporary back to the old position.
      translateY: [if oldNodeOffset.top - newNodeOffset.top < 0 then nodeOuterHeight else -1 * nodeOuterHeight]
    ,
      duration: 0
    ).velocity(
      # And then animate them slowly to new position.
      translateY: [0]
    ,
      duration: 1000
    )

    return

BlazeComponent.register 'AnimatedListComponent', AnimatedListComponent

class MyNamespace

class MyNamespace.Foo

class MyNamespace.Foo.MyComponent extends BlazeComponent
  @register 'MyNamespace.Foo.MyComponent'

  template: ->
    'MyNamespace.Foo.MyComponent'

  dataContext: ->
    EJSON.stringify @data()
