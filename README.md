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

Mixins
------

Animations
----------

Use with existing classes
-------------------------


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
In template helpers `currentData` returns the data context where a template helper was called. In life cycle
hooks `onCreated`, `onRendered`, and `onDestroyed`, it is the same as [`data`](#user-content-reference_instance_data).
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

This is just a helpful instance method which calls `@componentName` class method.

Related projects
----------------

* [meteor-template-extension](https://github.com/aldeed/meteor-template-extension) – provides various ways of copying
template helpers, event handlers and hooks between templates, allowing code reuse; a downside is that all copying
has to be taken care by a developer, often again and again, which becomes problematic as codebase grows; moreover,
without a clearly defined API community cannot build and share components
* [meteor-autoform](https://github.com/aldeed/meteor-autoform) – offers forms components through a sophisticated
use of templates and template helpers but it is still hard to compose behaviors you want beyond defining additional
input fields
