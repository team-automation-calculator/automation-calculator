class Lifecycle
  COMMAND_HASH = {
    debug_production: -> { start_debug_production },
    dev: -> { system('docker-compose up -d dev') },
    production: -> { system('docker-compose -f docker-compose.yml -f docker-compose.production_http.yml up -d') }
  }.freeze

  class << self
    def init(cmds)
      DockerBuild.build(cmds)
      exec('docker-compose run dev "/usr/src/app/bin/setup"')
    end

    def rm
      # stop, then remove
      system('docker-compose down')
      exec('docker ps -aq | xargs docker rm')
    end

    def start(cmds)
      sub_cmd = cmds.shift || 'dev'

      if COMMAND_HASH.key? sub_cmd.to_sym
        COMMAND_HASH[sub_cmd.to_sym].call
      else
        HelpText.help(['start'])
        puts
        warn("Unrecognized command: #{sub_cmd}")
      end
    end

    def start_debug_production
      EnvironmentVariables.set_mock_production_vars
      system('docker-compose -f docker-compose.yml -f docker-compose.production_http.yml up -d')
    end

    def stop
      exec('docker-compose down --remove-orphans')
    end
  end
end
