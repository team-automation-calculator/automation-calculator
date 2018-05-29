class Lifecycle
  COMMAND_HASH = {
    debug_production: -> { start_debug_production },
    dev: -> { system(build_dev_docker_compose_call) },
    production: -> { system('docker-compose -f docker-compose.yml -f docker-compose.production_http.yml up -d') }
  }.freeze

  class << self
    def build_dev_docker_compose_call
      uid = `id -u`.rstrip
      gid = `id -g`.rstrip
      "UID=#{uid} GID=#{gid} docker-compose -f docker-compose.yml -f docker-compose.dev.yml up -d dev"
    end

    def init(cmds)
      DockerBuild.build(cmds)
      exec('docker-compose -f docker-compose.yml -f docker-compose.dev.yml run dev "/usr/src/app/bin/setup"')
    end

    def rm
      # stop, then remove
      system('docker-compose down')
      exec('docker ps -aq | xargs docker rm')
    end

    def rmi
      exec('docker rmi automationcalculator_dev:latest')
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
      system('docker-compose -f docker-compose.yml -f docker-compose.production_http.yml up -d production')
    end

    def stop
      exec('docker-compose down --remove-orphans')
    end
  end
end
