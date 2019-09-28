## vNEXT

## v0.23.0, 2019-Sep-22

* Updated dependencies to Meteor 1.8.1.

## v0.22.0, 2017-Jul-18

* Updated dependencies to newer versions.

## v0.21.0, 2017-Feb-06

* Provide internal `_renderComponentTo` method to allow serialization of Blaze's intermediate HTMLJS
  to a custom output. This allows, for example, serialization of Blaze Components to a plain-text rendering
  useful for plain-text e-mails.

## v0.20.0, 2016-Nov-01

* Updated code to support the new version of [computed field](https://github.com/peerlibrary/meteor-computed-field).

## v0.19.0, 2016-Aug-03

* Correctly cache `<head>` tag. Our workaround for the
  [Meteor issue](https://github.com/meteor/meteor/issues/5913) was breaking the cache
  because it made empty head to be cached even for the client target.

## v0.18.0, 2016-Mar-07

* Reverted searching of mixins of mixins. `getFirstWith` and `callFirstWith` traverse mixins, so this is
  enough.
* But `childComponentsWith` does check for mixin properties now, when properties are being matched.
* `component` now always resolves to the component, even when called from a mixin.
  Many methods which expect to operate on the component and previously failed when called on a mixin
  now automatically assure that they are called on the component, if it is available.
  This allows better code reuse between mixins and components.

## v0.17.0, 2016-Mar-03

* `getFirstWith` now accepts a predicate as well.
* When searching for a property on a component with `getFirstWith` and `callFirstWith`,
  we now traverse also mixins of mixins recursively.

## v0.16.2, 2015-Dec-31

* Fixed missing animation hooks in more cases.

## v0.16.1, 2015-Dec-31

* Blaze Components can now process `<body>` tags in the server side templates, and ignore
  `<head>` tags (which are already rendered on the server side).

## v0.16.0, 2015-Dec-30

* `this` inside a `component.autorun` computation is bound automatically to the component.
* `currentComponent` inside template content wrapped with a block helper component returns
  the closest block helper component.
* Block helpers components are correctly positioned inside the component tree.
  Fixes [#50](https://github.com/peerlibrary/meteor-blaze-components/issues/50) and
  [#51](https://github.com/peerlibrary/meteor-blaze-components/issues/51).
* Both `data` and `currentData` can now limit the returned value to a path by passing the
  path as an argument. Moreover, this limits reactivity only to changes of that value.
  Fixes [#101](https://github.com/peerlibrary/meteor-blaze-components/issues/101).
* Access to the lexical scope is now possible through `currentData` by passing lexical
  scope path as an argument.
  Fixes [#76](https://github.com/peerlibrary/meteor-blaze-components/issues/76).
* Allow binding of event handlers in templates instead of through event maps.
  Fixes [#99](https://github.com/peerlibrary/meteor-blaze-components/issues/99).
* Fixed missing animation hooks in some cases.
* Preliminary support for server side rendering.
  See [#110](https://github.com/peerlibrary/meteor-blaze-components/issues/110).

## v0.15.1, 2015-Oct-27

* Made sure backported Blaze lookup.js is not applied under Meteor 1.2. It is needed only for older Meteor versions
  and it interferes with Meteor 1.2.
  Fixes [#100](https://github.com/peerlibrary/meteor-blaze-components/issues/100).

## v0.15.0, 2015-Oct-23

* Renamed two methods once more. Fixes [#56](https://github.com/peerlibrary/meteor-blaze-components/issues/94).
  Renamed methods:
    * `childrenComponents` to `childComponents`
    * `childrenComponentsWith` to `childComponentsWith`

## v0.14.0, 2015-Oct-19

* Now multiple methods (`data`, `subscriptionsReady`, `$`, `find`, `findAll`, `firstNode`, `lastNode`) which access
  data context and DOM are additionally reactive any you can use them even before the component is rendered or even
  created and they will trigger invalidation when DOM, for example, becomes ready.
  Fixes [#62](https://github.com/peerlibrary/meteor-blaze-components/issues/62).
* Constructor is now never in a reactive context. Previously, constructor was sometimes in a reactive context. Same
  for `onDestroyed`.
* Made parent template/component available in the component constructor.
* Made correct data context available in the component constructor when passing arguments to the component.
* Added `removeComponent` method. Partially fixes
  [#36](https://github.com/peerlibrary/meteor-blaze-components/issues/36).
* Renamed few methods to more intuitive names and added deprecation warnings if you use a method with an old name.
  Methods with old names will be removed in a future version.
  Fixes [#56](https://github.com/peerlibrary/meteor-blaze-components/issues/56).
  Renamed methods:
    * `componentChildren` to `childrenComponents`
    * `componentChildrenWith` to `childrenComponentsWith`
    * `addComponentChild` to `addChildComponent`
    * `removeComponentChild` to `removeChildComponent`
    * `componentParent` to `parentComponent`
* Support extending existing Blaze templates. Now preexisting events and life-cycle hooks are available through default
  implementations of related Blaze Components methods. Preexisting template helpers are searched if a requested
  component instance method is not found.
  Fixes [#71](https://github.com/peerlibrary/meteor-blaze-components/issues/71).
* Made sure that reactive life-cycle variables are set before corresponding callbacks are called.

## v0.13.0, 2015-Jun-24

* Fixed `getComponentForElement` to work correctly on DOM elements from non-template views.
* Started `HISTORY.md` file with the list of all changes.
