Session.setDefault 'language', 'coffeescript'

Template.registerHelper 'isCoffeeScript', ->
  Session.equals 'language', 'coffeescript'

Template.registerHelper 'isJavaScript', ->
  Session.equals 'language', 'javascript'

Template.languageSwitch.events
  'click a': (event, template) ->
    event.preventDefault()
    Session.set 'language', $(event.target).text()
    Tracker.afterFlush ->
      Prism.highlightAll()
    return

Meteor.startup ->
  Tracker.afterFlush ->
    Prism.highlightAll()
