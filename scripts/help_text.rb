# Help for using the main go script
class HelpText
  HELP_HASH = {
    build: {
      dev:
        '[Default] Build docker containers for your development environment.',
      ci: 'Build docker containers to simulate the ci environment.',
      base: 'Build the base docker image used by ci and development.',
      prod: 'Build the production docker image.',
      '--multi-platform':
        'Build for linux/amd64 and linux/arm64 using docker buildx (applies to any subcommand). ' \
        'Images are cached in the buildx builder for later pushing.',
      '--push':
        'Push the built image to Docker Hub immediately. ' \
        'Required with --multi-platform since multi-platform images cannot be loaded locally.',
      '--no-cache': 'Disable Docker layer caching (applies to any subcommand).'
    }.freeze,
    db: {
      dev:
        '[Default] Connect to the application\'s database ' \
        'in the development environment with psql'
    }.freeze,
    clean: 'Remove all docker containers, images, and volumes for a full reset.',
    init: 'Setup your development environment with docker.',
    lint: {
      dev: '[Default] Run RuboCop in the development container.',
      ci: 'Run RuboCop in the ci container.'
    }.freeze,
    logs: 'Tail logs from the dev container.',
    push: {
      prod:
        '[Default] Push the production image to Docker Hub (:latest and :semver tags).',
      ci:
        'Push the CI image to Docker Hub (:latest and :semver tags).',
      base:
        'Push the base image to Docker Hub.',
      '--multi-platform':
        'Push linux/amd64 and linux/arm64 images to Docker Hub using docker buildx ' \
        '(applies to any subcommand).'
    }.freeze,
    restart: 'Stop and restart docker containers.',
    rm: 'Remove running or stopped docker containers for a clean restart.',
    rmi: 'Remove the development docker image.',
    shell: {
      ci: 'Open a terminal inside of the CI container.',
      dev: '[Default] Open a terminal inside of the development container.',
      production: 'Open a terminal container with the production image.'
    }.freeze,
    start: {
      debug_production:
        'Simulate the production application, locally, to debug it.',
      dev:
        '[Default] Startup the application ' \
        'and it\'s dependencies in docker for the development environment.',
      production:
        'Startup the application ' \
        'and it\'s dependencies in docker for the production environment.'
    }.freeze,
    stop: 'Stop running docker containers.',
    tag:
      'Tag CI\'s docker image with semver. ' \
      'Useful for debugging when CI fails to do this properly.',
    smoke: {
      dev:
        '[Default] Run smoke tests against a live target. ' \
        'Set SMOKE_TARGET_URL to override the default (http://localhost:3001).',
      ci:
        'Run smoke tests in the ci container. ' \
        'Set SMOKE_TARGET_URL to target a specific environment (e.g. staging).'
    }.freeze,
    test: {
      dev: '[Default] Run the RSpec suite in the development container.',
      ci: 'Run the RSpec suite in the ci container.'
    }.freeze
  }.freeze

  class << self
    def help(cmds)
      sub_cmd = cmds.shift

      if sub_cmd.nil?
        HELP_HASH.each_pair { |key, value| print_help_key_value(key, value) }
      elsif HELP_HASH.key?(sub_cmd.to_sym)
        print_help_key_value(sub_cmd.to_sym, HELP_HASH[sub_cmd.to_sym])
      else
        warn("Unrecognized command: #{sub_cmd}")
      end
    end

    def print_help_key_value(key, value)
      if value.class == Hash
        puts(" #{key}:")
        value.each_pair do |sub_key, sub_value|
          puts("   #{sub_key} - #{sub_value}")
        end
      else
        puts(" #{key} - #{value}")
      end
    end
  end
end
