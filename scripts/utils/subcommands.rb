require './scripts/help_text'

# Runs the subcommand named by a command's first argument, or its default.
# An unknown name prints the command's help and a warning.
module Subcommands
  # table: subcommand name (a Symbol) => callable.
  def self.dispatch(cmds, table, default:, help:)
    name = (cmds.shift || default).to_sym
    action = table[name]
    return action.call if action

    HelpText.help([help])
    puts
    warn("Unrecognized command: #{name}")
  end
end
