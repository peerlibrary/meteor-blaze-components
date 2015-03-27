Package.describe({
  name: 'peerlibrary:blaze-components',
  summary: "Components for Blaze",
  version: '0.1.0',
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
