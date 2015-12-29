// Based on meteor/packages/templating/plugin/compile-templates.js.

Plugin.registerCompiler({
  extensions: ['html'],
  // TODO: Remove web arch only once server side support is in.
  archMatching: 'web',
  isTemplate: true
}, () => new CachingHtmlCompiler(
  "blaze-components-templating",
  TemplatingTools.scanHtmlForTags,
  TemplatingTools.compileTagsWithSpacebars
));
