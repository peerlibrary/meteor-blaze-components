Session.setDefault 'language', 'es2015'

Template.registerHelper 'isES2015', ->
  Session.equals 'language', 'es2015'

Template.registerHelper 'isJavaScript', ->
  Session.equals 'language', 'javascript'

Template.registerHelper 'isCoffeeScript', ->
  Session.equals 'language', 'coffeescript'

Template.languageSwitch.events
  'click a': (event, template) ->
    event.preventDefault()
    Session.set 'language', $(event.target).text()
    Tracker.afterFlush ->
      Prism.highlightAll()
    return

Template.languageChooser.events
  'change #languageChooser': (event, template) ->
    event.preventDefault()
    Session.set 'language', $(event.target).val()
    Tracker.afterFlush ->
      Prism.highlightAll()
    return

Meteor.startup ->
  Tracker.afterFlush ->
    Prism.highlightAll()
