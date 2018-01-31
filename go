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

def create_host(cmds)
  name = cmds.shift || 'automation-calculator-host'
  aws_access_key_id = ENV['AWS_ACCESS_KEY_ID']
  aws_secret_access_key = ENV['AWS_SECRET_ACCESS_KEY']
  exec("docker-machine create --driver amazonec2 --amazonec2-access-key #{aws_access_key_id} --amazonec2-secret-key #{aws_secret_access_key} #{name}")
end

def deploy

end

def test(cmds)
  env = cmds.shift || 'dev'
  case env
    when 'dev'
      exec('docker-compose run dev rspec')
    when 'ci'
      exec('docker-compose run ci')
    else
      warn "Unrecognized command: #{env}"
  end
end

case main_arg
  when 'build'
    build(cmds)
  when 'create_host'
    create_host(cmds)
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
    test(cmds)
  else
    warn "Unrecognized command: #{main_arg}"
end
