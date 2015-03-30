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

Life-cycle hooks
----------------

Passing arguments
-----------------

Mixins
------

Animations
----------

Use with existing classes
-------------------------

Reference
---------

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

Retrieves a component class with `componentName` name. If such component does not exist, `null` is returned.

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

The handler function receives one argument, an [jQuery event object](https://api.jquery.com/category/events/event-object/),
and optional extra arguments for custom events. The common pattern is to simply pass methods as event handlers to allow
subclasses to extend the event handlers logic through inheritance.

Example:

```coffee
# Fires when any element is clicked.
onClick: (event) ->

# Fires when any element with the "accept" class is clicked.
onAccept: (event) ->

# Fires when 'accept' is clicked or focused, or a key is pressed.
onMultiple: (event) ->

events: ->
  super.concat
    'click': @onClick
    'click .accept': @onAccept
    'click .accept, focus .accept, keypress': @onMultiple
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

When [mixins](#mixins-1) provide event handlers, they are attached in order of mixins, with the component last.

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
hooks [`onCreated`](#user-content-reference_instance_onCreated), [`onRendered`](user-content-reference_instance_onRendered),
and [`onDestroyed`](user-content-reference_instance_onDestroyed), it is the same as [`data`](#user-content-reference_instance_data).
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

If top-level data context is `color='red'`, then `currentData` inside a `color1` component method (template helper)
will return `color='red'`, but inside a `color2` it will return `color='blue'`. Similarly, click event handler on
buttons will by calling `currentData` get `color='red'` as the data context for red button, and `color='blue'` for
blue button. In all cases `data` will return `color='red'`.

<a name="reference_instance_currentComponent"></a>
```coffee
currentComponent: ->
```

Similar to [`currentData`](user-content-reference_instance_currentData), `currentComponent` returns current
caller-level component. A reactive data source.

In most cases the same as `this`/`@`, but in event handlers it returns the component at the place where
event originated (target component).

<a name="reference_instance_componentName"></a>
```coffee
componentName: ->
```

This is a complementary instance method which calls `@componentName` class method.

#### Life-cycle hooks ####

<a name="reference_instance_constructor"></a>
```coffee
constructor: (args...) ->
```

When a component is created, its constructor is first called. There are no restrictions on component's constructor
and Blaze Components are designed to coexist with classes which require their own arguments when initialized. To
facilitate this, Blaze Components operate equally well with classes (which are automatically instantiated as needed)
or already made instances. The real life-cycle of a Blaze Component starts after its instantiation.

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

When [mixins](#mixins-1) provide `onCreated` method, the default implementation calls them in order.

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

When [mixins](#mixins-1) provide `onRendered` method, the default implementation calls them in order.

<a name="reference_instance_onDestroyed"></a>
```coffee
onDestroyed: ->
```

This method is called when an occurrence of a component is taken off the page for any reason and not replaced
with a re-rendering.

Here you can clean up or undo any external effects of [`onCreated`](#user-content-reference_instance_onCreated)
or [`onRendered`](#user-content-reference_instance_onRendered) methods. See the example above.

When [mixins](#mixins-1) provide `onDestroyed` method, the default implementation calls them in order.

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
subscribe: (name, [args...], [callbacks]) ->
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
insertDOMElement: (parent, node, before, alreadyInserted=false) ->
```

Every time Blaze wants to insert a new DOM element into the component's DOM content it calls this method. The default
implementation is that it simply inserts the `node` DOM element under the `parent` DOM element, as a sibling
before the `before` DOM element, or as the last element if `before` is `null`.

You can extend this method if you want to insert the new DOM element in a different way, for example, by animating
it. Make sure you do insert it correctly because Blaze will expect it to be there afterwards.

When [mixins](#mixins-1) provide this method, the default implementation calls them in order, passing the returned
values of one to another, until the default component method is reached. All methods should return an array of
`[parent, node, before, alreadyInserted]` values. If `node` is inserted into the DOM by any method, that method
should return `alreadyInserted` set to `true`.

<a name="reference_instance_moveDOMElement"></a>
```coffee
moveDOMElement: (parent, node, before, alreadyMoved=false) ->
```

Every time Blaze wants to move a DOM element to a new position between siblings it calls this method. The default
implementation is that it simply moves the `node` DOM element before the `before` DOM element, or as the last
element if `before` is `null`.

You can extend this method if you want to move the DOM element in a different way, for example, by animating
it. Make sure you do move it correctly because Blaze will expect it to be there afterwards.

When [mixins](#mixins-1) provide this method, the default implementation calls them in order, passing the returned
values of one to another, until the default component method is reached. All methods should return an array of
`[parent, node, before, alreadyMoved]` values. If the `node` is moved to the final position by any method, that method
should return `alreadyMoved` set to `true`.

<a name="reference_instance_removeDOMElement"></a>
```coffee
removeDOMElement: (parent, node, alreadyRemoved=false) ->
```

Every time Blaze wants to remove a DOM element it calls this method. The default implementation is that
it simply removed the `node` DOM element.

You can extend this method if you want to remove the DOM element in a different way, for example, by animating
it. Make sure you do remove it correctly because Blaze will expect it to be removed afterwards.

When [mixins](#mixins-1) provide this method, the default implementation calls them in order, passing the returned
values of one to another, until the default component method is reached. All methods should return an array of
`[parent, node, alreadyRemoved]` values. If the `node` is removed by any method, that method should return
`alreadyRemoved` set to `true`.

#### Mixins ####

<a name="reference_instance_mixins"></a>
```coffee
mixins: ->
```

Extend this method and return mixins for the component. Mixins can be components themselves, or just classes or
objects resembling them. None method is required for them, but methods will be called on them by Blaze
Components if they do exist.

The `mixins` method should return an array of registered component names, mixin classes, or mixin instances.
When component instance is created, all mixins' instances are created as well, if they were not already an
instance. Life-cycle of mixin instances matches that of the component.

<a name="reference_instance_getMixin"></a>
```coffee
getMixin: (nameOrMixin) ->
```

Returns a component's mixin instance for a given name, class, or instance. Returns `null` if mixin is not found.

You can use it to check if a given mixin is used by a component.

<a name="reference_instance_getFirstMixin"></a>
```coffee
getFirstMixin: (propertyName) ->
```

Returns the first component's mixin instance which has an property `propertyName`. Returns `null` if such mixin
is not found.

<a name="reference_instance_callFirstMixin"></a>
```coffee
callFirstMixin: (propertyName, args...) ->
```

Finds the first component's mixin instance which has an property `propertyName` and if it is a function, calls
it with `args...` as arguments, otherwise returns the value of the property. Returns `undefined` if such mixin
is not found.

<a name="reference_instance_callMixins"></a>
```coffee
callMixins: (propertyName, args...) ->
```

Finds all component's mixin instances which have an property `propertyName` and calls them in order with `args...`
as arguments, returning an array of values returned from those calls.

<a name="reference_instance_foldMixins"></a>
```coffee
foldMixins: (propertyName, args...) ->
```

Iterates over all component's mixin instances which have an property `propertyName` and calls them in order
passing `args...` as arguments to the first one, and results of that call to the second one as arguments, and so on
until the last value returned is returned.

<a name="reference_instance_mixinParent"></a>
```coffee
mixinParent: (mixinParent) ->
```

When called without a `mixinParent` argument it returns the mixin's parent. For a component instance's mixins it
returns the component instance.

When called with a `mixinParent` argument it sets the mixin's parent.

*Setting the mixin's parent is done automatically by calling this method when creating component's mixins. Extend
(or provide) this method if you want to do any action when parent is set, for example, add dependency mixins to
the parent using [`addMixin`](user-content-reference_instance_addMixin). Make sure you call `super` as well.*

<a name="reference_instance_addMixin"></a>
```coffee
addMixin: (nameOrMixin) ->
```

Adds a mixin after already added mixins. `nameOrMixin` can be a registered component name, mixin class, or
mixin instance.

If mixin is already added to the component the method does nothing.

Use `addMixin` to manually add additional mixins after a component was created. For example, to add dependencies
required by automatically added mixins as a result of [`mixins`](user-content-reference_instance_mixins).

Related projects
----------------

* [meteor-template-extension](https://github.com/aldeed/meteor-template-extension) – provides various ways of copying
template helpers, event handlers and hooks between templates, allowing code reuse; a downside is that all copying
has to be taken care by a developer, often again and again, which becomes problematic as codebase grows; moreover,
without a clearly defined API community cannot build and share components
* [meteor-autoform](https://github.com/aldeed/meteor-autoform) – offers forms components through a sophisticated
use of templates and template helpers but it is still hard to compose behaviors you want beyond defining additional
input fields
