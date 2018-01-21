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

case main_arg
  when 'build'
    build(cmds)
  when 'init'
    build(cmds)
    exec('docker-compose run dev "/usr/src/app/bin/setup"')
  when 'rm'
    exec('docker ps -aq | xargs docker rm')
  when 'rmi'
    exec('docker rmi automationcalculator_dev:latest')
  when 'shell'
    exec('docker-compose run dev')
  when 'start'
    puts 'placeholder for start command'
  when 'stop'
    exec('docker-compose down')
  when 'test'
    exec('docker-compose run test')
  else
    warn "Unrecognized command: #{main_arg}"
end
