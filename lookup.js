/* This file backports Blaze lookup.js from Meteor 1.2 so that required
   Blaze features to support Blaze Components are available also in
   older Meteor versions.

   TODO: Remove this file eventually.
 */

// If `x` is a function, binds the value of `this` for that function
// to the current data context.
var bindDataContext = function (x) {
  if (typeof x === 'function') {
    return function () {
      var data = Blaze.getData();
      if (data == null)
        data = {};
      return x.apply(data, arguments);
    };
  }
  return x;
};

Blaze._getTemplateHelper = function (template, name, templateInstance) {
  // XXX COMPAT WITH 0.9.3
  var isKnownOldStyleHelper = false;

  if (template.__helpers.has(name)) {
    var helper = template.__helpers.get(name);
    if (helper === Blaze._OLDSTYLE_HELPER) {
      isKnownOldStyleHelper = true;
    } else if (helper != null) {
      return wrapHelper(bindDataContext(helper), templateInstance);
    } else {
      return null;
    }
  }

  // old-style helper
  if (name in template) {
    // Only warn once per helper
    if (! isKnownOldStyleHelper) {
      template.__helpers.set(name, Blaze._OLDSTYLE_HELPER);
      if (! template._NOWARN_OLDSTYLE_HELPERS) {
        Blaze._warn('Assigning helper with `' + template.viewName + '.' +
                    name + ' = ...` is deprecated.  Use `' + template.viewName +
                    '.helpers(...)` instead.');
      }
    }
    if (template[name] != null) {
      return wrapHelper(bindDataContext(template[name]), templateInstance);
    }
  }

  return null;
};

var wrapHelper = function (f, templateFunc) {
  // XXX COMPAT WITH METEOR 1.0.3.2
  if (! Blaze.Template._withTemplateInstanceFunc) {
    return Blaze._wrapCatchingExceptions(f, 'template helper');
  }

  if (typeof f !== "function") {
    return f;
  }

  return function () {
    var self = this;
    var args = arguments;

    return Blaze.Template._withTemplateInstanceFunc(templateFunc, function () {
      return Blaze._wrapCatchingExceptions(f, 'template helper').apply(self, args);
    });
  };
};

// templateInstance argument is provided to be available for possible
// alternative implementations of this function by 3rd party packages.
Blaze._getTemplate = function (name, templateInstance) {
  if ((name in Blaze.Template) && (Blaze.Template[name] instanceof Blaze.Template)) {
    return Blaze.Template[name];
  }
  return null;
};

Blaze.View.prototype.lookup = function (name, _options) {
  var template = this.template;
  var lookupTemplate = _options && _options.template;
  var helper;
  var boundTmplInstance;
  var foundTemplate;

  if (this.templateInstance) {
    boundTmplInstance = _.bind(this.templateInstance, this);
  }

  if (/^\./.test(name)) {
    // starts with a dot. must be a series of dots which maps to an
    // ancestor of the appropriate height.
    if (!/^(\.)+$/.test(name))
      throw new Error("id starting with dot must be a series of dots");

    return Blaze._parentData(name.length - 1, true /*_functionWrapped*/);

  } else if (template &&
             ((helper = Blaze._getTemplateHelper(template, name, boundTmplInstance)) != null)) {
    return helper;
  } else if (lookupTemplate &&
             ((foundTemplate = Blaze._getTemplate(name, boundTmplInstance)) != null)) {
    return foundTemplate;
  } else if (Blaze._globalHelpers[name] != null) {
    return wrapHelper(bindDataContext(Blaze._globalHelpers[name]),
      boundTmplInstance);
  } else {
    return function () {
      var isCalledAsFunction = (arguments.length > 0);
      var data = Blaze.getData();
      if (lookupTemplate && ! (data && data[name])) {
        throw new Error("No such template: " + name);
      }
      if (isCalledAsFunction && ! (data && data[name])) {
        throw new Error("No such function: " + name);
      }
      if (! data)
        return null;
      var x = data[name];
      if (typeof x !== 'function') {
        if (isCalledAsFunction) {
          throw new Error("Can't call non-function: " + x);
        }
        return x;
      }
      return x.apply(data, arguments);
    };
  }
  return null;
};
