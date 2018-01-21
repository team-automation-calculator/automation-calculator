#! /usr/bin/env ruby

cmds = ARGF.argv
main_arg = cmds[0] || 'init'

case main_arg
  when 'build'
    username = ENV['USER']
    exec("docker build -t automationcalculator_dev:latest -f Dockerfile.development --build-arg username=#{username}  .")
  when 'init'
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
    exec('docker-compose run dev rspec')
  else
    warn "Unrecognized command: #{main_arg}"
end
