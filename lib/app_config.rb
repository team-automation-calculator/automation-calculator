# The settings this app reads from its environment, in one place: each
# name, whether a production server can run without it, and what breaks
# when it is unset. Application code asks an AppConfig rather than
# reading ENV, so this file answers "what does production need set?".
#
# Deployed environments get every one of these from the core-iac Helm
# chart (helm/automation-calculator/templates/deployment.yaml).
#
# Framework settings stay where Rails and Puma read them and are not
# repeated here: DATABASE_URL (or DB_URL, config/database.yml),
# SECRET_KEY_BASE (Rails and config/initializers/devise.rb), RAILS_ENV,
# RAILS_LOG_LEVEL, RAILS_LOG_TO_STDOUT, RAILS_SERVE_STATIC_FILES
# (config/environments/production.rb), RAILS_MAX_THREADS,
# RAILS_MIN_THREADS and RAILS_SERVER_PORT (config/puma.rb).
#
# Reading a value never raises: rake tasks, the console and the asset
# precompile in the image build boot the app in production without most
# of these. Only a production server checks them, through validate!
# (BootReport.boot, config/initializers/boot_report.rb).
class AppConfig
  class MissingError < StandardError; end

  OAUTH_CREDENTIALS = {
    github: %w[GITHUB_OAUTH_APP_ID GITHUB_OAUTH_APP_SECRET],
    google: %w[GOOGLE_OAUTH_APP_ID GOOGLE_OAUTH_APP_SECRET]
  }.freeze

  # A production server refuses to start without these: each one unset
  # is a user-facing failure that would otherwise surface only later.
  REQUIRED = {
    'APP_HOSTNAME' => 'host authorization is off and every OAuth sign-in ' \
                      'will be rejected as invalid_host',
    'GITHUB_OAUTH_APP_ID' => 'sign-in with github will fail',
    'GITHUB_OAUTH_APP_SECRET' => 'sign-in with github will fail',
    'GOOGLE_OAUTH_APP_ID' => 'sign-in with google will fail',
    'GOOGLE_OAUTH_APP_SECRET' => 'sign-in with google will fail'
  }.freeze

  # A production server starts without these and logs a warning.
  RECOMMENDED = {
    'SHORT_COMMIT_HASH' => '/health cannot report the build',
    'GOOGLE_ANALYTICS_TRACKING_ID' => 'no page views reach Google Analytics'
  }.freeze

  def self.current
    new(ENV)
  end

  def initialize(env)
    @env = env
  end

  def app_hostname
    read('APP_HOSTNAME')
  end

  def short_commit_hash
    read('SHORT_COMMIT_HASH')
  end

  def google_analytics_tracking_id
    read('GOOGLE_ANALYTICS_TRACKING_ID')
  end

  # [id, secret] for :github or :google; nil for each one unset.
  def oauth_credentials(provider)
    OAUTH_CREDENTIALS.fetch(provider).map { |name| read(name) }
  end

  def oauth_configured?(provider)
    oauth_credentials(provider).all?
  end

  # Every unset REQUIRED or RECOMMENDED name, with what breaks without it.
  def unset
    REQUIRED.merge(RECOMMENDED).reject { |name, _| read(name) }
  end

  def validate!
    missing = REQUIRED.keys.reject { |name| read(name) }
    return if missing.empty?

    raise MissingError, "Missing required environment variables: #{missing.join(', ')}"
  end

  private

  # A blank value counts as unset.
  def read(name)
    value = @env[name].to_s.strip
    value.empty? ? nil : value
  end
end
