#! /usr/bin/env ruby

cmds = ARGF.argv
main_arg = cmds[0] || 'init'

case main_arg
  when 'build'
    exec('docker build -t automationcalculator_dev:latest -f Dockerfile.development .')
  when 'init'
    puts 'placeholder for init command'
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
    puts 'placeholder for test command'
  else
    warn "Unrecognized command: #{main_arg}"
end