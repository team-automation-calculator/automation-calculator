class DockerMachine
  Struct.new('EnvVarFile', :env_var, :file)
  CERT_ENV_VAR_FILE_STRUCTS =
    [
      Struct::EnvVarFile.new('DOCKER_CAPEM', 'ca.pem'),
      Struct::EnvVarFile.new('DOCKER_CERTPEM', 'cert.pem'),
      Struct::EnvVarFile.new('DOCKER_IDRSA', 'id.rsa')
    ].freeze

  class << self
    # Inability to upload files to be put into workspace on CircleCI
    # means I am trying to use this hacky method to get Docker machine certs on CircleCI.
    def build_docker_machine_certs_from_env_vars
      CERT_ENV_VAR_FILE_STRUCTS.each { |struct| build_file_from_env_var(struct) }
    end

    def build_file_from_env_var(struct)
      File.open(build_docker_machine_file_path(struct.file), 'w') { |file| file.write(ENV[struct.env_var]) }
    end

    def build_docker_machine_file_path(file)
      ENV['DOCKER_CERT_PATH'] + '/' + file
    end

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
