class Dependencies
  class << self
    def install_docker_machine
      system('curl -L https://github.com/docker/machine/releases/download/v0.14.0/docker-machine-`uname -s`-`uname -m`
        > /tmp/docker-machine')
      system('sudo install /tmp/docker-machine /usr/local/bin/docker-machine')
    end
  end
end