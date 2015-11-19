@EventStore = new Meteor.Collection Meteor.settings?.cqrs?.eventStore || "events"
@EventStore.allow(
  insert: (userId, doc) ->
    false
  update: (userId, doc, fields, modifier) ->
    false
  remove: (userId, doc) ->
    false
)

@EventErrorStore = new Meteor.Collection Meteor.settings?.cqrs?.eventErrorStore || "eventErrors"
@EventErrorStore.allow(
  insert: (userId, doc) ->
    false
  update: (userId, doc, fields, modifier) ->
    false
  remove: (userId, doc) ->
    false
)

