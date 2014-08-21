@EventStore = new Meteor.Collection 'events',
  schema: new SimpleSchema(
    executedAt:
      type: Date,
      label: 'Created At'

    name:
      type: String,
      label: 'Event Name'

    eventData:
      type: Object
      blackbox: true
      label: 'Event data'

    executed:
      type: Boolean,
      label: 'Already executed'

    error:
      type: Boolean,
      label: 'Execution resulted in an error'
      optional: true
      defaultValue: false

    errorDetails:
      type: Object
      label: 'Execution error details'
      blackbox: true
      optional: true

    retryCount:
      type: Number
      label: 'Retry Counter'
      defaultValue: 0

  )
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
        data = Commands.addDotInKeys fields.eventData
        (new handler(data)).execute()
        EventStore.update(id, $set: {executed: true})
      catch error
        console.log error
        err = {}
        err.handler = handler.eventName
        err.message = error
        #errorString = JSON.parse JSON.stringify err
        EventStore.update(id, {$set: {error: true, errorDetails: err}, $inc: {retryCount: 1}})
    )

  findNotExecuted = () ->
    try
      EventStore.find({executed: false, error: false}, {limit: 10, sort: {executedAt: 1}}).observeChanges
        added: execute
        changed: execute
    catch error
      console.log 'findNotExecuted: ' + error
      findNotExecuted

  Meteor.setTimeout(findNotExecuted, 10000)

  retryError = () ->
    try
      events = EventStore.find({executed: false, error: true, retryCount: { $lt: 5}}, {limit: 10, sort: {retryCount: 1, executedAt: 1}}).fetch()
      _.each(events, (event) ->
        execute(event._id, event)
      )
    catch error
      console.log 'retryError: ' + error

  Meteor.setInterval(retryError, 1000)