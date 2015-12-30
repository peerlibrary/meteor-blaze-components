Meteor Blaze Components
=======================

Blaze Components for [Meteor](https://meteor.com/) are a system for easily developing complex UI elements
that need to be reused around your Meteor app. You can use them in [ES2015, vanilla JavaScript, and
CoffeeScript](#javascript-and-coffeescript-support).

See [live tutorial](http://components.meteor.com/) for an introduction.

Adding this package to your Meteor application adds `BlazeComponent` and `BlazeComponentDebug` classes into the
global scope.

Client side only.

Table of contents
-----------------

* [Installation](#installation)
* [Additional packages](#additional-packages)
* [Components](#components)
* [JavaScript and CoffeeScript support](#javascript-and-coffeescript-support)
* [Accessing data context](#accessing-data-context)
* [Passing arguments](#passing-arguments)
* [Life-cycle hooks](#life-cycle-hooks)
* [Handling events](#handling-events)
* [Component-based block helpers](#component-based-block-helpers)
* [Animations](#animations)
* [Mixins](#mixins)
* [Namespaces](#namespaces)
* [Use with existing classes](#use-with-existing-classes)
* [Reference](#reference)
  * [Class methods](#class-methods)
  * [Instance methods](#instance-methods)
    * [Event handlers](#event-handlers)
    * [DOM content](#dom-content)
    * [Access to rendered content](#access-to-rendered-content)
    * [Access to data context and components](#access-to-data-context-and-components)
    * [Life-cycle hooks](#life-cycle-hooks-1)
    * [Utilities](#utilities)
    * [Low-level DOM manipulation hooks](#low-level-dom-manipulation-hooks)
    * [Mixins](#mixins-1)
* [Debugging](#debugging)
* [Related projects](#related-projects)

Installation
------------

```
meteor remove blaze-html-templates
meteor remove templating
meteor add peerlibrary:blaze-components
```

If you get an error that two packages are trying to handle `*.html` files, you have to make sure that your app
or a package does not depend on the `templating` packages (often through the `blaze-html-templates` package).
Blaze Components supersedes the `templating` package and provides its functionality as well.

Blaze Components compile `*.html` files both on the client and server side. If you have previously been adding
HTML files on the server side as well, you might want to limit those to the client side only. Moreover, server
side `*.html` templates do not support `<head>` or `<body>` tags.

Additional packages
-------------------

* [peerlibrary:blaze-layout-component](https://github.com/peerlibrary/blaze-layout-component) – A
  simple [Blaze Component](https://github.com/peerlibrary/meteor-blaze-components) for use with
  [Flow Router](https://github.com/kadirahq/flow-router)'s [layout manager](https://github.com/kadirahq/blaze-layout)

Components
----------

While Blaze Components are build on top of [Blaze](https://www.meteor.com/blaze), Meteor's a powerful library
for creating live-updating user interfaces, its public API and semantics are different with the goal of providing
extensible and composable components through unified and consistent interface.

This documentation assumes familiarity with Blaze and its concepts of
[templates, template helpers, data contexts](http://docs.meteor.com/#/full/livehtmltemplates), and
[reactivity](http://docs.meteor.com/#/full/reactivity), but we will also turn some of those concepts around.
For a gentle introduction to Blaze Components see the [tutorial](http://components.meteor.com/).

A Blaze Component is defined as a class providing few methods Blaze Components system will call to render a
component and few methods which will be called through a lifetime of a component. See the [reference](#reference)
for the list of all methods used and/or provided by Blaze Components.

A basic component might look like the following (using the
[reactive-field](https://github.com/peerlibrary/meteor-reactive-field)) package as well).

```javascript
class ExampleComponent extends BlazeComponent {
  // Life-cycle hook to initialize component's state.
  onCreated() {
    // It is a good practice to always call super.
    super.onCreated();
    this.counter = new ReactiveField(0);
  }

  // Mapping between events and their handlers.
  events() {
    // It is a good practice to always call super.
    return super.events().concat({
      // You could inline the handler, but the best is to make
      // it a method so that it can be extended later on.
      'click .increment': this.onClick
    });
  }

  onClick(event) {
    this.counter(this.counter() + 1);
  }

  // Any component's method is available as a template helper in the template.
  customHelper() {
    if (this.counter() > 10) {
      return "Too many times";
    }
    else if (this.counter() === 10) {
      return "Just enough";
    }
    else {
      return "Click more";
    }
  }
}

// Register a component so that it can be included in templates. It also
// gives the component the name. The convention is to use the class name.
ExampleComponent.register('ExampleComponent');
```

```handlebars
<!-- By default a template with the component's name will be used for the content. -->
<template name="ExampleComponent">
  <button class="increment">Click me</button>
  {{! You can include subtemplates to structure your templates. }}
  {{> subTemplate}}
</template>

<!-- We use camelCase to distinguish it from the component's template. -->
<template name="subTemplate">
  {{! You can access component's properties. }}
  <p>Counter: {{counter}}</p>
  {{! And component's methods. }}
  <p>Message: {{customHelper}}</p>  
</template>
```

You can see how to [register a component](#user-content-reference_class_register), define a
[template](#user-content-reference_instance_template), define a [life-cycle hook](#life-cycle-hooks),
[event handlers](#user-content-reference_instance_events), and a custom helper as a component method.

All template helpers, methods, event handlers, life-cycle hooks have `this` bound to the component.

JavaScript and CoffeeScript support
-----------------------------------

While documentation is in ES2015, Blaze Components are designed to be
equally easy to use with vanilla JavaScript and CoffeeScript classes as well.

Example above in vanilla JavaScript:

```javascript
var ExampleComponent = BlazeComponent.extendComponent({
  onCreated: function () {
    ExampleComponent.__super__.onCreated.call(this);
    this.counter = new ReactiveField(0);
  },

  events: function () {
    return ExampleComponent.__super__.events.call(this).concat({
      'click .increment': this.onClick
    });
  },

  onClick: function (event) {
    this.counter(this.counter() + 1);
  },

  customHelper: function () {
    if (this.counter() > 10) {
      return "Too many times";
    }
    else if (this.counter() === 10) {
      return "Just enough";
    }
    else {
      return "Click more";
    }
  }
}).register('ExampleComponent');
```

Example in CoffeeScript:

```coffee
class ExampleComponent extends BlazeComponent
  @register 'ExampleComponent'

  onCreated: ->
    super
    @counter = new ReactiveField 0

  events: ->
    super.concat
      'click .increment': @onClick

  onClick: (event) ->
    @counter @counter() + 1

  customHelper: ->
    if @counter() > 10
      "Too many times"
    else if @counter() is 10
      "Just enough"
    else
      "Click more"
```

Accessing data context
----------------------

Blaze Components are designed around the separation of concerns known as
[model–view–controller](https://en.wikipedia.org/wiki/Model%E2%80%93view%E2%80%93controller) (MVC).
Controller and its logic is implemented through a component. View is described through a template. And model is provided
as a data context to a controller, a component.

Data context is often reactive. It often comes from a database using Meteor's reactive stack. Often as data context
changes, components stays rendered and just how it is rendered changes.

When accessing values in a template, first component methods are searched for a property (with possible
[mixins](#mixins-1)), then global template helpers, and lastly the data context.

You can provide a data context to a component when you are including it in the template.

Examples:

```handlebars
{{> MyComponent}}

{{#with dataContext}}
  {{> MyComponent}}
{{/with}}

{{#each documents}}
  {{> MyComponent}}
{{/each}}

{{> MyComponent dataContext}}

{{> MyComponent a='foo' b=helper}}
```

`dataContext`, `documents` and `helper` are template helpers, component's methods. If they are reactive, the data
context is reactive.

You can access provided data context in your component's code through reactive
[`data`](#user-content-reference_instance_data) and [`currentData`](#user-content-reference_instance_currentData)
methods. There is slight difference between those two. The former always returns component's data context, while
the latter returns the data context from where it was called. It can be different in template helpers and event
handlers.

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

Because [`data`](#user-content-reference_instance_data) and [`currentData`](#user-content-reference_instance_currentData)
are both component's methods you can access them in a template as well. This is useful when you want to access
a data context property which is shadowed by a component's method.

Example:

```handlebars
<template name="Colors">
  {{color}}
  {{#with color='blue'}}
    {{! If "color" is the component's method, this would resolve to the method, and not to the data context. }}
    {{color}}
    {{! If you want to make sure you are calling the component's method. }}
    {{component.color}}
    {{! To access the component's data context from an inner data context, use "data". }}
    {{data.color}}
    {{! Or first access the component. }}
    {{component.data.color}}
    {{! To access the current data context through the component method. }}
    {{currentData.color}}
    {{! Alternatively, you can also use keyword "this". }}
    {{this.color}}
  {{/with}}
</template>
```

*See [Spacebars documentation](https://github.com/meteor/meteor/blob/devel/packages/spacebars/README.md) for more
information how to specify and work with the data context in templates.*

*Specifying a data context to a component in the code will be provided through the
[`renderComponent`](#user-content-reference_instance_renderComponent) method which is not yet public.*

Passing arguments
-----------------

Blaze Components automatically instantiate an instance of a component when needed. In most cases you pass data to
a component as its data context, but sometimes you want to pass arguments to component's constructor. You can do
that as well with the special `args` syntax:

```handlebars
{{> MyComponent args 'foo' key='bar'}}
```

Blaze Components will call `MyComponent`'s constructor with arguments `foo` and `Spacebars.kw({key: 'bar'})`
when instantiating the component's class. Keyword arguments are wrapped into
[`Spacebars.kw`](https://github.com/meteor/meteor/blob/devel/packages/spacebars/README.md#helper-arguments).

Compare:

```handlebars
{{> MyComponent key='bar'}}
```

`MyComponent`'s constructor is called without any arguments, but the data context of a component is set to
`{key: 'bar'}`.

```handlebars
{{> MyComponent}}
```

`MyComponent`'s constructor is called without any arguments and the data context is kept as it is.

When you want to use a data context and when arguments depends on your use case and code structure. Sometimes your class
is not used only as a component and requires some arguments to the constructor.

A general rule of thumb is that if you want the component to persist while data used to render the component is changing,
use a data context. But if you want to reinitialize the component itself if your data changes, then pass that data
through arguments. Component is always recreated when any argument changes. In some way arguments configure the
life-long properties of a component, which then uses data context reactively when rendering.

Another look at it is from the MVC perspective. Arguments configure the controller (component), while data
context is the model. If data is coming from the database, it should probably be a data context.

*Passing arguments to a component method which returns a component to be included, something like
`{{> getComponent args 'foo' key='bar'}}` is
[not yet possible](https://github.com/peerlibrary/meteor-blaze-components/issues/12).*

Life-cycle hooks
----------------

There are multiple stages in the life of a component. In the common case it starts with a class which is
instantiated, rendered, and destroyed.

Life-cycle hooks are called in order:

1. Class [`constructor`](#user-content-reference_instance_constructor)
2. [`mixinParent`](#user-content-reference_instance_mixinParent) (mixins only) – called on a mixin after it has been
created to associate it with its component
3. [`onCreated`](#user-content-reference_instance_onCreated) – called once a component is being created before being
inserted into DOM
4. [`onRendered`](#user-content-reference_instance_onRendered) – called once a rendered component is inserted into DOM
5. [`onDestroyed`](#user-content-reference_instance_onDestroyed) – called once a component was removed from DOM and is
being destroyed

The suggested use is that most of the component related initialization should be in
[`onCreated`](#user-content-reference_instance_onCreated) and [`constructor`](#user-content-reference_instance_constructor)
should be used for possible other uses of the same class. [`constructor`](#user-content-reference_instance_constructor)
does receive [optional arguments](#passing-arguments) though.

[Mixins](#mixins-1) share life-cycle with the component and their life-cycle hooks are called automatically
by Blaze Components.

*Life-cycle of a component is is the common case linked with its life in the DOM. But you can create an instance of
a component which you can keep a reference to and reuse it multiple times, thus keeping its state between multiple
renderings. You can do this using the [`renderComponent`](#user-content-reference_instance_renderComponent) method
which is not yet public.*

Handling events
---------------

There are two ways to handle DOM events in Blaze Components. The first is by using
[event maps](#user-content-reference_instance_events) in a similar way how you would bind event handlers in Blaze
or jQuery.

The issue is that using event maps is error prone. Your selector can match too much, or too
little, especially when component's template is changed in the future. Furthermore, event maps invert the relationship
between templates and components. Observe how components provide template helpers to templates and how you define
in the template itself how those template helpers are mapped to the template. Logic stays in the component, but
where exactly the template helper is used is defined in the template. If you are modifying the template, you can
easily see how you have to move template helpers around to keep the template working. With event maps this is
inverted. You often have to define custom CSS classes to allow event handlers to be bound to the DOM element
and later on is unclear how those CSS classes are connected to the event handlers. If you are modifying the template
you have to be careful to maintain correct mapping of event handlers.

Blaze Components provide an alternative approach. You can define event handlers as component's methods and they
are available to you to bind them to DOM elements in the template directly. The recommended approach is to name event
handlers based on which element they are handling and not what they are doing:

```handlebars
<template name="ExampleComponent">
  <button onClick={{onButtonClick}}>Click me</button>
</template>
```

```javascript
class ExampleComponent extends BlazeComponent {
  onCreated() {
    super.onCreated();
    this.counter = new ReactiveField(0);
  }

  onButtonClick(event) {
    this.counter(this.counter() + 1);
    this.callFirstWith(this, 'onButtonClick', event);
  }

  customHelper() {
    if (this.counter() > 10) {
      return "Too many times";
    }
    else if (this.counter() === 10) {
      return "Just enough";
    }
    else {
      return "Click more";
    }
  }
}
```

It is important to use `onClick` and not `onclick` because only the former will be handled by Blaze Components
(and the latter will be passed on as it is).

Moreover, observe the [`callFirstWith`](#user-content-reference_instance_callFirstWith) call. This allows
[mixins](#mixins-1) to hook into the same event. Only the first resolved event handler with a given name is
called and any other event handlers with the same name are not called automatically for events bound in templates.

While it is recommended that you define only one event handler per event per element and then do multiple actions
inside the component's code, you can still use the following syntax to bind multiple event handlers:

```handlebars
<template name="ExampleComponent">
  <button onClick="{{onClick1}} {{onClick2}}">Click me</button>
</template>
```

If you do not provide the name of the event handler, the name of the event is used instead. This will call `onClick`
method on the component for every `click` event on the button:

```handlebars
<template name="ExampleComponent">
  <button onClick>Click me</button>
</template>
```

Furthermore, when using a template helper to return a
[dynamic set of attributes](https://github.com/meteor/meteor/blob/devel/packages/spacebars/README.md#dynamic-attributes),
if any of those attributes are named like an event, the value will be bound as a event handler (or multiple of those
if the value is an array):

```handlebars
<template name="ExampleComponent">
  <button {{attrs}}>Click me</button>
</template>
```

```javascript
class ExampleComponent extends BlazeComponent {
  /* ... */
  
  attrs() {
    return {
      onClick: this.onButtonClick,
      title: "Button title"
    }
  }
}
```

You can also pass custom arguments to the event handlers:

```handlebars
<template name="ExampleComponent">
  <button onClick={{onButtonClick 'first'}}>Click me</button>
  <button onClick={{onButtonClick 'second'}}>Click me</button>
</template>
```

```javascript
onButtonClick(event, argument) {
  this.counter(this.counter() + 1);
  this.callFirstWith(this, 'onButtonClick', event, argument);
}
```

Those arguments can even be reactive.

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
it is used (one with `customers`) stays the same. On the other hand, wrapping template content with a block
helper component does change what [`currentComponent`](#user-content-reference_instance_currentComponent) returns:
it returns the block helper component instance. In a way you can still access the block helper's data context
through its component's instance (and [`data`](#user-content-reference_instance_data)).

When working with block helper components it is important to remember: block helper's data context is hidden
when traversing the tree of data contexts, but the block helper's component is available in the component tree
as the parent of any components included inside the block helper's content, both the content of the
block helper's component itself, and the content wrapped with the block helper.

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

```javascript
class CaseComponent extends BlazeComponent {
  constructor(kwargs) {
    super();

    this.cases = kwargs.hash;
  }

  renderCase() {
    let caseComponent = this.cases[this.data().case];
    if (!caseComponent) return null;
    return BlazeComponent.getComponent(caseComponent).renderComponent(this.currentComponent());
  }
}

CaseComponent.register('CaseComponent');
```

If you use `CaseComponent` now in the `{case: 'left'}` data context, a `LeftComponent`
component will be rendered. If you want to control in which data context `LeftComponent`
is rendered, you can specify data context as `{{> renderCase dataContext}}`.

*Example above is using [`renderComponent`](#user-content-reference_instance_renderComponent) method which is not yet public.*

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

```javascript
insertDOMElement(parent, node, before) {
  this.callFirstWith(this, 'insertDOMElement', parent, node, before);
  super.insertDOMElement(parent, node, before);
}

moveDOMElement(parent, node, before) {
  this.callFirstWith(this, 'moveDOMElement', parent, node, before);
  super.moveDOMElement(parent, node, before);
}

removeDOMElement(parent, node) {
  this.callFirstWith(this, 'removeDOMElement', parent, node);
  super.removeDOMElement(parent, node);
}
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

```javascript
class MyComponent extends BlazeComponent {
  mixins() {
    return [FirstMixin, new SecondMixin('foobar')];
  }

  alternativeName() {
    return this.callFirstWith(null, 'templateHelper');
  }

  values() {
    return 'a' + (this.callFirstWith(this, 'values') || '');
  }
}

MyComponent.register('MyComponent');

class FirstMixinBase extends BlazeComponent {
  templateHelper() {
    return "42";
  }

  extendedHelper() {
    return 1;
  }

  onClick() {
    if (this.values() !== this.valuesPrediction) throw new Error();
  }
}

class FirstMixin extends FirstMixinBase {
  extendedHelper() {
    return super.extendedHelper() + 2;
  }

  values() {
    return 'b' + (this.mixinParent().callFirstWith(this, 'values') || '');
  }

  dataContext() {
    return EJSON.stringify(this.mixinParent().data());
  }

  events() {
    return super.events().concat({
      'click': this.onClick
    });
  }

  onCreated() {
    super.onCreated();
    this.valuesPrediction = 'bc';
  }
}

class SecondMixin {
  constructor(name) {
    super();

    this.name = name;
  }

  mixinParent(mixinParent) {
    if (mixinParent) this._mixinParent = mixinParent;
    return this._mixinParent;
  }

  values() {
    return 'c' + (this.mixinParent().callFirstWith(this, 'values') || '');
  }
}
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

![Example mixins visualization](https://cdn.rawgit.com/peerlibrary/meteor-blaze-components/master/mixins.svg)

Full lines represent JavaScript inheritance. Dashed lines represent mixins relationships based
on the order of mixins specified.

Let's dissect the example.

As we can see all methods become template helpers and they are searched for in the normal order, first the
component, then mixins. On the diagram from left to right. First implementation found is called. If the
implementation wants to continue with the traversal it can do it by itself, probably using
[`callFirstWith`](#user-content-reference_instance_callFirstWith).

```javascript
mixins() {
  return [FirstMixin, new SecondMixin('foobar')];
}
```

We can see that mixins can be also already made instances. And that mixins do not have to extend
`BlazeComponent`. You get some methods for free, but you can use whatever you want to provide your features.

```javascript
alternativeName() {
  return this.callFirstWith(null, 'templateHelper');
}
```

Wa call [`callFirstWith`](#user-content-reference_instance_callFirstWith) with `null` which makes it traverse
the whole structure, the component and all mixins, when searching for the first implementation of `templateHelper`.

This allows us to not assume much about where the `templateHelper` is implemented. But be careful, if `templateHelper`
would do the same back, calling the `alternativeName` on the whole structure, you might get into an inifinite loop.

On the diagram of our example, this starts traversal on `MyComponent`, checking for the `templateHelper` on
its instance through JavaScript inheritance. Afterwards it moves to `FirstMixin`, looking at its
instance and its inheritance parent, where it finds it.

```javascript
values() {
  return 'a' + (this.callFirstWith(this, 'values') || '');
}
```

`values` method is passing `this` to [`callFirstWith`](#user-content-reference_instance_callFirstWith), signaling that only
mixins after the component should be traversed.

This is a general pattern for traversal which all `values` methods in this example use. Similar to how you would use
`super` call in inheritance. `values` methods add their own letter to the result and ask later mixins for possible
more content.

Calling [`callFirstWith`](#user-content-reference_instance_callFirstWith) in this way traverses the structure from
the left to the right on the diagram of our example, one implementation of `values` after another. First, `values`
method from `MyComponent` component is found. This method calls [`callFirstWith`](#user-content-reference_instance_callFirstWith)
which continues searching on `FirstMixin`, where it is found again. That method calls
[`callFirstWith`](#user-content-reference_instance_callFirstWith), which now finds `values` again, this time on
`SecondMixin`. Call from the `SecondMixin` does not find any more implementations. The result is thus:

```javascript
'a' + ('b' + ('c' + ''))
```

```javascript
onClick() {
  if (this.values() !== this.valuesPrediction) throw new Error();
}
```

Event handlers (and all other methods) have `this` bound to the mixin instance, not the component. Here we can see
how the event handler can access `values` and `valuesPrediction` on mixin's instance and how normal JavaScript
inheritance works between `FirstMixinBase` and `FirstMixin`.

Event handlers are independent from other mixins and the component's event handlers. They are attached to DOM in the
normal traversal order, first the component's, then mixins'. 

To control how events are propagated between the component and mixins you can use `event` object methods like
[`stopPropagation`](https://api.jquery.com/event.stopPropagation/) and
[`stopImmediatePropagation`](https://api.jquery.com/event.stopImmediatePropagation/).

```javascript
extendedHelper() {
  return super.extendedHelper() + 2;
}
```

You can use normal JavaScript inheritance in your mixins. On the diagram of our example `super` traverses
upwards.

```javascript
dataContext() {
  return EJSON.stringify(this.mixinParent().data());
}
```

To access the data context used for the component you first access the component, and then its data context.

```javascript
onCreated() {
  super.onCreated();
  this.valuesPrediction = 'bc';
}
```

Mixin's life-cycle matches that of the component and mixin's life-cycle hooks are automatically called by Blaze
Components when the component is [created](#user-content-reference_instance_onCreated),
[rendered](#user-content-reference_instance_onRendered), and [destroyed](#user-content-reference_instance_onDestroyed).
`this` is bound to the mixin instance.

```javascript
mixinParent(mixinParent) {
  if (mixinParent) this._mixinParent = mixinParent;
  return this._mixinParent;
}
```

Because `SecondMixin` does not extend `BlazeComponent` we have to provide the
[`mixinParent`](#user-content-reference_instance_mixinParent) method ourselves. It is called by the Blaze Components
as a setter to tell the mixin what its component instance is.

[`mixinParent`](#user-content-reference_instance_mixinParent) is a good place to add any dependencies to the
component your mixin might need. Extend it and your additional logic.

Example:

```javascript
mixinParent(mixinParent) {
  if (mixinParent) mixinParent.requireMixin(DependencyMixin);
  return super.mixinParent(mixinParent);
}
```

Don't forget to call `super`.

*See the [tutorial](http://components.meteor.com/#the-cooperation) for a more real example of mixins.*

Namespaces
----------

As your project grows and you are using more and more components, especially from 3rd party packages, flat
structure of components (and templates) might lead to interference. To address this issue Blaze Components
provide multi-level namespacing, with `.` character as a separator.

Example:

```javascript
class Buttons {}

Buttons.Red = class Red extends BlazeComponent {}

Buttons.Red.register('Buttons.Red');

Buttons.Blue = class Blue extends BlazeComponent {}

Buttons.Blue.register('Buttons.Blue');
```

```handlebars
{{> Buttons.Red}}
```

You do not have to export `Buttons` from your package for components to be available in templates throughout your
project. The registry of components is shared between all packages and the project. Even if you need to access a
component's class in your code, you can use `BlazeComponent.getComponent('Buttons.Red')` to access it.

Sometimes you want some non-component logic to be available together with your components. You can export
one symbol and nest components under it like in the example above, having access to both non-component logic
through that symbol, and components through Blaze Components registry.

On the other hand, you do not even have to [register](#user-content-reference_class_register) components to use them.
But then you have to get them into templates through some other means, for example, using some other component's
template helper (method). Remember though that Meteor has a global namespace for all template names, so probably you
want to use namespaced template names in large projects or packages you publish even if you are not registering
components.

Let's imagine thar your package exports `Buttons` class above. Then you could do:

```handlebars
<template name="OtherComponent">
  {{> renderButton}}
</template>
```

```javascript
class OtherComponent extends BlazeComponent {
  renderButton() {
    return Buttons.Red.renderComponent(this.currentComponent());
  }
}

OtherComponent.register('OtherComponent');
```

If you would leave your components registered, you could still do:

```javascript
renderButton() {
  return BlazeComponent.getComponent('Buttons.Red').renderComponent(this.currentComponent());
}
```

You do not even have to create a namespacing class in your code like we did in the example above. It does make the
code more readable and uniform, though.

How exactly you structure your code and components depends on various factors. Blaze Components provide multiple
ways to keep your components structured, tidy, and reusable.

*Example above is using [`renderComponent`](#user-content-reference_instance_renderComponent) method which is not yet public.*

Use with existing classes
-------------------------

Blaze Components are designed to work with existing class hierarchies. There are no restrictions on class constructor,
for example. In fact, Blaze Components can be seen simply as an API a class or object has to provide to be compatible
with the system. The easiest way to bootstrap your class hierarchy is to copy default implementations from
`BlazeComponent` to your class.

Example:

```javascript
for (let property in BlazeComponent) {
  if (property === '__super__') continue;
  YourBaseClass[property] = BlazeComponent[property];
}

for (let property in BlazeComponent.prototype) {
  if (property === 'constructor') continue;
  YourBaseClass.prototype[property] = BlazeComponent.prototype[property];
}
```

Reference
---------

### Class methods ###

<a name="reference_class_register"></a>
```javascript
static register(componentName, [componentClass])
```

Registers a new component with the name `componentName`. This makes it available in templates and elsewhere
in the component system under that name, and assigns the name to the component. If `componentClass`
argument is omitted, class on which `register` is called is used.

<a name="reference_class_getComponent"></a>
```javascript
static getComponent(componentName)
```

Retrieves the component class with `componentName` name. If such component does not exist, `null` is returned.

<a name="reference_class_getComponentForElement"></a>
```javascript
static getComponentForElement(domElement)
```

Returns a component instance used to render a particular DOM element, if it was rendered using Blaze Components.
Otherwise `null`.

<a name="reference_class_currentData"></a>
```javascript
static currentData([path], [equalsFunc])
```

This is a complementary class method to the [`currentData`](#user-content-reference_instance_currentData)
instance method. Use it when you do not have a component instance available.

<a name="reference_class_currentComponent"></a>
```javascript
static currentComponent()
```

This is a complementary class method to the [`currentComponent`](#user-content-reference_instance_currentComponent)
instance method. Use it when you do not have a component instance available.

<a name="reference_class_componentName"></a>
```javascript
static componentName([componentName])
```

When called without a `componentName` argument it returns the component name.

When called with a `componentName` argument it sets the component name.

*Setting the component name yourself is needed and required only for unregistered classes because
[`register`](#user-content-reference_class_register) sets the component name automatically otherwise. All component
should have a component name associated with them.*

<a name="reference_class_extendComponent"></a>
```javascript
static extendComponent([constructor], methods)
```

A helper method to extend a component into a new component when using vanilla JavaScript. It configures
prototype-based inheritance and assigns properties and values from `methods` to the prototype of the new component.
It accepts an optional `constructor` function to be used instead of a default one which just calls the constructor
of the parent component.

Inside a method you can use `this.constructor` to access the class. Parent class prototype is stored into `__super__`
for you convenience. You can use it to do `super` calls.

Example (in vanilla JavaScript):

```javascript
var OurComponent = MyComponent.extendComponent({
  values: function () {
    return '>>>' + OurComponent.__super__.values.call(this) + '<<<';
  }
});
```

In ES2015 and CoffeeScript you do not have to use `__super__` but can use languages' `super`.

### Instance methods ###

#### Event handlers ####

<a name="reference_instance_events"></a>
```javascript
events()
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

By default the method returns [preexisting event handlers](http://docs.meteor.com/#/full/template_events) defined on the
template returned from the [`template`](#user-content-reference_instance_template) method call.

Example:

```javascript
events() {
  return super.events().concat({
    'click': this.onClick,
    'click .accept': this.onAccept,
    'click .accept, focus .accept, keypress': this.onMultiple
  });
}
   
// Fires when any element is clicked.
onClick(event) {
}

// Fires when any element with the "accept" class is clicked.
onAccept(event) {
}

// Fires when 'accept' is clicked or focused, or a key is pressed.
onMultiple(event) {
}
```

Blaze Components make sure that event handlers are called bound with the component itself in `this`.
This means you can [normally access data context and the component itself](#access-to-data-context-and-components)
in the event handler.

When extending this method make sure to not forget about possible ancestor event handlers you can get through
the `super` call. Concatenate additional event handlers in subclasses and/or modify ancestor event handlers before
returning them all. This is also the reason why the method has to return an array. There might be multiple handlers
for the same event specification (eg., multiple handlers to handle `click` event) and we do not want them to be
clobbered.

Returned values from event handlers are ignored. To control how events are propagated you can use `event` object
methods like [`stopPropagation`](https://api.jquery.com/event.stopPropagation/) and
[`stopImmediatePropagation`](https://api.jquery.com/event.stopImmediatePropagation/).

It is a good practice to always call parent class method using `super`.

When [mixins](#mixins-1) provide event handlers, they are attached in order of mixins, with the component first.

*For more information about event maps, event handling, and `event` object, see [Blaze documentation](http://docs.meteor.com/#/full/eventmaps)
and [jQuery documentation](https://api.jquery.com/category/events/event-object/).*

#### DOM content ####

<a name="reference_instance_template"></a>
```javascript
template()
```

Extend this method and return the name of a [Blaze template](http://docs.meteor.com/#/full/templates_api) or template
object itself. By default it returns the [component name](#user-content-reference_class_componentName).

Template content will be used to render component's DOM content.

All component methods (properties, more precisely) are available in the template as template helpers. Template helpers
are bound to the component itself in `this`.

It is recommended that you use templates only to specify DOM content and that you do not define any template helpers,
event handlers, and life-cycle hooks on the template itself but instead define it at the component level. But to support
wrapping existing templates into Blaze Components so that you can extend or override their behavior, Blaze Components
reuse template helpers, event handlers, and life-cycle hooks from the template in a backwards compatible way. Preexisting
template helpers are searched if the component does not have a property with the requested helper name. Preexisting
event handlers are returned from the default [`events`](#user-content-reference_instance_events) method.
Default [life-cycle hooks](#life-cycle-hooks-1) methods call template's preexisting life-cycle hooks as well.

You can include other templates (to keep individual templates manageable) and components.

Convention is to name component templates the same as components, which are named the same as their classes.
And because components are classes, they start with an upper-case letter, TitleCase.

When [mixins](#mixins-1) provide `template` method, the component's default implementation first calls them
and only if mixins do not provide a template, [component name](#user-content-reference_class_componentName) is used
instead.

*See [Spacebars documentation](http://docs.meteor.com/#/full/templates_api) for more information about the template
language.*

#### Access to rendered content ####

<a name="reference_instance_$"></a>
```javascript
$(selector)
```

Finds all DOM elements matching the `selector` in the rendered content of the component, and returns them
as a [JQuery object](https://api.jquery.com/Types/#jQuery).

The component serves as the document root for the selector. Only elements inside the component and its
sub-components can match parts of the selector.

*Wrapper around [Blaze's `$`](http://docs.meteor.com/#/full/template_$).*

<a name="reference_instance_find"></a>
```javascript
find(selector)
```

Finds one DOM element matching the `selector` in the rendered content of the component, or returns `null`
if there are no such elements.

The component serves as the document root for the selector. Only elements inside the component and its
sub-components can match parts of the selector.

*Wrapper around [Blaze's `find`](http://docs.meteor.com/#/full/templƒate_find).*

<a name="reference_instance_findAll"></a>
```javascript
findAll(selector)
```

Finds all DOM element matching the `selector` in the rendered content of the component. Returns an array.

The component serves as the document root for the selector. Only elements inside the component and its
sub-components can match parts of the selector.

*Wrapper around [Blaze's `findAll`](http://docs.meteor.com/#/full/template_findAll).*

<a name="reference_instance_firstNode"></a>
```javascript
firstNode()
```

Returns the first top-level DOM node in the rendered content of the component.

The two nodes `firstNode` and `lastNode` indicate the extent of the rendered component in the DOM. The rendered
component includes these nodes, their intervening siblings, and their descendents. These two nodes are siblings
(they have the same parent), and `lastNode` comes after `firstNode`, or else they are the same node.

*Wrapper around [Blaze's `firstNode`](http://docs.meteor.com/#/full/template_firstNode).*

<a name="reference_instance_lastNode"></a>
```javascript
lastNode()
```

Returns the last top-level DOM node in the rendered content of the component.

*Wrapper around [Blaze's `lastNode`](http://docs.meteor.com/#/full/template_lastNode).*

#### Access to data context and components ####

<a name="reference_instance_data"></a>
```javascript
data([path], [equalsFunc])
```

Returns current component-level data context. A reactive data source.

If `path` is provided, it returns only the value under the path. It uses
[data-lookup](https://github.com/peerlibrary/meteor-data-lookup) package to resolve the path. Moreover, this limits
reactivity only to changes of that value and not the whole data context.

Use this to always get the top-level data context used to render the component.

<a name="reference_instance_currentData"></a>
```javascript
currentData([path], [equalsFunc])
```

Returns current caller-level data context. A reactive data source.

In [event handlers](#event-handlers) use `currentData` to get the data context at the place where the event originated (target context).
In template helpers `currentData` returns the data context where a template helper was called. In life-cycle
hooks [`onCreated`](#user-content-reference_instance_onCreated), [`onRendered`](#user-content-reference_instance_onRendered),
and [`onDestroyed`](#user-content-reference_instance_onDestroyed), it is the same as [`data`](#user-content-reference_instance_data).
Inside a template accessing the method as a template helper `currentData` is the same as `this`.

If `path` is provided, it returns only the value under the path. It uses
[data-lookup](https://github.com/peerlibrary/meteor-data-lookup) package to resolve the path. Moreover, this limits
reactivity only to changes of that value and not the whole data context.

When `path` is provided, current lexical scope is consulted first, before path is looked up
in the data context. This allows one to access lexical scope values from the component.
`currentData('foo.bar')` thus becomes the same as `{{foo.bar}}`, even when `foo` is defined
through the lexical scope. For example, to access current iteration index, you can do:

```handlebars
<template name="ListComponent">
  <ul>
    {{#each list}}
      <li class="{{oddOrEven}}">{{item}}</li>
    {{/each}}
  </ul>
</template>
```

```javascript
class ListComponent extends BlazeComponent {
  oddOrEven() {
    // @index is zero-based, so "odd" and "even" are swapped.
    return this.currentData('@index') % 2 === 0 ? 'odd' : 'even';
  }
}

ListComponent.register('ListComponent');
```

<a name="reference_instance_component"></a>
```javascript
component()
```

Returns the component. Useful in templates to get a reference to the component.

<a name="reference_instance_currentComponent"></a>
```javascript
currentComponent()
```

Similar to [`currentData`](#user-content-reference_instance_currentData), `currentComponent` returns current
caller-level component.

In most cases the same as `this` in the code, but in event handlers it returns the component at the place
where event originated (target component), and inside template content wrapped with a block helper component,
it is the closest block helper component.

<a name="reference_instance_componentName"></a>
```javascript
componentName()
```

This is a complementary instance method which calls [`componentName`](#user-content-reference_class_componentName)
class method.

<a name="reference_instance_parentComponent"></a>
```javascript
parentComponent()
```

Returns the component's parent component, if it exists, or `null`. A reactive data source.

The parent component is available only after the component has been [created](#user-content-reference_instance_onCreated),
and until is [destroyed](#user-content-reference_instance_onDestroyed).

<a name="reference_instance_childComponents"></a>
```javascript
childComponents([nameOrComponent])
```

Returns an array of component's children components. A reactive data source. The order of children components in the
array is arbitrary.

You can specify a component name, class, or instance to limit the resulting children to.

The children components are in the array only after they have been [created](#user-content-reference_instance_onCreated),
and until they are [destroyed](#user-content-reference_instance_onDestroyed).

<a name="reference_instance_childComponentsWith"></a>
```javascript
childComponentsWith(propertyOrMatcherOrFunction)
```

Returns an array of component's children components which match a `propertyOrMatcherOrFunction` predicate. A reactive
data source. The order of children components in the array is arbitrary.

A `propertyOrMatcherOrFunction` predicate can be:
* a property name string, in this case all children components which have a property with the given name are matched
* a matcher object specifying mapping between property names and their values, in this case all children components
which have all properties fom the matcher object equal to given values are matched (if a property is a function, it
is called and its return value is compared instead)
* a function which receives `(child, parent)` with `this` bound to `parent`, in this case all children components
for which the function returns a true value are matched

Examples:

```javascript
component.childComponentsWith('propertyName');
component.childComponentsWith({propertyName: 42});
component.childComponentsWith((child, parent) => child.propertyName === 42);
```

The children components are in the array only after they have been [created](#user-content-reference_instance_onCreated),
and until they are [destroyed](#user-content-reference_instance_onDestroyed).

#### Life-cycle hooks ####

<a name="reference_instance_constructor"></a>
```javascript
constructor([args...])
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

It is a good practice to always call parent class constructor using `super`.

After the component is instantiated, all its [mixins](#user-content-reference_instance_mixins) are instantiated as well.

<a name="reference_instance_onCreated"></a>
```javascript
onCreated()
```

Extend this method to do any initialization of the component before it is rendered for the first time. This is a better
place to do so than a class constructor because it does not depend on the component nature,
[mixins](#user-content-reference_instance_mixins) are already initialized, and most Blaze Components methods
work as expected (component was not yet rendered, so [DOM related methods](#access-to-rendered-content) do not yet work).

By default the method calls preexisting [`onCreated`](http://docs.meteor.com/#/full/template_onCreated) callbacks defined
on the template returned from the [`template`](#user-content-reference_instance_template) method call.

A recommended use is to initialize any reactive variables and subscriptions internal to the component.

Example:

```javascript
class ButtonComponent extends BlazeComponent {
  onCreated() {
    super.onCreated();

    this.color = new ReactiveField("Red");

    $(window).on('message.buttonComponent', (event) => {
      let color = event.originalEvent.data && event.originalEvent.data.color;
      if (color) this.color(color);
    });
  }

  onDestroyed() {
    super.onDestroyed();

    $(window).off('.buttonComponent');
  }
}

ButtonComponent.register('ButtonComponent');
```

```handlebars
<template name="ButtonComponent">
  <button>{{color}}</button>
</template>
```

You can now use [`postMessage`](https://developer.mozilla.org/en-US/docs/Web/API/Window/postMessage) to send messages
like `{color: "Blue"}` which would reactively change the label of the button.

It is a good practice to always call parent class method using `super`.

When [mixins](#mixins-1) provide `onCreated` method, they are called after the component in mixins order automatically.

<a name="reference_instance_onRendered"></a>
```javascript
onRendered()
```

This method is called once when a component is rendered into DOM nodes and put into the document for the first time.

By default the method calls preexisting [`onRendered`](http://docs.meteor.com/#/full/template_onRendered) callbacks
defined on the template returned from the [`template`](#user-content-reference_instance_template) method call.

Because your component has been rendered, you can use [DOM related methods](#access-to-rendered-content) to access
component's DOM nodes.

This is the place where you can initialize 3rd party libraries to work with the DOM content as well. Keep in
mind that interactions of a 3rd party library with Blaze controlled content might bring unintentional consequences
so consider reimplementing the 3rd party library as a Blaze Component instead.

It is a good practice to always call parent class method using `super`.

When [mixins](#mixins-1) provide `onRendered` method, they are called after the component in mixins order automatically.

<a name="reference_instance_onDestroyed"></a>
```javascript
onDestroyed()
```

This method is called when an occurrence of a component is taken off the page for any reason and not replaced
with a re-rendering.

By default the method calls preexisting [`onDestroyed`](http://docs.meteor.com/#/full/template_onDestroyed) callbacks
defined on the template returned from the [`template`](#user-content-reference_instance_template) method call.

Here you can clean up or undo any external effects of [`onCreated`](#user-content-reference_instance_onCreated)
or [`onRendered`](#user-content-reference_instance_onRendered) methods. See the example above.

It is a good practice to always call parent class method using `super`.

When [mixins](#mixins-1) provide `onDestroyed` method, they are called after the component in mixins order automatically.

<a name="reference_instance_isCreated"></a>
```javascript
isCreated()
```

Returns `true` if the component is created, possibly rendered, but not (yet) destroyed. Otherwise `false`. A reactive
data source.

<a name="reference_instance_isRendered"></a>
```javascript
isRendered()
```

Returns `true` if the component is rendered, but not (yet) destroyed. Otherwise `false`. A reactive data source.

<a name="reference_instance_isDestroyed"></a>
```javascript
isDestroyed()
```

Returns `true` if the component is destroyed. Otherwise `false`. If component was never created, it was also never
destroyed so initially the value is `false`. A reactive data source.

#### Programmatic rendering ####

Blaze Components are most often automatically rendered by Blaze when included in templates. In that case Blaze
takes care of the whole life-cycle of a component. Sometimes you might want to render a component programmatically
by yourself. In that case you have to keep in mind that Blaze Components are first rendered to Blaze template, which
are then rendered by Blaze to DOM.

<a name="reference_instance_renderComponent"></a>
```javascript
renderComponent(parentComponent)
```

Renders a Blaze Component into a Blaze template.

In the case you want to render the Blaze template further to DOM, you can use that Blaze template as an input to
[`Blaze.render`](http://docs.meteor.com/#/full/blaze_render) or
[`Blaze.renderWithData`](http://docs.meteor.com/#/full/blaze_renderwithdata).

Alternatively, you can return that Blaze template from a Blaze Component method to have a dynamic include in the
template:

```javascript
class DynamicComponent extends BlazeComponent {
  renderButton(parentComponent) {
    parentComponent ||= this.currentComponent();
    return ButtonComponent.renderComponent(parentComponent);
  }
}

DynamicComponent.register('DynamicComponent');
```

```handlebars
<template name="DynamicComponent">
  {{> renderButton}}
</template>
```

Notice the use of [`currentComponent`](#user-content-reference_instance_currentComponent) as the default
`parentComponent` argument.
This makes `parentComponent` be set to the correct value when `renderButton` method is used in a template include,
but also allows calling `renderButton` from elsewhere in the code with a provided `parentComponent`.

*Despite being documented, `renderComponent` method is not yet considered public and is subject to change.*

<a name="reference_instance_removeComponent"></a>
```javascript
removeComponent()
```

Removes rendered-to-DOM Blaze Component from DOM, destroys the underlying Blaze template, and destroys the Blaze Component.

You should call this method only if you have previously programmatically rendered the Blaze Component to DOM
(using [`Blaze.render`](http://docs.meteor.com/#/full/blaze_render) or
[`Blaze.renderWithData`](http://docs.meteor.com/#/full/blaze_renderwithdata)). In all other cases Blaze Components
will be removed from DOM and destroyed automatically by Blaze: you should not interfere with Blaze by removing
rendered DOM by yourself.

#### Utilities ####

<a name="reference_instance_autorun"></a>
```javascript
autorun(runFunc)
```

A version of [`Tracker.autorun`](http://docs.meteor.com/#/full/tracker_autorun) that is stopped when the component is
destroyed. You can use `autorun` from an [`onCreated`](#user-content-reference_instance_onCreated) or
[`onRendered`](#user-content-reference_instance_onRendered) life-cycle hooks to reactively update the DOM or the component.

<a name="reference_instance_subscribe"></a>
```javascript
subscribe(name, [args...], [callbacks])
```

A version of [`Meteor.subscribe`](http://docs.meteor.com/#meteor_subscribe) that is stopped when the component is
destroyed. You can use `subscribe` from an [`onCreated`](#user-content-reference_instance_onCreated) life-cycle hook to
specify which data publications this component depends on.

<a name="reference_instance_subscriptionsReady"></a>
```javascript
subscriptionsReady()
```

This method returns `true` when all of the subscriptions called with [`subscribe`](#user-content-reference_instance_subscribe)
are ready. Same as with all other methods, you can use it as a template helper in the component's template.

#### Low-level DOM manipulation hooks ####

<a name="reference_instance_insertDOMElement"></a>
```javascript
insertDOMElement(parent, node, before)
```

Every time Blaze wants to insert a new DOM element into the component's DOM content it calls this method. The default
implementation is that if `node` has not yet been inserted, it simply inserts the `node` DOM element under the
`parent` DOM element, as a sibling before the `before` DOM element, or as the last element if `before` is `null`.

You can extend this method if you want to insert the new DOM element in a different way, for example, by animating
it. Make sure you do insert it correctly because Blaze will expect it to be there afterwards.

If you want to use [mixins](#mixins-1) with the `insertDOMElement` method, you will have to extend the component's
method to call them in the way you want.

<a name="reference_instance_moveDOMElement"></a>
```javascript
moveDOMElement(parent, node, before)
```

Every time Blaze wants to move a DOM element to a new position between siblings it calls this method. The default
implementation is that if `node` has not yet been moved, it simply moves the `node` DOM element before the `before`
DOM element, or as the last element if `before` is `null`.

You can extend this method if you want to move the DOM element in a different way, for example, by animating
it. Make sure you do move it correctly because Blaze will expect it to be there afterwards.

If you want to use [mixins](#mixins-1) with the `moveDOMElement` method, you will have to extend the component's
method to call them in the way you want.

<a name="reference_instance_removeDOMElement"></a>
```javascript
removeDOMElement(parent, node)
```

Every time Blaze wants to remove a DOM element it calls this method. The default implementation is that
if `node` has not yet been removed, it simply removes the `node` DOM element.

You can extend this method if you want to remove the DOM element in a different way, for example, by animating
it. Make sure you do remove it correctly because Blaze will expect it to be removed afterwards.

If you want to use [mixins](#mixins-1) with the `removeDOMElement` method, you will have to extend the component's
method to call them in the way you want.

#### Mixins ####

<a name="reference_instance_mixins"></a>
```javascript
mixins()
```

Extend this method and return mixins for the component. Mixins can be components themselves, or just classes or
objects resembling them. No method is required for them, but methods will be called on them by Blaze
Components if they do exist.

The `mixins` method should return an array of registered component names, mixin classes, or mixin instances.
When component instance is created, all mixins' instances are created as well, if they were not already an
instance. Life-cycle of mixin instances matches that of the component.

<a name="reference_instance_getMixin"></a>
```javascript
getMixin(nameOrMixin)
```

Returns the component's mixin instance for a given name, class, or instance. Returns `null` if mixin is not found.

You can use it to check if a given mixin is used by the component.

<a name="reference_instance_getFirstWith"></a>
```javascript
getFirstWith(afterComponentOrMixin, propertyName)
```

It searchers the component and its mixins in order to find the first with a property `propertyName`. If
`afterComponentOrMixin` is `null`, it starts with the component itself. If `afterComponentOrMixin` is the component,
it starts with the first mixin. Otherwise it starts with the mixin after `afterComponentOrMixin`.

Returns `null` if such component or mixin is not found.

<a name="reference_instance_callFirstWith"></a>
```javascript
callFirstWith(afterComponentOrMixin, propertyName, [args...])
```

It searchers the component and its mixins in order to find the first with a property `propertyName`
and if it is a function, calls it with `args` as arguments, otherwise returns the value of the property.
If `afterComponentOrMixin` is `null`, it starts with the component itself. If `afterComponentOrMixin` is the component,
it starts with the first mixin. Otherwise it starts with the mixin after `afterComponentOrMixin`.

Returns `undefined` if such component or mixin is not found.

<a name="reference_instance_mixinParent"></a>
```javascript
mixinParent([mixinParent])
```

When called without a `mixinParent` argument it returns the mixin's parent. For a component instance's mixins it
returns the component instance.

When called with a `mixinParent` argument it sets the mixin's parent.

*Setting the mixin's parent is done automatically by calling this method when creating component's mixins. Extend
(or provide) this method if you want to do any action when parent is set, for example, add dependency mixins to
the parent using [`requireMixin`](#user-content-reference_instance_requireMixin). Make sure you call `super` as well.*

<a name="reference_instance_requireMixin"></a>
```javascript
requireMixin(nameOrMixin)
```

Adds a mixin after already added mixins. `nameOrMixin` can be a registered component name, mixin class, or
mixin instance.

If mixin is already added to the component the method does nothing.

Use `requireMixin` to manually add additional mixins after a component was created. For example, to add
dependencies required by automatically added mixins as a result of [`mixins`](#user-content-reference_instance_mixins).

Debugging
---------

To help with debugging, `BlazeComponentDebug` class is available. It contains class methods which can help
you introspect the current state of rendered components.

<a name="debugging_class_dumpComponentSubtree"></a>
```javascript
static dumpComponentSubtree(componentOrElement)
```

For a provided component instance or DOM element rendered by a component instance this class method prints
to the browser web console the tree structure of component instances for which the provided component instance
is an ancestor.

<a name="debugging_class_dumpComponentTree"></a>
```javascript
static dumpComponentTree(componentOrElement)
```

For a provided component instance or DOM element rendered by a component instance this class method prints
to the browser web console the whole tree structure of component instances in which the provided component
instance exists, from the root component instance down.

The provided component instance's name is underlined.

<a name="debugging_class_dumpAllComponents"></a>
```javascript
static dumpAllComponents()
```

Prints to the browser web console tree structures of all component instances currently rendered.

Related projects
----------------

* [meteor-template-extension](https://github.com/aldeed/meteor-template-extension) – provides various ways of copying
template helpers, event handlers and hooks between templates, allowing code reuse; a downside is that all copying
has to be taken care by a developer, often again and again, which becomes problematic as codebase grows; moreover,
without a clearly defined API community cannot build and share components
* [meteor-autoform](https://github.com/aldeed/meteor-autoform) – offers forms components through a sophisticated
use of templates and template helpers but it is still hard to compose behaviors you want beyond defining additional
input fields
* [Flow Components](https://github.com/meteorhacks/flow-components) – Flow Components are closer to
[React](https://facebook.github.io/react/) in the API design while Blaze Components are keeping familiar concepts
like data contexts and template helpers; Flow Components on the other hand still use template-based event handlers
while Blaze Components make them class methods so it easier to extend or override them through inheritance; in
general Blaze Components seems to be more OOP oriented; Flow Components are not yet officially released
* [ViewModel](http://viewmodel.meteor.com/) – instead of using event handlers to imperatively respond to user
interactions, ViewModel provides a two-way data binding between the model and DOM elements, like form input elements,
if data changes, form input element updates, if user modifies form input element, data is updated; alongside, ViewModel
can be used as components; Blaze Components are in this way lower level and they do not prescribe the way you
should be using data binding or event handlers, Blaze Components provide traditional DOM event handlers but you can
build on top of it data binding in the way you want, when you want/need it; you can even create a mixin for that and
reuse it across components; moreover, Blaze Components' main focus is on providing a good and extensible components
system and its power shows exactly because you can build such features through opt-in mixins
* [Blaze Plus](https://github.com/kadirahq/blaze-plus/) – Blaze Plus adds props and state management functionality to
Blaze, allowing one to pass data from the top to the bottom. These ideas are inspired by React.
A proposed way to limit rerenders in Blaze Components if one wants to pass data from the top to the bottom is to use
[computed field](https://github.com/peerlibrary/meteor-computed-field) package.
