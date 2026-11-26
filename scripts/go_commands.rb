# The ./go command table: each name runs with the arguments after it. A new
# command is a line here and an entry in HelpText::HELP_HASH
# (spec/scripts/go_commands_spec.rb keeps the two in step).
require './scripts/utils/command_failure'

module GoCommands
  TABLE = {
    build: ->(cmds) { DockerBuild.new.build(cmds) },
    clean: ->(_cmds) { Lifecycle.new.clean },
    compile: ->(cmds) { Verify.new.compile(cmds) },
    db: ->(cmds) { DatabaseTerminal.new.connect(cmds) },
    format: ->(_cmds) { Verify.new.autoformat },
    'graphify-seed': ->(cmds) { exit(1) unless Graphify.new.seed(cmds) },
    'graphify-status': ->(cmds) { exit(GraphifyStatus.new.status(cmds)) },
    'graphify-update': ->(cmds) { Graphify.new.update(cmds) },
    help: ->(cmds) { HelpText.help(cmds) },
    init: ->(cmds) { Lifecycle.new.init(cmds) },
    lint: ->(cmds) { Verify.new.lint(cmds) },
    logs: ->(_cmds) { Logs.new.logs },
    push: ->(cmds) { DockerHub.new.push(cmds) },
    restart: ->(_cmds) { Lifecycle.new.restart },
    rm: ->(_cmds) { Lifecycle.new.rm },
    rmi: ->(_cmds) { Lifecycle.new.rmi },
    shell: ->(cmds) { Shell.new.shell(cmds) },
    smoke: ->(cmds) { Verify.new.smoke_test(cmds) },
    start: ->(cmds) { Lifecycle.new.start(cmds) },
    stop: ->(_cmds) { Lifecycle.new.stop },
    tag: ->(_cmds) { DockerHub.new.tag_latest_with_semver },
    test: ->(cmds) { Verify.new.rspec_test(cmds) },
    validate: ->(cmds) { Verify.new.validate(cmds) }
  }.freeze

  # argv's first word names the command (init when there is none). A
  # CommandFailure prints its message and exits 1.
  def self.run(argv, table: TABLE)
    name = argv.shift || 'init'
    command = table[name.to_sym]
    return warn("Unrecognized command: #{name}") unless command

    command.call(argv)
  rescue CommandFailure => e
    abort(e.message)
  end
end
