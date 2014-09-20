@EventStore = new Meteor.Collection 'events'
@EventStore.allow(
  insert: (userId, doc) ->
    false
  update: (userId, doc, fields, modifier) ->
    false
  remove: (userId, doc) ->
    false
)

if Meteor.isServer

  execute = (id, fields) ->

    handlers = EventHandlers.getEventHandlers fields.name

    _.each(handlers, (handler) ->
      try
        (new handler(fields.eventData)).execute()
      catch error
        EventStore.update(id, {$set: {error: true, errorDetails: error}})

    )

    EventStore.update(id, $set: {executed: true})

  @EventStore.find({executed: false, error: false}, {limit: 1, sort: {executedAt: 1}}).observeChanges
    added: execute
    changed: (id, fields) ->
      if fields.executed
        execute id, fields
