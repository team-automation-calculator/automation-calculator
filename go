#! /usr/bin/env ruby

cmds = ARGF.argv
main_arg = cmds[0] || 'init'

case main_arg
  when 'start'
    puts 'placeholder for start command'
  when 'stop'
    puts 'placeholder for stop command'
  when 'init'
    puts 'placeholder for init command'
  else
    warn "Unrecognized command: #{main_arg}"
end