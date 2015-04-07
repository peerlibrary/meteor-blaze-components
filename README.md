Meteor Blaze Components
=======================

Blaze Components for [Meteor](https://meteor.com/) are a system for easily developing complex UI elements
that need to be reused around your Meteor app.

See [live tutorial](http://components.meteor.com/) for an introduction.

Adding this package to your Meteor application adds `BlazeComponent` class into the global scope.

Client side only.

Installation
------------

```
meteor add peerlibrary:blaze-components
```

Components
----------

Accessing data context
----------------------


Passing arguments
-----------------

Life-cycle hooks
----------------

Component-based block helpers
-----------------------------

You can use Blaze Components to define block helpers as well.

Example:

```handlebars
<template name="TableWrapperBlockComponent">
  <table>
    <thead>
      <tr>
        <th>Name</th>
        <th>Email</th>
      </tr>
    </thead>
    <tbody>
      {{> Template.contentBlock}}
    </tbody>
    <tfoot>
      <tr>
        <td colspan="2">
          {{> Template.elseBlock}}
        </td>
      </tr>
    </tfoot>
  </table>
</template>
```

```handlebars
{{#TableWrapperBlockComponent}}
  {{#each customers}}
    <td>{{name}}</td>
    <td>{{email}}</td>
  {{/each}}
{{else}}
  <p class="copyright">Content available under the CC0 license.</p>
{{/TableWrapperBlockComponent}}
```

You can use [`Template.contentBlock` and `Template.elseBlock`](https://github.com/meteor/meteor/blob/devel/packages/spacebars/README.md#custom-block-helpers)
to define "content" and "else" inclusion points.

You can modify just block helpers data context by passing it in the tag:

```handlebars
<template name="TableWrapperBlockComponent">
  <table class="{{color}}">
...
```

```handlebars
{{#TableWrapperBlockComponent color='red'}}
...
```

Notice that block helper's data context is available only inside a block helper's template, but data context where
it is used (one with `customers`) stays the same.

You can also [pass arguments](#passing-arguments) to a component:

```handlebars
{{#TableWrapperBlockComponent args displayCopyright=false}}
...
```

For when to use a data context and when arguments the same rule of thumb from the [Passing arguments](#passing-arguments)
section applies.

Blaze provides up to two inclusion points in block helpers. If you need more you should probably not use a component
as a block helper but move the logic to the component's method, returning a rendered Blaze Component instance or template
which provides any content you want. You can provide content (possibly as Blaze Components themselves) to the component
through your component arguments or data context.

Example:

```handlebars
<template name="CaseComponent">
  {{> renderCase}}
</template>

<template name="useCaseTemplate">
  {{> CaseComponent args left='LeftComponent' middle='MiddleComponent' right='RightComponent'}}
</template>
```

```coffee
class CaseComponent extends BlazeComponent
  @register 'CaseComponent'

  template: ->
    'CaseComponent'
    
  constructor: (kwargs) ->
    @cases = kwargs.hash

  renderCase: ->
    caseComponent = @cases[@data().case]
    return null unless caseComponent
    BlazeComponent.getComponent(caseComponent).renderComponent @
```

If you use `CaseComponent` now in the `{case: 'left'}` data context, a `LeftComponent`
component will be rendered. If you want to control in which data context `LeftComponent`
is rendered, you can specify data context as `{{> renderCase dataContext}}`.

*Example above is using `renderComponent` method which is not yet public.*

Animations
----------

Blaze Components provide [low-level DOM manipulation hooks](#low-level-dom-manipulation-hooks) you can use to
hook into insertion, move, or removal of DOM elements. Primarily you can use this to animate manipulation of
DOM elements, but at the end you have to make sure you do the requested DOM manipulation correctly because Blaze
will expect it done.

Hooks are called only when DOM elements themselves are manipulated and not when their attributes change.

A common pattern of using the hooks is to do the DOM manipulation as requested immediately, to the final state, and
then only visually instantaneously revert to the initial state and then animate back to the final state. For example,
to animate move of a DOM element you can first move the DOM element to the new position, and then use CSS translation
to visually move it back to the previous position and then animate it slowly to the new position. The DOM element itself
stays in the new position all the time in the DOM, only visually is being translated to the old position and animated.

One way for animating is to modify CSS, like toggling a CSS class which enables animations. Another common way
is to use a library like [Velocity](http://julian.com/research/velocity/).

Animations are best provided as [reusable mixins](#mixins-1). But for performance reasons the default
implementation of [`insertDOMElement`](#user-content-reference_instance_insertDOMElement),
[`moveDOMElement`](#user-content-reference_instance_moveDOMElement), and
[`removeDOMElement`](#user-content-reference_instance_removeDOMElement) just performs the manipulation and does not
try to call mixins. So for components where you want to enable mixin animations for, you should extend those methods
with something like:

```coffee
insertDOMElement: (parent, node, before) ->
  @callFirstWith @, 'insertDOMElement', parent, node, before
  super

moveDOMElement: (parent, node, before) ->
  @callFirstWith @, 'moveDOMElement', parent, node, before
  super

removeDOMElement: (parent, node) ->
  @callFirstWith @, 'removeDOMElement', parent, node
  super
```

*See [Momentum Meteor package](https://github.com/percolatestudio/meteor-momentum) for more information on how to
use these hooks to animate DOM elements.*

Mixins
------

Blaze Components are designed around the [composition over inheritance](http://en.wikipedia.org/wiki/Composition_over_inheritance)
paradigm. JavaScript is a single-inheritance language and instead of Blaze Components trying to force fake
multiple-inheritance onto a language, it offers a
[set of utility methods](https://github.com/peerlibrary/meteor-blaze-components/#mixins-1) which allow the component to
interact with its mixins and mixins with the component. The code becomes more verbose because of the use of methods
instead of overloading, overriding or extending the existing elements of the language or objects, but we believe that
results are easier to read, understand, and maintain.

Each mixin becomes its own JavaScript object with its own state, but they share a life-cycle with the component.
Most commonly mixin is an instance of a provided mixin class.

A contrived example to showcase various features of mixins:

```coffee
class MyComponent extends BlazeComponent
  @register 'MyComponent'

  template: ->
    'MyComponent'

  mixins: -> [FirstMixin, new SecondMixin 'foobar']

  alternativeName: ->
    @callFirstWith null, 'templateHelper'

  values: ->
    'a' + (@callFirstWith(@, 'values') or '')

class FirstMixinBase extends BlazeComponent
  templateHelper: ->
    "42"

  extendedHelper: ->
    1

  onClick: ->
    throw new Error() if @values() isnt @valuesPredicton

class FirstMixin extends FirstMixinBase
  extendedHelper: ->
    super + 2

  values: ->
    'b' + (@mixinParent().callFirstWith(@, 'values') or '')

  dataContext: ->
    EJSON.stringify @mixinParent().data()

  events: ->
    super.concat
      'click': @onClick

  onCreated: ->
    @valuesPredicton = 'bc'

class SecondMixin
  constructor: (@name) ->

  mixinParent: (mixinParent) ->
    @_mixinParent = mixinParent if mixinParent
    @_mixinParent

  values: ->
    'c' + (@mixinParent().callFirstWith(@, 'values') or '')
```

```handlebars
<template name="MyComponent">
  <p>alternativeName: {{alternativeName}}</p>
  <p>values: {{values}}</p>
  <p>templateHelper: {{templateHelper}}</p>
  <p>extendedHelper: {{extendedHelper}}</p>
  <p>name: {{name}}</p>
  <p>dataContext: {{dataContext}}</p>
</template>
```

When this component is rendered using the `{top: '42'}` as a data context, it is rendered as:

```html
<p>alternativeName: 42</p>
<p>values: abc</p>
<p>templateHelper: 42</p>
<p>extendedHelper: 3</p>
<p>name: foobar</p>
<p>dataContext: {"top":"42"}</p>
```

We can visualize class structure and mixins.






Let's dissect the example.

As we can see all methods become template helpers and they are searched for in the normal order, first the
component, then mixins. First implementation found is called. If the implementation wants to continue with
traversal it can call a method like [`callFirstWith`](user-content-reference_instance_callFirstWith).

```coffee
mixins: -> [FirstMixin, new SecondMixin 'foobar']
```

We can see that mixins can be also already made instances. And that mixins do not have to extend
`BlazeComponent`. You get some methods for free, but you can use whatever you want to provide your features.

```coffee
alternativeName: ->
  @callFirstWith null, 'templateHelper'
```

Wa call [`callFirstWith`](user-content-reference_instance_callFirstWith) with `null` which makes it traverse
the whole stack, the component and all mixins, when searching for the first implementation of `templateHelper`.

This allows us to not assume much about where the `templateHelper` is implemented. But be careful, if `templateHelper`
would do the same back, calling the `alternativeName` on the whole stack, you might get into an inifinite loop.

```coffee
values: ->
  'a' + (@callFirstWith(@, 'values') or '')
```

`values` method is passing `@` to p[`callFirstWith`](user-content-reference_instance_callFirstWith), signaling that only
mixins after the component should be traversed.

This is a general pattern for traversal which all `values` methods in this example use. Similar to how you would use
`super` call in inheritance. `values` methods add their own letter to the result and ask later mixins for possible
more content.

Calling [`callFirstWith`](user-content-reference_instance_callFirstWith) in this way traverses the stack from the left
to the right on the diagram of our example, one implementation of `values` after another.

```coffee
onClick: ->
  throw new Error() if @values() isnt @valuesPredicton
```

Event handlers (and all other methods) have `@`/`this` bound to the mixin instance, not the component. Here we can see
how the event handler can access `values` and `valuesPredicton` on mixin's instance and how normal CoffeeScript
inheritance works between `FirstMixinBase` and `FirstMixin`.

Event handlers are independent from other mixins and the component's event handlers. They are attached to DOM in the
normal traversal order, first the component's, then mixins'. 

To control how events are propagated between the component and mixins you can use `event` object methods like
[`stopPropagation`](https://api.jquery.com/event.stopPropagation/) and
[`stopImmediatePropagation`](https://api.jquery.com/event.stopImmediatePropagation/).

```coffee
extendedHelper: ->
  super + 2
```

You can use normal CoffeeScript inheritance in your mixins. On the diagram of our example this traverses upwards.

```coffee
dataContext: ->
  EJSON.stringify @mixinParent().data()
```

To access the data context used for the component you first access the component, and then its data context.

```coffee
onCreated: ->
  @valuesPredicton = 'bc'
```

Mixin's life-cycle matches that of the component and mixin's life-cycle hooks are automatically called by Blaze
Components when the component is [created](#user-content-reference_instance_onCreated),
[rendered](#user-content-reference_instance_onRendered), and [destroyed](#user-content-reference_instance_onDestroyed).
`@`/`this` is bound to the mixin instance.

```coffee
mixinParent: (mixinParent) ->
  @_mixinParent = mixinParent if mixinParent
  @_mixinParent
```

Because `SecondMixin` does not extend `BlazeComponent` we have to provide the
[`mixinParent`](#user-content-reference_instance_mixinParent) method ourselves. It is called by the Blaze Components
as a setter to tell the mixin what its component instance is.

[`mixinParent`](#user-content-reference_instance_mixinParent) is a good place to add any dependencies to the
component your mixin might need. Extend it and your additional logic.

Example:

```coffee
mixinParent: (mixinParent) ->
  mixinParent.requireMixin DependencyMixin if mixinParent
  super
```

Don't forget to call `super`.

*See the [tutorial](http://components.meteor.com/#the-cooperation) for a more real example of mixins.*

Use with existing classes
-------------------------

Blaze Components are designed to work with existing class hierarchies. There are no restrictions on class constructor,
for example. In fact, Blaze Components can be seen simply as an API a class or object has to provide to be compatible
with the system. The easiest way to bootstrap your class hierarchy is to copy default implementations from
`BlazeComponent` to your class.

Example:

```coffee
for property, value of BlazeComponent when property not in ['__super__']
  YourBaseClass[property] = value
for property, value of (BlazeComponent::) when property not in ['constructor']
  YourBaseClass::[property] = value
```

Reference
---------

**API is still in development and we seek community input. Please
[use GitHub issues](https://github.com/peerlibrary/meteor-blaze-components/issues) to offer your suggestions
and feedback, and join existing discussions there.**

### Class methods ###

<a name="reference_class_register"></a>
```coffee
@register: (componentName, [componentClass]) ->
```

Registers a new component with the name `componentName`. This makes it available in templates and elsewhere
in the component system under that name, and assigns the name to the component. If `componentClass`
argument is omitted, class on which `@register` is called is used.

<a name="reference_class_getComponent"></a>
```coffee
@getComponent: (componentName) ->
```

Retrieves the component class with `componentName` name. If such component does not exist, `null` is returned.

<a name="reference_class_componentName"></a>
```coffee
@componentName: ([componentName])  ->
```

When called without a `componentName` argument it returns the component name.

When called with a `componentName` argument it sets the component name.

*Setting the component name yourself is needed and required only for unregistered classes because
[`@register`](#user-content-reference_class_register) sets the component name automatically otherwise. All component
should have a component name associated with them.*

### Instance methods ###

#### Event handlers ####

<a name="reference_instance_events"></a>
```coffee
events: ->
```

Extend this method and return event hooks for the component's DOM content. Method should return an array of event maps,
where an event map is an object where the properties specify a set of events to handle, and the values are the
handlers for those events. The property can be in one of several forms:

* `eventtype` – Matches a particular type of event, such as `click`.
* `eventtype selector` – Matches a particular type of event, but only when it appears on an element that matches a
certain CSS selector.
* `event1, event2` – To handle more than one type of event with the same function, use a comma-separated list.

The handler function receives one argument, a [jQuery event object](https://api.jquery.com/category/events/event-object/),
and optional extra arguments for custom events. The common pattern is to simply pass methods as event handlers to allow
subclasses to extend the event handlers logic through inheritance.

Example:

```coffee
events: ->
  super.concat
    'click': @onClick
    'click .accept': @onAccept
    'click .accept, focus .accept, keypress': @onMultiple
    
# Fires when any element is clicked.
onClick: (event) ->

# Fires when any element with the "accept" class is clicked.
onAccept: (event) ->

# Fires when 'accept' is clicked or focused, or a key is pressed.
onMultiple: (event) ->
```

Blaze Components make sure that event handlers are called bound with the component itself in `this`/`@`.
This means you can [normally access data context and the component itself](#access-to-data-context-and-components)
in the event handler.

When extending this method make sure to not forget about possible ancestor event handlers you can get through
the `super` call. Concatenate additional event handlers in subclasses and/or modify ancestor event handlers before
returning them all.

Returned values from event handlers are ignored. To control how events are propagated you can use `event` object
methods like [`stopPropagation`](https://api.jquery.com/event.stopPropagation/) and
[`stopImmediatePropagation`](https://api.jquery.com/event.stopImmediatePropagation/).

When [mixins](#mixins-1) provide event handlers, they are attached in order of mixins, with the component first.

*For more information about event maps, event handling, and `event` object, see [Blaze documentation](http://docs.meteor.com/#/full/eventmaps)
and [jQuery documentation](https://api.jquery.com/category/events/event-object/).*

#### DOM content ####

<a name="reference_instance_template"></a>
```coffee
template: ->
```

Extend this method and return the name of a [Blaze template](http://docs.meteor.com/#/full/templates_api) or template
object itself. Template content will be used to render component's DOM content, but all preexisting template helpers,
event handlers and life-cycle hooks will be ignored.

All component methods are available in the template as template helpers. Template helpers are bound to the component
itself in `this`/`@`.

You can include other templates (to keep individual templates manageable) and components.

Convention is to name component templates the same as components, which are named the same as their classes.
And because components are classes, they start with an upper-case letter.

*See [Spacebars documentation](http://docs.meteor.com/#/full/templates_api) for more information about the template
language.*

#### Access to rendered content ####

<a name="reference_instance_$"></a>
```coffee
$: (selector) ->
```

Finds all DOM elements matching the `selector` in the rendered content of the component, and returns them
as a [JQuery object](https://api.jquery.com/Types/#jQuery).

The component serves as the document root for the selector. Only elements inside the component and its
sub-components can match parts of the selector.

*Wrapper around [Blaze's `$`](http://docs.meteor.com/#/full/template_$).*

<a name="reference_instance_find"></a>
```coffee
find: (selector) ->
```

Finds one DOM element matching the `selector` in the rendered content of the component, or returns `null`
if there are no such elements.

The component serves as the document root for the selector. Only elements inside the component and its
sub-components can match parts of the selector.

*Wrapper around [Blaze's `find`](http://docs.meteor.com/#/full/template_find).*

<a name="reference_instance_findAll"></a>
```coffee
findAll: (selector) ->
```

Finds all DOM element matching the `selector` in the rendered content of the component. Returns an array.

The component serves as the document root for the selector. Only elements inside the component and its
sub-components can match parts of the selector.

*Wrapper around [Blaze's `findAll`](http://docs.meteor.com/#/full/template_findAll).*

<a name="reference_instance_firstNode"></a>
```coffee
firstNode: ->
```

Returns the first top-level DOM node in the rendered content of the component.

The two nodes `firstNode` and `lastNode` indicate the extent of the rendered component in the DOM. The rendered
component includes these nodes, their intervening siblings, and their descendents. These two nodes are siblings
(they have the same parent), and `lastNode` comes after `firstNode`, or else they are the same node.

*Wrapper around [Blaze's `firstNode`](http://docs.meteor.com/#/full/template_firstNode).*

<a name="reference_instance_lastNode"></a>
```coffee
lastNode: ->
```

Returns the last top-level DOM node in the rendered content of the component.

*Wrapper around [Blaze's `lastNode`](http://docs.meteor.com/#/full/template_lastNode).*

#### Access to data context and components ####

<a name="reference_instance_data"></a>
```coffee
data: ->
```

Returns current component-level data context. A reactive data source.

Use this to always get the top-level data context used to render the component.

<a name="reference_instance_currentData"></a>
```coffee
currentData: ->
```

Returns current caller-level data context. A reactive data source.

In [event handlers](#event-handlers) use `currentData` to get the data context at the place where the event originated (target context).
In template helpers `currentData` returns the data context where a template helper was called. In life-cycle
hooks [`onCreated`](#user-content-reference_instance_onCreated), [`onRendered`](#user-content-reference_instance_onRendered),
and [`onDestroyed`](#user-content-reference_instance_onDestroyed), it is the same as [`data`](#user-content-reference_instance_data).
Inside a template accessing the method as a template helper `currentData` is the same as `this`/`@`.

Example:

```handlebars
<template name="Buttons">
  <button>Red</button>
  {{color1}}
  {{#with color='blue'}}
    <button>Blue</button>
    {{color2}}
  {{/with}}
</template>
```

If top-level data context is `{color: "red"}`, then `currentData` inside a `color1` component method (template helper)
will return `{color: "red"}`, but inside a `color2` it will return `{color: "blue"}`. Similarly, click event handler on
buttons will by calling `currentData` get `{color: "red"}` as the data context for red button, and `{color: "blue"}` for
blue button. In all cases `data` will return `{color: "red"}`.

<a name="reference_instance_component"></a>
```coffee
component: ->
```

Returns the component. Useful in templates to get a reference to the component.

<a name="reference_instance_currentComponent"></a>
```coffee
currentComponent: ->
```

Similar to [`currentData`](user-content-reference_instance_currentData), `currentComponent` returns current
caller-level component.

In most cases the same as `this`/`@`, but in event handlers it returns the component at the place where
event originated (target component).

<a name="reference_instance_componentName"></a>
```coffee
componentName: ->
```

This is a complementary instance method which calls [`@componentName`](#user-content-reference_class_componentName)
class method.

<a name="reference_instance_componentParent"></a>
```coffee
componentParent: ->
```

Returns the component's parent component, if it exists, or `null`. A reactive data source.

The parent component is available only after the component has been [created](#user-content-reference_instance_onCreated),
and until is [destroyed](#user-content-reference_instance_onDestroyed).

<a name="reference_instance_componentChildren"></a>
```coffee
componentChildren: ([nameOrComponent]) ->
```

Returns an array of component's children components. A reactive data source. The order of children components in the
array is arbitrary.

You can specify a component name, class, or instance to limit the resulting children to.

The children components are in the array only after they have been [created](#user-content-reference_instance_onCreated),
and until they are [destroyed](#user-content-reference_instance_onDestroyed).

<a name="reference_instance_componentChildrenWith"></a>
```coffee
componentChildrenWith: (propertyOrMatcherOrFunction) ->
```

Returns an array of component's children components which match a `propertyOrMatcherOrFunction` predicate. A reactive
data source. The order of children components in the array is arbitrary.

A `propertyOrMatcherOrFunction` predicate can be:
* a property name string, in this case all children components which have a property with the given name are matched
* a matcher object specifying mapping between property names and their values, in this case all children components
which have all properties fom the matcher object equal to given values are matched (if a property is a function, it
is called and its return value is compared instead)
* a function which receives `(child, parent)` with `this`/`@` bound to `parent`, in this case all children components
for which the function returns a true value are matched

Examples:

```coffee
component.componentChildrenWith 'propertyName'
component.componentChildrenWith propertyName: 42
component.componentChildrenWith (child, parent) ->
  child.propertyName is 42
```

The children components are in the array only after they have been [created](#user-content-reference_instance_onCreated),
and until they are [destroyed](#user-content-reference_instance_onDestroyed).

#### Life-cycle hooks ####

<a name="reference_instance_constructor"></a>
```coffee
constructor: (args...) ->
```

When a component is created, its constructor is first called. There are no restrictions on component's constructor
and Blaze Components are designed to [coexist with classes](#use-with-existing-classes) which require their own
arguments when instantiated. To facilitate this, Blaze Components operate equally well with classes (which are
automatically instantiated as needed) or already made instances. The real life-cycle of a Blaze Component starts
after its instantiation.

When including a component in a template, you can pass arguments to a constructor by using the `args` keyword.

Example:

```handlebars
{{> ButtonComponent args 12 color='red'}}
```

Blaze Components will call `ButtonComponent`'s constructor with arguments `12` and `Spacebars.kw({color: 'red'})`
when instantiating the component's class. Keyword arguments are wrapped into
[`Spacebars.kw`](https://github.com/meteor/meteor/blob/devel/packages/spacebars/README.md#helper-arguments).

After the component is instantiated, all its [mixins](#user-content-reference_instance_mixins) are instantiated as well.

<a name="reference_instance_onCreated"></a>
```coffee
onCreated: ->
```

Extend this method to do any initialization of the component before it is rendered for the first time. This is a better
place to do so than a class constructor because it does not depend on the component nature,
[mixins](#user-content-reference_instance_mixins) are already initialized, and most Blaze Components methods
work as expected (component was not yet rendered, so [DOM related methods](#access-to-rendered-content) do not yet work).

A recommended use is to initialize any reactive variables and subscriptions internal to the component.

Example:

```coffee
class ButtonComponent extends BlazeComponent
  @register 'ButtonComponent'

  template: ->
    'ButtonComponent'
 
  onCreated: ->
    super

    @color = new ReactiveVar "Red"

    $(window).on 'message.buttonComponent', (event) =>
      if color = event.originalEvent.data?.color
        @color.set color

  onDestroyed: ->
    super

    $(window).off '.buttonComponent'
```

```handlebars
<template name="ButtonComponent">
  <button>{{color.get}}</button>
</template>
```

You can now use [`postMessage`](https://developer.mozilla.org/en-US/docs/Web/API/Window/postMessage) to send messages
like `{color: "Blue"}` which would reactively change the label of the button.

When [mixins](#mixins-1) provide `onCreated` method, they are called after the component in mixins order automatically.

<a name="reference_instance_onRendered"></a>
```coffee
onRendered: ->
```

This method is called once when a component is rendered into DOM nodes and put into the document for the first time.

Because your component has been rendered, you can use [DOM related methods](#access-to-rendered-content) to access
component's DOM nodes.

This is the place where you can initialize 3rd party libraries to work with the DOM content as well. Keep in
mind that interactions of a 3rd party library with Blaze controlled content might bring unintentional consequences
so consider reimplementing the 3rd party library as a Blaze Component instead.

When [mixins](#mixins-1) provide `onRendered` method, they are called after the component in mixins order automatically.

<a name="reference_instance_onDestroyed"></a>
```coffee
onDestroyed: ->
```

This method is called when an occurrence of a component is taken off the page for any reason and not replaced
with a re-rendering.

Here you can clean up or undo any external effects of [`onCreated`](#user-content-reference_instance_onCreated)
or [`onRendered`](#user-content-reference_instance_onRendered) methods. See the example above.

When [mixins](#mixins-1) provide `onDestroyed` method, they are called after the component in mixins order automatically.

#### Utilities ####

<a name="reference_instance_autorun"></a>
```coffee
autorun: (runFunc) ->
```

A version of [`Tracker.autorun`](http://docs.meteor.com/#/full/tracker_autorun) that is stopped when the component is
destroyed. You can use `autorun` from an [`onCreated`](#user-content-reference_instance_onCreated) or
[`onRendered`](user-content-reference_instance_onRendered) life-cycle hooks to reactively update the DOM or the component.

<a name="reference_instance_subscribe"></a>
```coffee
subscribe: (name, args..., [callbacks]) ->
```

A version of [`Meteor.subscribe`](http://docs.meteor.com/#meteor_subscribe) that is stopped when the component is
destroyed. You can use `subscribe` from an [`onCreated`](#user-content-reference_instance_onCreated) life-cycle hook to
specify which data publications this component depends on.

<a name="reference_instance_subscriptionsReady"></a>
```coffee
subscriptionsReady: ->
```

This method returns `true` when all of the subscriptions called with [`subscribe`](#user-content-reference_instance_subscribe)
are ready. Same as with all other methods, you can use it as a template helper in the component's template.

#### Low-level DOM manipulation hooks ####

<a name="reference_instance_insertDOMElement"></a>
```coffee
insertDOMElement: (parent, node, before) ->
```

Every time Blaze wants to insert a new DOM element into the component's DOM content it calls this method. The default
implementation is that if `node` has not yet been inserted, it simply inserts the `node` DOM element under the
`parent` DOM element, as a sibling before the `before` DOM element, or as the last element if `before` is `null`.

You can extend this method if you want to insert the new DOM element in a different way, for example, by animating
it. Make sure you do insert it correctly because Blaze will expect it to be there afterwards.

If you want to use [mixins](#mixins-1) with the `insertDOMElement` method, you will have to extend the component's
method to call them in the way you want.

<a name="reference_instance_moveDOMElement"></a>
```coffee
moveDOMElement: (parent, node, before) ->
```

Every time Blaze wants to move a DOM element to a new position between siblings it calls this method. The default
implementation is that if `node` has not yet been moved, it simply moves the `node` DOM element before the `before`
DOM element, or as the last element if `before` is `null`.

You can extend this method if you want to move the DOM element in a different way, for example, by animating
it. Make sure you do move it correctly because Blaze will expect it to be there afterwards.

If you want to use [mixins](#mixins-1) with the `moveDOMElement` method, you will have to extend the component's
method to call them in the way you want.

<a name="reference_instance_removeDOMElement"></a>
```coffee
removeDOMElement: (parent, node) ->
```

Every time Blaze wants to remove a DOM element it calls this method. The default implementation is that
if `node` has not yet been removed, it simply removes the `node` DOM element.

You can extend this method if you want to remove the DOM element in a different way, for example, by animating
it. Make sure you do remove it correctly because Blaze will expect it to be removed afterwards.

If you want to use [mixins](#mixins-1) with the `removeDOMElement` method, you will have to extend the component's
method to call them in the way you want.

#### Mixins ####

<a name="reference_instance_mixins"></a>
```coffee
mixins: ->
```

Extend this method and return mixins for the component. Mixins can be components themselves, or just classes or
objects resembling them. No method is required for them, but methods will be called on them by Blaze
Components if they do exist.

The `mixins` method should return an array of registered component names, mixin classes, or mixin instances.
When component instance is created, all mixins' instances are created as well, if they were not already an
instance. Life-cycle of mixin instances matches that of the component.

<a name="reference_instance_getMixin"></a>
```coffee
getMixin: (nameOrMixin) ->
```

Returns the component's mixin instance for a given name, class, or instance. Returns `null` if mixin is not found.

You can use it to check if a given mixin is used by the component.

<a name="reference_instance_getFirstWith"></a>
```coffee
getFirstWith: (afterComponentOrMixin, propertyName) ->
```

It searchers the component and its mixins in order to find the first with a property `propertyName`. If
`afterComponentOrMixin` is `null`, it starts with the component itself. If `afterComponentOrMixin` is the component,
it starts with the first mixin. Otherwise it starts with the mixin after `afterComponentOrMixin`.

Returns `null` if such component or mixin is not found.

<a name="reference_instance_callFirstWith"></a>
```coffee
callFirstWith: (afterComponentOrMixin, propertyName, args...) ->
```

It searchers the component and its mixins in order to find the first with a property `propertyName`
and if it is a function, calls it with `args...` as arguments, otherwise returns the value of the property.
If `afterComponentOrMixin` is `null`, it starts with the component itself. If `afterComponentOrMixin` is the component,
it starts with the first mixin. Otherwise it starts with the mixin after `afterComponentOrMixin`.

Returns `undefined` if such component or mixin is not found.

<a name="reference_instance_mixinParent"></a>
```coffee
mixinParent: ([mixinParent]) ->
```

When called without a `mixinParent` argument it returns the mixin's parent. For a component instance's mixins it
returns the component instance.

When called with a `mixinParent` argument it sets the mixin's parent.

*Setting the mixin's parent is done automatically by calling this method when creating component's mixins. Extend
(or provide) this method if you want to do any action when parent is set, for example, add dependency mixins to
the parent using [`requireMixin`](user-content-reference_instance_requireMixin). Make sure you call `super` as well.*

<a name="reference_instance_requireMixin"></a>
```coffee
requireMixin: (nameOrMixin) ->
```

Adds a mixin after already added mixins. `nameOrMixin` can be a registered component name, mixin class, or
mixin instance.

If mixin is already added to the component the method does nothing.

Use `requireMixin` to manually add additional mixins after a component was created. For example, to add
dependencies required by automatically added mixins as a result of [`mixins`](user-content-reference_instance_mixins).

Related projects
----------------

* [meteor-template-extension](https://github.com/aldeed/meteor-template-extension) – provides various ways of copying
template helpers, event handlers and hooks between templates, allowing code reuse; a downside is that all copying
has to be taken care by a developer, often again and again, which becomes problematic as codebase grows; moreover,
without a clearly defined API community cannot build and share components
* [meteor-autoform](https://github.com/aldeed/meteor-autoform) – offers forms components through a sophisticated
use of templates and template helpers but it is still hard to compose behaviors you want beyond defining additional
input fields
