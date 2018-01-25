#! /usr/bin/env ruby

cmds = ARGF.argv
main_arg = cmds.shift || 'init'

def build(cmds)
  sub_cmd = cmds.shift || 'dev'

  case sub_cmd
  when 'dev'
    build_image('automationcalculator_dev:latest', 'Dockerfile.development')
  when 'ci'
    build_image('automationcalculator_ci:latest', 'Dockerfile.ci')
  else
    warn "Unrecognized command: #{sub_cmd}"
  end
end

def build_image(tag, file)
  username = ENV['USER']
  exec("docker build -t #{tag} -f #{file} --build-arg username=#{username}  .")
end

def test(cmds)
  env = cmds.shift || 'dev'
  case env
  when 'dev'
    exec('docker-compose run dev /bin/bash -c "rubocop; rspec"')
  when 'ci'
    exec('docker-compose run ci')
  else
    warn "Unrecognized command: #{env}"
  end
end

case main_arg
when 'build'
  build(cmds)
when 'init'
  build(cmds)
  exec('docker-compose run dev "/usr/src/app/bin/setup"')
when 'rm'
  # stop, then remove
  system('docker-compose down')
  exec('docker ps -aq | xargs docker rm')
when 'rmi'
  exec('docker rmi automationcalculator_dev:latest')
when 'shell'
  exec('docker-compose run dev /bin/bash')
when 'start'
  exec('docker-compose run dev rails s')
when 'stop'
  exec('docker-compose down')
when 'test'
  test(cmds)
else
  warn "Unrecognized command: #{main_arg}"
end
