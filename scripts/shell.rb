# Using a shell in docker containers
require './scripts/utils/get_uid.rb'

class Shell
  COMMAND_HASH = {
    ci: -> { ci_shell },
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

    def ci_shell
      exec(
        "USER=#{ENV.fetch('USER', 'circleci')} docker compose -f docker-compose.yml" \
        ' -f docker-compose.ci.yml' \
        ' run --entrypoint /bin/bash ci'
      )
    end

    def dev_shell
      exec(
        "UID=#{GetUID.read_uid} docker compose -f docker-compose.yml" \
        ' -f docker-compose.dev.yml' \
        ' run dev /bin/bash'
      )
    end

    def production_shell
      exec(
        'docker compose -f docker-compose.yml ' \
        '-f docker-compose.production_http.yml run production /bin/bash'
      )
    end
  end
end
