# ./go compile, lint, format, test, validate and smoke, in a container.
require 'shellwords'
require './scripts/utils/compose_files'
require './scripts/utils/runner'
require './scripts/utils/tracked_env_files'

class Verify
  CONTAINERS = %w[dev ci].freeze
  # Ruby sources, including the ones without a .rb or .rake extension.
  RUBY_FILE_PATTERNS = %w[*.rb *.rake bin/* go Gemfile Rakefile config.ru Guardfile].freeze

  # container: where the smoke specs run; url: the SMOKE_TARGET_URL they
  # hit, none to leave it to the caller; keep_set: an explicit
  # SMOKE_TARGET_URL in the environment wins.
  SmokeTarget = Struct.new(:container, :url, :keep_set) do
    # What the smoke run adds to env: the target's URL, unless env's own wins.
    def env_for(env)
      return {} if url.nil? || (keep_set && env.key?('SMOKE_TARGET_URL'))

      { 'SMOKE_TARGET_URL' => url }
    end
  end
  SMOKE_TARGETS = {
    # Inside the docker-compose network, the dev service resolves by service
    # name on its internal port (not the host-mapped 3001).
    'dev' => SmokeTarget.new('dev', 'http://dev:3000', true),
    'staging' => SmokeTarget.new('dev', 'https://staging.automation-calculations.io', false),
    'prod' => SmokeTarget.new('dev', 'https://automation-calculations.io', false),
    'ci' => SmokeTarget.new('ci', nil, true)
  }.freeze

  def initialize(runner: Runner.new, env: ENV)
    @runner = runner
    @env = env
  end

  # Parse the given files (default: every tracked Ruby file) without
  # running them. `./go lint` runs this first.
  def compile(cmds)
    container = shift_container(cmds)
    files = cmds.empty? ? tracked_ruby_files : cmds
    run_in(container, "ruby scripts/utils/syntax_check.rb #{files.shelljoin}")
  end

  # No tracked .env file (checked on the host, where git is), then the
  # compile check, RuboCop, then Reek's code smells on the ./go scripts.
  def lint(cmds)
    container = shift_container(cmds)
    TrackedEnvFiles.new(runner: @runner).check
    compile([container])
    run_in(container, 'rubocop')
    run_in(container, 'reek scripts go')
  end

  # Apply RuboCop's safe autocorrections to the working tree.
  def autoformat
    run_in('dev', 'rubocop --autocorrect')
  end

  def rspec_test(cmds)
    container = cmds.shift || 'dev'
    return warn("Unrecognized command: #{container}") unless CONTAINERS.include?(container)

    # The whole suite, so spec/spec_helper.rb holds scripts/ to its coverage minimum.
    compose_run(container, "-e COVERAGE_GATE #{container} rspec", env: { 'COVERAGE_GATE' => '1' })
  end

  # Everything CI checks before it builds the production image.
  def validate(cmds)
    container = shift_container(cmds)
    lint([container])
    rspec_test([container])
  end

  def smoke_test(cmds)
    name = cmds.shift || 'dev'
    target = SMOKE_TARGETS[name]
    return warn("Unrecognized command: #{name}") unless target

    container = target.container
    compose_run(container, "-e SMOKE_TARGET_URL #{container} rspec spec/smoke/ --tag smoke",
                env: target.env_for(@env))
  end

  private

  # A leading dev|ci argument, taken off cmds; dev when there is none.
  def shift_container(cmds)
    CONTAINERS.include?(cmds.first) ? cmds.shift : 'dev'
  end

  def run_in(container, command)
    @runner.run("docker compose #{ComposeFiles.flags(container)} run --no-deps --rm #{container} #{command}",
                check: true)
  end

  # `docker compose run --rm` with the container's compose files; run_args
  # name the service and its command.
  def compose_run(container, run_args, env: {})
    @runner.run("docker compose #{ComposeFiles.flags(container)} run --rm #{run_args}", env: env, check: true)
  end

  def tracked_ruby_files
    @runner.output("git ls-files -z -- #{RUBY_FILE_PATTERNS.shelljoin}").split("\0")
  end
end
