/* This file is a direct copy of Blaze lookup.js with modifications described
   in this pull request: https://github.com/meteor/meteor/pull/4036

   TODO: Remove this file once the pull request is merged in.
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

Blaze._getTemplateHelper = function (template, name) {
  // XXX COMPAT WITH 0.9.3
  var isKnownOldStyleHelper = false;

  if (template.__helpers.has(name)) {
    var helper = template.__helpers.get(name);
    if (helper === Blaze._OLDSTYLE_HELPER) {
      isKnownOldStyleHelper = true;
    } else {
      return helper;
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
    return template[name];
  }

  return null;
};

var wrapHelper = function (f, templateFunc) {
  // XXX COMPAT WITH 1.3.2
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

Blaze._getTemplate = function (name) {
  if (name in Blaze.Template) {
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
    return wrapHelper(bindDataContext(helper), boundTmplInstance);
  } else if (lookupTemplate && (foundTemplate = Blaze._getTemplate(name)) &&
             (foundTemplate instanceof Blaze.Template)) {
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
