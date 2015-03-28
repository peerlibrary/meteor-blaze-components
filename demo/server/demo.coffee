Meteor.startup ->
  dimsum.configure
    words_per_sentence: [1, 4]
    flavor: 'jabberwocky'
    commas_per_sentence: [0, 0]

  Meteor.setInterval ->
    Values.upsert 'demo5',
      # Remove the sentence dot and convert to lower case.
      value: dimsum.sentence(1).slice(0, -1).toLowerCase()
  , 3000 # ms
