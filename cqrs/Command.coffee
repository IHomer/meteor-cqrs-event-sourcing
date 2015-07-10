class @Command

  constructor: (@data, @commandName) ->
    @user = ""
    if Meteor.isServer
      @user = this.userId
    else
      @user = Meteor.userId()

  insertEvent: (name) ->
    data = @data
    dataDB = EJSON.clone data
    dataDB = Commands.removeDotInKeys dataDB
    id = EventStore.insert
      createdAt: new Date
      command: @commandName
      name: name
      eventData: dataDB
      eventHandlers: []
    handlers = EventHandlers.getEventHandlers name
    _.each(handlers, (handler) ->
      try
        dataClone = EJSON.clone data
        (new handler(dataClone)).execute()
        EventStore.update(id, $push: {eventHandlers: {name: handler.prototype.constructor.name, executedAt: new Date()}})
      catch error
        fields =
          executedAt: new Date
          handler: handler.prototype.constructor.name
          message: error
          name: name
          eventData: dataDB
          eventId: id
          executed: false
          error: true
          retryCount: 0
        console.log fields
        EventErrorStore.insert(fields)
    )

# static part
class @Commands
  @commands = {}
  @validateCommand = (command) ->
    if command.prototype.execute instanceof Function
      true
    else
      throw new Meteor.Error "Command: "+ command.prototype.constructor.name + " does not has an execute function"


  @register = (name, command) ->
    @validateCommand command
    @commands[name] = command


  @createCommand = (command) ->
    if (!command.commandName)
      throw new Meteor.Error "Not a valid Command!"
    if (!@commands[command.commandName])
      throw new Meteor.Error "Command: "+ command.commandName + " is not Registered"
    _.extend(new @commands[command.commandName](), command)

  @removeDotInKeys = (obj, i) ->
    if i
      i++
    else
      i = 1
    if i > 100
      return obj
    for own key, value of obj
      if key.indexOf('.') > -1
        obj[key.replace(/\./g,'\uff0e')] = obj[key]
        delete obj[key]
      if value instanceof Object
        Commands.removeDotInKeys(value, i)
    obj

  @addDotInKeys = (obj, i) ->
    if i
      i++
    else
      i = 1
    if i > 100
      return obj
    for own key, value of obj
      if key.indexOf('\uff0e') > -1
        obj[key.replace(/\uff0e/g, '.')] = obj[key]
        delete obj[key]
      if value instanceof Object
        Commands.addDotInKeys(value, i)
    obj
