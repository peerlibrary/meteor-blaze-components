// Based on meteor/packages/templating/plugin/compile-templates.js.

Plugin.registerCompiler({
  extensions: ['html'],
  isTemplate: true
}, () => new CachingHtmlCompiler(
  "blaze-components-templating",
  TemplatingTools.scanHtmlForTags,
  TemplatingTools.compileTagsWithSpacebars
));
