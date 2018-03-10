class Lifecycle
  COMMAND_HASH = {
    dev: 'docker-compose up -d dev',
    production: 'docker-compose -f docker-compose.production_http.yml up -d'
  }.freeze

  class << self
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
  end
end
