# Create a docker host
class DockerMachine
  class << self
    def create_host(cmds)
      name = cmds.shift
      region = cmds.shift
      commands = [
        'docker-machine',
        'create',
        '--driver amazonec2',
        "--amazonec2-region #{region}",
        name
      ].join(' ')
      exec(commands)
    end
  end
end
