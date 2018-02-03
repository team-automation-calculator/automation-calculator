#! /usr/bin/env ruby

cmds = ARGF.argv
main_arg = cmds.shift || 'init'

help_hash = {
  build: {
    dev: 'Build docker containers for your development environment.',
    ci: 'Build docker containers to simulate the ci environment.'
  },
  init: 'Setup your development environment with docker.',
  rm: 'Remove running or stopped docker containers for a clean restart.',
  rmi: 'Remove the development docker image. ',
  start: 'Startup the application and it\'s dependencies in docker.',
  stop: 'Stop running docker containers.',
  test: 'Run all tests in the docker containers.'
}

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

def help(cmds, help_hash)
  sub_cmd = cmds.shift

  if sub_cmd.nil?
    help_hash.each_pair { |key, value| print_help_key_value(key, value) }
  elsif help_hash.key?(sub_cmd.to_sym)
    print_help_key_value(sub_cmd.to_sym, help_hash[sub_cmd.to_sym])
  else
    warn("Unrecognized command: #{sub_cmd}")
  end
end

def print_help_key_value(key, value)
  if value.class == Hash
    puts(" #{key}:")
    value.each_pair { |sub_key, sub_value| puts("   #{sub_key} - #{sub_value}") }
  else
    puts(" #{key} - #{value}")
  end
end

case main_arg
when 'build'
  build(cmds)
when 'init'
  build(cmds)
  exec('docker-compose run dev "/usr/src/app/bin/setup"')
when 'help'
  help(cmds, help_hash)
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
