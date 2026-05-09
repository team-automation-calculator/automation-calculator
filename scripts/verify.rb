# Spec and lint commands for docker containers
class Verify
  class << self
    def rspec_test(cmds)
      env = cmds.shift || 'dev'

      unless %w[dev ci].include?(env)
        warn "Unrecognized command: #{env}"
        return
      end

      system(
        "docker compose -f docker-compose.yml -f docker-compose.#{env}.yml " \
        "run --rm --remove-orphans #{env} rspec",
        exception: true
      )
    end

    SMOKE_URLS = {
      'prod' => 'https://automation-calculations.io',
      'staging' => 'https://staging.automation-calculations.io'
    }.freeze

    def smoke_test(cmds)
      arg = cmds.shift.to_s
      docker_env = arg == 'ci' ? 'ci' : 'dev'

      if SMOKE_URLS.key?(arg)
        ENV['SMOKE_TARGET_URL'] = SMOKE_URLS[arg]
      elsif !%w[dev ci].include?(arg) && !arg.empty?
        warn "Unrecognized command: #{arg}"
        return
      end

      system(
        "docker compose -f docker-compose.yml -f docker-compose.#{docker_env}.yml " \
        "run --rm --remove-orphans -e SMOKE_TARGET_URL #{docker_env} rspec spec/smoke/ --tag smoke",
        exception: true
      )
    end

    def lint(cmds)
      env = cmds.shift.to_s == 'ci' ? 'ci' : 'dev'

      system(
        "docker compose -f docker-compose.yml -f docker-compose.#{env}.yml "\
        "run --no-deps --rm --remove-orphans #{env} rubocop",
        exception: true
      )
    end
  end
end
