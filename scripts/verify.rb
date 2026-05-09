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
        "run --rm #{env} rspec",
        exception: true
      )
    end

    SMOKE_URLS = {
      'prod' => 'https://automation-calculations.io',
      'staging' => 'https://staging.automation-calculations.io',
      # Inside the docker-compose network, the dev service resolves
      # by service name on its internal port (not the host-mapped 3001).
      'dev' => 'http://dev:3000'
    }.freeze

    def smoke_test(cmds)
      arg = cmds.shift.to_s
      docker_env = arg == 'ci' ? 'ci' : 'dev'
      return unless setup_smoke_url(arg)

      cmd = 'docker compose -f docker-compose.yml' \
            " -f docker-compose.#{docker_env}.yml run --rm" \
            " -e SMOKE_TARGET_URL #{docker_env}" \
            ' rspec spec/smoke/ --tag smoke'
      system(cmd, exception: true)
    end

    def lint(cmds)
      env = cmds.shift.to_s == 'ci' ? 'ci' : 'dev'

      system(
        "docker compose -f docker-compose.yml -f docker-compose.#{env}.yml "\
        "run --no-deps --rm #{env} rubocop",
        exception: true
      )
    end

    private

    def setup_smoke_url(arg)
      if SMOKE_URLS.key?(arg)
        ENV['SMOKE_TARGET_URL'] = SMOKE_URLS[arg]
      elsif !%w[dev ci].include?(arg) && !arg.empty?
        warn "Unrecognized command: #{arg}"
        return false
      end
      true
    end
  end
end
