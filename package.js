Package.describe({
  name: 'blaze-components',
  version: '0.1.0'
});

Package.onUse(function (api) {
  api.versionsFrom('1.0.3.1');

  // Core dependencies.
  api.use([
    'templating',
    'coffeescript',
    'underscore',
    'tracker'
  ]);

  // 3rd party dependencies.
  api.use([
    'aldeed:template-extension@3.4.3'
  ]);

  api.export('BlazeComponent');

  // Client.
  api.addFiles([
    'lookup.js',
    'lib.coffee'
  ], 'client');
});
