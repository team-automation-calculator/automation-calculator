#! /usr/bin/env ruby

cmds = ARGF.argv
main_arg = cmds[0] || 'init'

case main_arg
  when 'init'
    puts 'placeholder for init command'
  when 'shell'
    exec('docker-compose run dev')
  when 'start'
    puts 'placeholder for start command'
  when 'stop'
    puts 'placeholder for stop command'
  when 'test'
    puts 'placeholder for test command'
  else
    warn "Unrecognized command: #{main_arg}"
end