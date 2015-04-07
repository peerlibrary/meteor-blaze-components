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

Mixins
------

Use with existing classes
-------------------------

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
and Blaze Components are designed to coexist with classes which require their own arguments when instantiated. To
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
