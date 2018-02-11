class DockerMachine
  class << self
    def create_host(cmds)
      name = cmds.shift || 'automation-calculator-host'
      aws_access_key_id = ENV['AWS_ACCESS_KEY_ID']
      aws_secret_access_key = ENV['AWS_SECRET_ACCESS_KEY']
      exec("docker-machine create --driver amazonec2
        --amazonec2-access-key #{aws_access_key_id}
        --amazonec2-secret-key #{aws_secret_access_key} #{name}")
    end
  end
end
