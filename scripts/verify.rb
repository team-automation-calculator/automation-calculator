# ./go compile, lint, format, test, validate and smoke, in a container.
require 'shellwords'
require './scripts/utils/compose_files'
require './scripts/utils/runner'

class Verify
  CONTAINERS = %w[dev ci].freeze
  # Ruby sources, including the ones without a .rb or .rake extension.
  RUBY_FILE_PATTERNS = %w[*.rb *.rake bin/* go Gemfile Rakefile config.ru Guardfile].freeze

  # container: where the smoke specs run; url: the SMOKE_TARGET_URL they
  # hit, none to leave it to the caller; keep_set: an explicit
  # SMOKE_TARGET_URL in the environment wins.
  SmokeTarget = Struct.new(:container, :url, :keep_set)
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

  def lint(cmds)
    container = shift_container(cmds)
    compile([container])
    run_in(container, 'rubocop')
  end

  # Apply RuboCop's safe autocorrections to the working tree.
  def autoformat
    run_in('dev', 'rubocop --autocorrect')
  end

  def rspec_test(cmds)
    container = cmds.shift || 'dev'
    return warn("Unrecognized command: #{container}") unless CONTAINERS.include?(container)

    compose_run(container, "#{container} rspec")
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

    compose_run(target.container, "-e SMOKE_TARGET_URL #{target.container} rspec spec/smoke/ --tag smoke",
                env: smoke_env(target))
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

  def smoke_env(target)
    return {} if target.url.nil? || (target.keep_set && @env.key?('SMOKE_TARGET_URL'))

    { 'SMOKE_TARGET_URL' => target.url }
  end

  def tracked_ruby_files
    @runner.output("git ls-files -z -- #{RUBY_FILE_PATTERNS.shelljoin}").split("\0")
  end
end
