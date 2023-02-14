#! /usr/bin/env ruby

Dir['./scripts/*.rb'].each { |file| require file }

cmds = ARGF.argv
main_arg = cmds.shift || 'init'

COMMAND_HASH = {
  build: -> { DockerBuild.build(cmds) },
  clean: -> { Lifecycle.clean },
  create_host: -> { DockerMachine.create_host(cmds) },
  db: -> { DatabaseTerminal.connect(cmds) },
  help: -> { HelpText.help(cmds) },
  init: -> { Lifecycle.init(cmds) },
  lint: -> { Verify.lint(cmds) },
  logs: -> { Logs.logs },
  push: -> { DockerHub.push_to_docker_hub },
  restart: -> { Lifecycle.restart },
  rm: -> { Lifecycle.rm },
  rmi: -> { Lifecycle.rmi },
  shell: -> { Shell.shell(cmds) },
  start: -> { Lifecycle.start(cmds) },
  stop: -> { Lifecycle.stop },
  tag: -> { DockerHub.tag_latest_with_semver },
  test: -> { Verify.rspec_test(cmds) }
}.freeze

if COMMAND_HASH.key? main_arg.to_sym
  COMMAND_HASH[main_arg.to_sym].call
else
  warn "Unrecognized command: #{main_arg}"
end
