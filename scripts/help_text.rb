# Help for using the main go script
class HelpText
  HELP_HASH = {
    build: {
      dev:
        '[Default] Build docker containers for your development environment.',
      ci: 'Build docker containers to simulate the ci environment.'
    }.freeze,
    db: {
      dev:
        '[Default] Connect to the application\'s database ' \
        'in the development environment with psql'
    }.freeze,
    create_host: 'Create a docker-machine host for the application.',
    init: 'Setup your development environment with docker.',
    push:
      'Push docker image to docker hub. ' \
      'Useful for debugging when CI fails to do this properly.',
    lint:
      'Use a linter on the application ' \
      'and test code to ensure code style is consistent.',
    rm: 'Remove running or stopped docker containers for a clean restart.',
    rmi: 'Remove the development docker image. ',
    shell: {
      dev: '[Default] Open a terminal inside of the development container.',
      production: 'Open a terminal container with the production image.'
    },
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
    test: 'Run all tests in the docker containers.'
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
