Package.describe({
  name: 'peerlibrary:blaze-components',
  summary: "Reusable components for Blaze",
  version: '0.15.1',
  git: 'https://github.com/peerlibrary/meteor-blaze-components.git'
});

// Based on meteor/packages/templating/package.js.
Package.registerBuildPlugin({
  name: "compileBlazeComponentsTemplatesBatch",
  use: [
    'caching-html-compiler',
    'ecmascript',
    'templating-tools',
    'spacebars-compiler',
    'html-tools'
  ],
  sources: [
    'patch-compiling.js',
    'compile-templates.js'
  ]
});

Package.onUse(function (api) {
  api.versionsFrom('METEOR@1.0.3.1');

  // Core dependencies.
  api.use([
    'blaze',
    'coffeescript',
    'underscore',
    'tracker',
    'reactive-var',
    'ejson',
    'spacebars',
    'jquery'
  ]);

  // Based on meteor/packages/templating/package.js.
  api.addFiles('templating.js', 'client');
  api.export('Template', 'client');
  api.use('isobuild:compiler-plugin@1.0.0');
  api.imply(['meteor', 'blaze', 'spacebars'], 'client');

  // Internal dependencies.
  api.use([
    'peerlibrary:base-component@0.14.0'
  ]);

  // 3rd party dependencies.
  api.use([
    'peerlibrary:assert@0.2.5',
    'peerlibrary:reactive-field@0.1.0',
    'peerlibrary:computed-field@0.3.0',
    'peerlibrary:data-lookup@0.1.0'
  ]);

  api.export('BlazeComponent');
  // TODO: Move to a separate package. Possibly one with debugOnly set to true.
  api.export('BlazeComponentDebug');

  api.addFiles([
    'lookup.js',
    'attrs.js',
    'materializer.js',
    'lib.coffee',
    'debug.coffee'
  ]);

  api.addFiles([
    'client.coffee'
  ], 'client');
});

Package.onTest(function (api) {
  // Core dependencies.
  api.use([
    'coffeescript',
    'jquery',
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
    'peerlibrary:classy-test@0.2.25',
    'mquandalle:harmony@1.3.79',
    'peerlibrary:reactive-field@0.1.0',
    'peerlibrary:assert@0.2.5'
  ]);

  api.addFiles([
    'tests/tests.html',
    'tests/tests.coffee',
    'tests/tests.js',
    'tests/tests.next.js',
    'tests/tests.css'
   ], 'client');
});
