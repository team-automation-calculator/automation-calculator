require 'allowed_hosts'

# What this process booted with, for the first lines of a new pod's log:
# enough to tell which build is running and whether the environment gave
# it what it needs, without opening a shell in the pod. Names and
# presence only; no secret values.
module BootReport
  OAUTH_CREDENTIALS = {
    'github' => %w[GITHUB_OAUTH_APP_ID GITHUB_OAUTH_APP_SECRET],
    'google' => %w[GOOGLE_OAUTH_APP_ID GOOGLE_OAUTH_APP_SECRET]
  }.freeze

  UNSET_WARNINGS = {
    'APP_HOSTNAME' => 'host authorization is off and every OAuth sign-in ' \
                      'will be rejected as invalid_host',
    'SHORT_COMMIT_HASH' => '/health cannot report the build'
  }.freeze

  module_function

  def log(logger = Rails.logger)
    logger.info(summary)
    warnings.each { |warning| logger.warn("Boot: #{warning}") }
  end

  def summary(env: ENV, hosts: AllowedHosts.list)
    'Boot: ' \
      "env=#{Rails.env} commit=#{env['SHORT_COMMIT_HASH'].presence || 'unknown'} " \
      "rails=#{Rails.version} ruby=#{RUBY_VERSION} " \
      "log_level=#{Rails.application.config.log_level} " \
      "hosts=#{hosts.join(',').presence || 'none'} " \
      "oauth=#{oauth_status(env)}"
  end

  # Misconfigurations the app starts happily with and that otherwise
  # surface later as a user-facing failure. Development and test run
  # without these on purpose, so only production is checked.
  def warnings(env: ENV, production: Rails.env.production?)
    return [] unless production

    unset = UNSET_WARNINGS.select { |name, _| env[name].blank? }
    unset.map { |name, effect| "#{name} is unset: #{effect}" } +
      missing_oauth_providers(env).map do |provider|
        "#{provider} OAuth credentials are unset: sign-in with #{provider} will fail"
      end
  end

  def oauth_status(env)
    missing = missing_oauth_providers(env)
    OAUTH_CREDENTIALS.keys.map do |provider|
      "#{provider}:#{missing.include?(provider) ? 'missing' : 'configured'}"
    end.join(',')
  end

  def missing_oauth_providers(env)
    OAUTH_CREDENTIALS.reject { |_, names| names.all? { |name| env[name].present? } }.keys
  end
end
