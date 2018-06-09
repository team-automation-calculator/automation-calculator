# Using a shell in docker containers
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
      exec(
        'docker-compose -f docker-compose.yml -f docker-compose.dev.yml ' \
        'run dev /bin/bash'
      )
    end

    def production_shell
      exec(
        'docker-compose -f docker-compose.yml ' \
        '-f docker-compose.production_http.yml run production /bin/bash'
      )
    end
  end
end
