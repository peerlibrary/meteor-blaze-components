Package.describe({
  name: 'peerlibrary:blaze-components',
  summary: "Reusable components for Blaze",
  version: '0.12.0',
  git: 'https://github.com/peerlibrary/meteor-blaze-components.git'
});

Package.onUse(function (api) {
  api.versionsFrom('METEOR@1.0.3.1');

  // Core dependencies.
  api.use([
    'blaze',
    'templating',
    'coffeescript',
    'underscore',
    'tracker',
    'reactive-var',
    'ejson',
    'spacebars'
  ]);

  // Internal dependencies.
  api.use([
    'peerlibrary:base-component@0.10.0'
  ]);

  // 3rd party dependencies.
  api.use([
    'peerlibrary:assert@0.2.5'
  ]);

  api.export('BlazeComponent');
  // TODO: Move to a separate package. Possibly one with debugOnly set to true.
  api.export('BlazeComponentDebug');

  api.addFiles([
    'lookup.js',
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
    'templating',
    'jquery',
    'reactive-var',
    'underscore',
    'tracker'
  ]);

  // Internal dependencies.
  api.use([
    'peerlibrary:blaze-components'
  ]);

  // 3rd party dependencies.
  api.use([
    'peerlibrary:classy-test@0.2.9',
    'mquandalle:harmony@1.3.79'
  ]);

  api.addFiles([
    'tests/tests.html',
    'tests/tests.coffee',
    'tests/tests.js',
    'tests/tests.next.js',
    'tests/tests.css'
   ], 'client');
});
