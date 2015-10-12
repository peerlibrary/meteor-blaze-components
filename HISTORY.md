## vNEXT

* Now multiple methods (`data`, `subscriptionsReady`, `$`, `find`, `findAll`, `firstNode`, `lastNode`) which access
  data context and DOM are additionally reactive any you can use them even before the component is rendered or even
  created and they will trigger invalidation when DOM, for example, becomes ready.
  Fixes [#62](https://github.com/peerlibrary/meteor-blaze-components/issues/62).
* Constructor is now never in a reactive context. Previously, constructor was sometimes in a reactive context. Same
  for `onDestroyed`.
* Made parent template/component available in the component constructor.
* Made correct data context available in the component constructor when passing arguments to the component.

## v0.13.0, 2015-Jun-24

* Fixed `getComponentForElement` to work correctly on DOM elements from non-template views.
* Started `HISTORY.md` file with the list of all changes.
