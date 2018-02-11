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

def test(cmds)
  env = cmds.shift || 'dev'
  case env
  when 'dev'
    exec('docker-compose run dev rspec')
  when 'ci'
    exec('docker-compose -f docker-compose.yml -f docker-compose.ci.yml run ci')
  else
    warn "Unrecognized command: #{env}"
  end
end

def lint(cmds)
  env = cmds.shift.to_s

  if env == 'ci'
    exec('docker-compose -f docker-compose.yml -f docker-compose.ci.yml run ci rubocop')
  else
    exec('docker-compose run dev rubocop')
  end
end

case main_arg
when 'build'
  DockerBuild.build(cmds)
when 'create_host'
  create_host(cmds)
when 'help'
  HelpText.help(cmds)
when 'init'
  build(cmds)
  exec('docker-compose run dev "/usr/src/app/bin/setup"')
when 'lint'
  lint(cmds)
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
  test(cmds)
else
  warn "Unrecognized command: #{main_arg}"
end
