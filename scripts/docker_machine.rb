# Create a docker host
class DockerMachine
  class << self
    def create_host(cmds)
      name = cmds.shift || "automation-calculator-host-#{Time.now.strftime("%Y-%m-%d")}"
      region = cmds.shift || 'us-west-1'
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
