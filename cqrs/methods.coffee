Meteor.methods(
  executeCommand: (command) ->
    check command, Object
    c = Command.createCommand(command)
    c.execute()
)
