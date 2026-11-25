# Compile, lint, format and spec commands for docker containers
require 'shellwords'
require './scripts/utils/compose_files'

class Verify
  # Ruby sources without a .rb or .rake extension.
  RUBY_FILE_PATTERNS = %w[
    *.rb *.rake bin/* go Gemfile Rakefile config.ru Guardfile
  ].freeze

  class << self
    # Compile check: parse the given files (default: every tracked Ruby
    # file) without running them. `./go lint` runs this first.
    def compile(cmds)
      env = shift_env(cmds)
      files = cmds.empty? ? tracked_ruby_files : cmds

      run_in(env, "ruby scripts/utils/syntax_check.rb #{files.shelljoin}")
    end

    # Apply RuboCop's safe autocorrections to the working tree.
    def autoformat
      run_in('dev', 'rubocop --autocorrect')
    end

    # Everything CI checks before it builds the production image:
    # lint (compile check, then RuboCop), then the RSpec suite.
    def validate(cmds)
      env = shift_env(cmds)

      lint([env])
      rspec_test([env])
    end

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
      env = shift_env(cmds)

      compile([env])
      run_in(env, 'rubocop')
    end

    private

    # Takes a leading dev|ci argument off cmds; dev when there is none.
    def shift_env(cmds)
      %w[dev ci].include?(cmds.first) ? cmds.shift : 'dev'
    end

    def run_in(env, command)
      system(
        "docker compose #{ComposeFiles.flags(env)} " \
        "run --no-deps --rm #{env} #{command}",
        exception: true
      )
    end

    def tracked_ruby_files
      `git ls-files -z -- #{RUBY_FILE_PATTERNS.shelljoin}`.split("\0")
    end

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
