# Selects the docker compose files for a `./go` command.
#
# Every command line is built from the base file plus one environment file
# (dev, ci, production_http). When an untracked docker-compose.local.yml
# exists in the current directory it is appended last, so it overrides
# the tracked files. See docker-compose.local.example.yml.
class ComposeFiles
  BASE_FILE = 'docker-compose.yml'.freeze
  LOCAL_FILE = 'docker-compose.local.yml'.freeze

  class << self
    def flags(env)
      files(env).map { |file| "-f #{file}" }.join(' ')
    end

    def files(env)
      list = [BASE_FILE, "docker-compose.#{env}.yml"]
      list << LOCAL_FILE if File.exist?(LOCAL_FILE)
      list
    end
  end
end
