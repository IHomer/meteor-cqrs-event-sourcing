Meteor.methods(
  executeCommand: (command) ->
    @unblock()
    if command.commandName?
      c = Commands.createCommand(command)
      c.execute()
    else
      _.each command, (it) ->
        c = Commands.createCommand(it)
        c.execute()
)