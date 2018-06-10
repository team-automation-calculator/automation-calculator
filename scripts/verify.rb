# Spec and lint commands for docker containers
class Verify
  class << self
    def rspec_test(cmds)
      env = cmds.shift || 'dev'

      unless %w[dev ci].include?(env)
        warn "Unrecognized command: #{env}"
        return
      end

      exec(
        "docker-compose -f docker-compose.yml -f docker-compose.#{env}.yml " \
        "run --rm #{env} rspec"
      )
    end

    def lint(cmds)
      env = cmds.shift.to_s == 'ci' ? 'ci' : 'dev'

      exec(
        "docker-compose -f docker-compose.yml -f docker-compose.#{env}.yml "\
        "run --no-deps --rm #{env} rubocop"
      )
    end
  end
end
