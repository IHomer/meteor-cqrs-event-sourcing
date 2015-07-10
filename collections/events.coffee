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

if Meteor.isServer

  executeHandler = (id, fields) ->
    handler = EventHandlers.getEventHandlerByName fields.name, fields.handler
    if handler
      try
        data = Commands.addDotInKeys fields.eventData
        (new handler(data)).execute()
        EventStore.update(fields.eventId, $push: {eventHandlers: {name: handler.prototype.constructor.name, executedAt: new Date(), error: fields.message, retryCount: fields.retryCount+1}})
        EventErrorStore.remove id
      catch error
        fields.error = error
        console.log fields
        EventErrorStore.update(id, {$set: {error: true, message: error, executedAt: new Date()}, $inc: {retryCount: 1}})
    else
      console.log handler + ' NOT FOUND TO EXECUTE'

  findNotExecuted = () ->
    try
      EventErrorStore.find({executed: false, error: false}, {limit: 10, sort: {executedAt: 1}}).observeChanges
        added: executeHandler
    catch error
      console.log 'findNotExecuted: ' + error
      throw error

  retryError = () ->
    try
      events = EventErrorStore.find({executed: false, error: true, retryCount: { $lt: 5}}, {limit: 10, sort: {retryCount: 1, executedAt: 1}}).fetch()
      _.each(events, (event) ->
        EventErrorStore.update(event._id, {$set: {error: false}})
      )
    catch error
      console.log 'retryError: ' + error

  Meteor.startup ->
    Meteor.setTimeout(findNotExecuted, 10000)
    Meteor.setInterval(retryError, 5000)