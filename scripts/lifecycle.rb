class Lifecycle
  COMMAND_HASH = {
    dev: 'docker-compose up -d dev',
    production: 'docker-compose -f docker-compose.yml -f docker-compose.production_http.yml up -d'
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
        system(COMMAND_HASH[sub_cmd.to_sym])
      else
        HelpText.help(cmds)
        puts
        warn("Unrecognized command: #{sub_cmd}")
      end
    end

    def stop
      exec('docker-compose down')
    end
  end
end
