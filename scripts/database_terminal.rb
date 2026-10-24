# Commands to connect to a container database
require './scripts/utils/compose_files'

class DatabaseTerminal
  COMMAND_HASH = {
    dev: -> { connect_dev_db }
  }.freeze

  class << self
    def connect(cmds)
      sub_cmd = cmds.shift || 'dev'

      if COMMAND_HASH.key? sub_cmd.to_sym
        COMMAND_HASH[sub_cmd.to_sym].call
      else
        HelpText.help(['db'])
        puts
        warn("Unrecognized command: #{sub_cmd}")
      end
    end

    def connect_dev_db
      exec("docker compose #{ComposeFiles.flags('dev')} run db_client")
    end
  end
end
