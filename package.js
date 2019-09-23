Package.describe({
  name: 'peerlibrary:blaze-components',
  summary: "Reusable components for Blaze",
  version: '0.23.0',
  git: 'https://github.com/peerlibrary/meteor-blaze-components.git'
});

// Based on meteor/packages/templating/package.js.
Package.registerBuildPlugin({
  name: "compileBlazeComponentsTemplatesBatch",
  use: [
    'caching-html-compiler@1.1.3',
    'ecmascript@0.12.7',
    'templating-tools@1.1.2',
    'spacebars-compiler@1.1.3',
    'html-tools@1.0.11'
  ],
  sources: [
    'patch-compiling.js',
    'compile-templates.js'
  ]
});

Package.onUse(function (api) {
  api.versionsFrom('METEOR@1.8.1');

  // Core dependencies.
  api.use([
    'blaze@2.3.3',
    'coffeescript@2.4.1',
    'underscore',
    'tracker',
    'reactive-var',
    'ejson',
    'spacebars@1.0.15',
    'jquery@1.11.11'
  ]);

  // If templating package is among dependencies, we want it to be loaded before
  // us to not override our augmented functions. But we cannot make a real dependency
  // because of a plugin conflict (both us and templating are registering a *.html plugin).
  api.use([
    'templating@1.3.2'
  ], {weak: true});

  api.imply([
    'meteor',
    'blaze',
    'spacebars'
  ]);

  api.use('isobuild:compiler-plugin@1.0.0');

  // Internal dependencies.
  api.use([
    'peerlibrary:base-component@0.17.1'
  ]);

  // 3rd party dependencies.
  api.use([
    'peerlibrary:assert@0.3.0',
    'peerlibrary:reactive-field@0.6.0',
    'peerlibrary:computed-field@0.10.0',
    'peerlibrary:data-lookup@0.3.0'
  ]);

  api.export('Template');
  api.export('BlazeComponent');
  // TODO: Move to a separate package. Possibly one with debugOnly set to true.
  api.export('BlazeComponentDebug');

  api.addFiles([
    'template.coffee',
    'compatibility/templating.js',
    'compatibility/dynamic.html',
    'compatibility/dynamic.js',
    'compatibility/lookup.js',
    'compatibility/attrs.js',
    'compatibility/materializer.js',
    'lib.coffee',
    'debug.coffee'
  ]);

  api.addFiles([
    'client.coffee'
  ], 'client');

  api.addFiles([
    'server.coffee'
  ], 'server');
});

Package.onTest(function (api) {
  api.versionsFrom('METEOR@1.8.1');

  // Core dependencies.
  api.use([
    'coffeescript@2.4.1',
    'jquery@1.11.11',
    'reactive-var',
    'underscore',
    'tracker',
    'ejson',
    'random'
  ]);

  // Internal dependencies.
  api.use([
    'peerlibrary:blaze-components'
  ]);

  // 3rd party dependencies.
  api.use([
    'peerlibrary:classy-test@0.4.0',
    'peerlibrary:reactive-field@0.6.0',
    'peerlibrary:assert@0.3.0'
  ]);

  api.addFiles([
    'tests/tests.html',
    'tests/tests.coffee',
    'tests/tests.js',
    'tests/tests.es2015.js',
    'tests/tests.css'
   ]);
});
