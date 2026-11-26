# Raised by a ./go command that cannot finish. GoCommands.run prints the
# message and exits 1, so the command itself never ends the process.
class CommandFailure < StandardError; end
