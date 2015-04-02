Meteor.startup ->
  dimsum.configure
    words_per_sentence: [1, 4]
    flavor: 'jabberwocky'
    commas_per_sentence: [0, 0]

  Meteor.setInterval ->
    for demo in ['demo5', 'demo6']
      Values.upsert demo,
        # Remove the sentence dot and convert to lower case.
        $set: value: dimsum.sentence(1).slice(0, -1).toLowerCase()

  , 3000 # ms
