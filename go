#! /usr/bin/env ruby

Dir['./scripts/*.rb'].each { |file| require file }

cmds = ARGF.argv
main_arg = cmds.shift || 'init'

COMMAND_HASH = {
  build: -> { DockerBuild.build(cmds) },
  create_host: -> { DockerMachine.create_host(cmds) },
  help: -> { HelpText.help(cmds) },
  init: -> { Lifecycle.init(cmds) },
  lint: -> { Verify.lint(cmds) },
  push: -> { DockerHub.push_to_docker_hub },
  rm: -> { Lifecycle.rm },
  rmi: -> { exec('docker rmi automationcalculator_dev:latest') },
  exec: -> { exec('docker-compose run dev /bin/bash') },
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
