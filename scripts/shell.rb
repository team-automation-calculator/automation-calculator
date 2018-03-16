class Shell
  COMMAND_HASH = {
    dev: -> { dev_shell },
    production: -> { production_shell }
  }.freeze

  class << self
    def shell(cmds)
      sub_cmd = cmds.shift || 'dev'

      if COMMAND_HASH.key? sub_cmd.to_sym
        COMMAND_HASH[sub_cmd.to_sym].call
      else
        HelpText.help(['shell'])
        puts
        warn("Unrecognized command: #{sub_cmd}")
      end
    end

    def dev_shell
      exec('docker-compose run dev /bin/bash')
    end

    def production_shell
      # exec('docker-compose run dev /bin/bash')
    end
  end
end
