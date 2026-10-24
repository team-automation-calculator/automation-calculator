# Spec and lint commands for docker containers
require './scripts/utils/compose_files'

class Verify
  class << self
    def rspec_test(cmds)
      env = cmds.shift || 'dev'

      unless %w[dev ci].include?(env)
        warn "Unrecognized command: #{env}"
        return
      end

      system(
        "docker compose #{ComposeFiles.flags(env)} run --rm #{env} rspec",
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

      cmd = "docker compose #{ComposeFiles.flags(docker_env)} run --rm" \
            " -e SMOKE_TARGET_URL #{docker_env}" \
            ' rspec spec/smoke/ --tag smoke'
      system(cmd, exception: true)
    end

    def lint(cmds)
      env = cmds.shift.to_s == 'ci' ? 'ci' : 'dev'

      system(
        "docker compose #{ComposeFiles.flags(env)} " \
        "run --no-deps --rm #{env} rubocop",
        exception: true
      )
    end

    private

    def setup_smoke_url(arg)
      if arg.empty? || arg == 'dev'
        # Default to the compose dev service, but honor an explicit override.
        ENV['SMOKE_TARGET_URL'] ||= SMOKE_URLS['dev']
      elsif SMOKE_URLS.key?(arg)
        ENV['SMOKE_TARGET_URL'] = SMOKE_URLS[arg]
      elsif arg != 'ci'
        warn "Unrecognized command: #{arg}"
        return false
      end
      true
    end
  end
end
