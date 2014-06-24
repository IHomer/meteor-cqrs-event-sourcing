class @Command

  constructor: (@data, @commandName) ->
    @user = ""
    if Meteor.isServer
      @user = this.userId
    else
      @user = Meteor.userId()

  insertEvent: (name) ->
    EventStore.insert
      executedAt: new Date
      name: name
      eventData: @data
      executed: false


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

