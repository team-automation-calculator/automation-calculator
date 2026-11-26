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
        'Build for linux/amd64 and linux/arm64 using docker buildx ' \
        '(applies to any subcommand). ' \
        'Images are cached in the buildx builder for later pushing ' \
        '(./go push --multi-platform).',
      '--no-cache': 'Disable Docker layer caching (applies to any subcommand).'
    }.freeze,
    db: {
      dev:
        '[Default] Connect to the application\'s database ' \
        'in the development environment with psql'
    }.freeze,
    clean:
      'Remove all docker containers, images, and volumes for a full reset.',
    compile: {
      dev:
        '[Default] Check that Ruby files parse (ruby -c) in the development ' \
        'container. Pass file paths to check only those; ' \
        'the default is every tracked Ruby file.',
      ci: 'Run the same check in the ci container.'
    }.freeze,
    format:
      'Apply RuboCop safe autocorrections in the development container.',
    'graphify-seed':
      'In a git worktree, copy the main checkout\'s knowledge graph ' \
      '(graphify-out/) and refresh its code layer to this branch. ' \
      'Does nothing in the main checkout. Flags: --force, --no-update, --quiet.',
    'graphify-status':
      'How far the knowledge graph is behind HEAD, and which documents ' \
      'wait for /graphify --update (exit 0 current, 3 behind, 1 no graph). ' \
      '--brief prints one line only when it is behind.',
    'graphify-update':
      'Refresh the knowledge graph\'s code layer to HEAD (AST only, no LLM, ' \
      'no Docker). Does nothing without a graph, in CI or a cloud session, ' \
      'or when the main checkout is not on main.',
    init: 'Setup your development environment with docker.',
    lint: {
      dev:
        '[Default] Run the compile check, then RuboCop, ' \
        'in the development container.',
      ci: 'Run the compile check, then RuboCop, in the ci container.'
    }.freeze,
    logs: 'Tail logs from the dev container.',
    push: {
      prod:
        '[Default] Push the production image to Docker Hub ' \
        '(:latest and :semver tags).',
      ci:
        'Push the CI image to Docker Hub (:latest and :semver tags).',
      base:
        'Push the base image to Docker Hub.',
      '--multi-platform':
        'Push linux/amd64 and linux/arm64 images to Docker Hub ' \
        'using docker buildx (applies to any subcommand). ' \
        'Slow: the non-native architecture is built under emulation.',
      '--digest-only':
        'Build for this machine\'s own architecture and push the image ' \
        'untagged, recording its digest in tmp/digests/. ' \
        'CI runs this once per architecture on native runners.',
      '--manifest':
        'Join the amd64 and arm64 images recorded in tmp/digests/ into ' \
        'one multi-arch manifest and tag it (:latest and :semver tags).'
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
        'Set SMOKE_TARGET_URL to override the default ' \
        '(http://dev:3000, the compose dev service).',
      ci:
        'Run smoke tests in the ci container. ' \
        'Set SMOKE_TARGET_URL to target a specific environment.',
      staging:
        'Run smoke tests against ' \
        'staging (https://staging.automation-calculations.io).',
      prod:
        'Run smoke tests against ' \
        'production (https://automation-calculations.io).'
    }.freeze,
    test: {
      dev: '[Default] Run the RSpec suite in the development container.',
      ci: 'Run the RSpec suite in the ci container.'
    }.freeze,
    validate: {
      dev:
        '[Default] Run lint, then test, in the development container. ' \
        'Changes nothing.',
      ci: 'Run lint, then test, in the ci container.'
    }.freeze
  }.freeze

  class << self
    # Every command with no argument, else the one named.
    def help(cmds)
      name = cmds.shift
      return HELP_HASH.each_pair { |key, value| print_help_key_value(key, value) } if name.nil?

      entry = HELP_HASH[name.to_sym]
      entry ? print_help_key_value(name, entry) : warn("Unrecognized command: #{name}")
    end

    def print_help_key_value(key, value)
      if value.instance_of?(Hash)
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
