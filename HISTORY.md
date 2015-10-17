## vNEXT

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

## v0.13.0, 2015-Jun-24

* Fixed `getComponentForElement` to work correctly on DOM elements from non-template views.
* Started `HISTORY.md` file with the list of all changes.
