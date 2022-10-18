# List all environment variables
class EnvironmentVariables
  EnvVar = Struct.new(:name, :value)

  # Note secret key base is only set as a mock for production
  # in the development environment,
  # and should never be the real production secret key base.
  PRODUCTION_VARS = [
    EnvVar.new('DOCKER_REPO_PASS', 'password'),
    EnvVar.new('DOCKER_REPO_USER', 'automationcalculator'),
    EnvVar.new('LOGSPOUT_TARGET_URL', 'logs4.papertrailapp.com'),
    EnvVar.new('POSTGRESS_PASSWORD', 'automation-calculator-production'),
    EnvVar.new(
      'SECRET_KEY_BASE', 'a588cf98f7e28d5024826d7142fe7b69582d9252218b2' \
                         '89df7b80366f9b19efdc56af2aa8820a8543cf2691313' \
                         '4014a41f3058ffdd5f3d5f1b93d964b3baba52'
    )
  ].freeze

  class << self
    def set_mock_production_vars
      PRODUCTION_VARS.each { |var| create_if_not_already_defined(var) }
    end

    def create_if_not_already_defined(var)
      if ENV.include? var.name
        puts "#{var.name} has already been set, not using mock for it."
      else
        ENV[var.name] = var.value
      end
    end
  end
end
