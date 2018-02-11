#! /usr/bin/env ruby

Dir['./scripts/*.rb'].each { |file| require file }

cmds = ARGF.argv
main_arg = cmds.shift || 'init'

def create_host(cmds)
  name = cmds.shift || 'automation-calculator-host'
  aws_access_key_id = ENV['AWS_ACCESS_KEY_ID']
  aws_secret_access_key = ENV['AWS_SECRET_ACCESS_KEY']
  exec("docker-machine create --driver amazonec2
        --amazonec2-access-key #{aws_access_key_id}
        --amazonec2-secret-key #{aws_secret_access_key} #{name}")
end

case main_arg
when 'build'
  DockerBuild.build(cmds)
when 'create_host'
  create_host(cmds)
when 'help'
  HelpText.help(cmds)
when 'init'
  DockerBuild.build(cmds)
  exec('docker-compose run dev "/usr/src/app/bin/setup"')
when 'lint'
  Verify.lint(cmds)
when 'rm'
  # stop, then remove
  system('docker-compose down')
  exec('docker ps -aq | xargs docker rm')
when 'rmi'
  exec('docker rmi automationcalculator_dev:latest')
when 'shell'
  exec('docker-compose run dev /bin/bash')
when 'start'
  exec('docker-compose up -d dev')
when 'stop'
  exec('docker-compose down')
when 'test'
  Verify.rspec_test(cmds)
else
  warn "Unrecognized command: #{main_arg}"
end
