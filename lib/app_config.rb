# The settings this app reads from its environment, in one place: each
# name, how loudly a production server reports it unset, and what breaks
# without it. Application code asks an AppConfig rather than reading ENV,
# so this file answers "what does production need set?".
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
# Nothing here stops the app: reading a value never raises, and a
# production server (staging and prod) logs what is unset at boot and
# keeps serving (BootReport.boot, config/initializers/boot_report.rb).
class AppConfig
  OAUTH_CREDENTIALS = {
    github: %w[GITHUB_OAUTH_APP_ID GITHUB_OAUTH_APP_SECRET],
    google: %w[GOOGLE_OAUTH_APP_ID GOOGLE_OAUTH_APP_SECRET]
  }.freeze

  # Unset, these break something users see: a production server logs an
  # ERROR line for each one and keeps serving.
  IMPORTANT = {
    'APP_HOSTNAME' => 'host authorization is off and every OAuth sign-in ' \
                      'will be rejected as invalid_host; set it to the ' \
                      'public hostname (core-iac sets it from the ingress host)',
    'GITHUB_OAUTH_APP_ID' => 'sign-in with github will fail',
    'GITHUB_OAUTH_APP_SECRET' => 'sign-in with github will fail',
    'GOOGLE_OAUTH_APP_ID' => 'sign-in with google will fail',
    'GOOGLE_OAUTH_APP_SECRET' => 'sign-in with google will fail'
  }.freeze

  # Unset, these cost diagnostics or analytics only: a production server
  # logs a WARN line for each one.
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

  # Unset names with what breaks without each, by the level a production
  # server logs them at: IMPORTANT at :error, RECOMMENDED at :warn. Names
  # and effects only, never a value.
  def unset
    {
      error: IMPORTANT.reject { |name, _| read(name) },
      warn: RECOMMENDED.reject { |name, _| read(name) }
    }
  end

  private

  # A blank value counts as unset.
  def read(name)
    value = @env[name].to_s.strip
    value.empty? ? nil : value
  end
end
