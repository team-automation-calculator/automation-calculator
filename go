#! /usr/bin/env ruby

Dir['./scripts/*.rb'].each { |file| require file }

cmds = ARGF.argv
main_arg = cmds.shift || 'init'

case main_arg
when 'build'
  DockerBuild.build(cmds)
when 'create_host'
  DockerMachine.create_host(cmds)
when 'help'
  HelpText.help(cmds)
when 'init'
  DockerBuild.build(cmds)
  exec('docker-compose run dev "/usr/src/app/bin/setup"')
when 'lint'
  Verify.lint(cmds)
when 'push'
  DockerHub.push_to_docker_hub
when 'rm'
  Lifecycle.rm
when 'rmi'
  exec('docker rmi automationcalculator_dev:latest')
when 'shell'
  exec('docker-compose run dev /bin/bash')
when 'start'
  Lifecycle.start(cmds)
when 'stop'
  Lifecycle.stop
when 'tag'
  DockerHub.tag_latest_with_semver
when 'test'
  Verify.rspec_test(cmds)
else
  warn "Unrecognized command: #{main_arg}"
end
