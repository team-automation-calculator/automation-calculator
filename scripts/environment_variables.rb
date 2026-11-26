# Mock production environment variables, for ./go start debug_production.
class EnvironmentVariables
  # The secret key base here is a mock for running production locally, and
  # must never be the real production secret key base.
  PRODUCTION_VARS = {
    'DOCKER_REPO_PASS' => 'password',
    'DOCKER_REPO_USER' => 'automationcalculator',
    'LOGSPOUT_TARGET_URL' => 'logs4.papertrailapp.com',
    'POSTGRESS_PASSWORD' => 'automation-calculator-production',
    'SECRET_KEY_BASE' => 'a588cf98f7e28d5024826d7142fe7b69582d9252218b2' \
                         '89df7b80366f9b19efdc56af2aa8820a8543cf2691313' \
                         '4014a41f3058ffdd5f3d5f1b93d964b3baba52'
  }.freeze

  # The mock variables env does not already set; the ones it does set are
  # named on stdout and kept.
  def self.missing_production_vars(env)
    set, missing = PRODUCTION_VARS.partition { |name, _| env.key?(name) }.map(&:to_h)
    set.each_key { |name| puts "#{name} has already been set, not using mock for it." }
    missing
  end
end
