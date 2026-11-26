require 'allowed_hosts'
require 'app_config'

# What this process booted with, for the first lines of a new pod's log:
# enough to tell which build is running and whether the environment gave
# it what it needs, without opening a shell in the pod. Names and
# presence only; no secret values. The names themselves live in
# AppConfig (lib/app_config.rb).
module BootReport
  module_function

  # Only a server reports its environment: rake tasks, the console and
  # the asset precompile in the image build boot the app too, without
  # most of AppConfig set. In production (staging and prod both run
  # RAILS_ENV=production; development and test are never checked) a
  # server logs every unset setting at ERROR or WARN (see
  # AppConfig#unset) and keeps serving.
  def boot(server:, config: AppConfig.current,
           production: Rails.env.production?, logger: Rails.logger)
    return unless server

    log(config: config, production: production, logger: logger)
  end

  def log(config: AppConfig.current, production: Rails.env.production?,
          logger: Rails.logger)
    logger.info(summary(config: config))
    problems(config: config, production: production).each do |level, lines|
      lines.each { |line| logger.public_send(level, "Boot: #{line}") }
    end
  end

  def summary(config: AppConfig.current, hosts: AllowedHosts.list)
    'Boot: ' \
      "env=#{Rails.env} commit=#{config.short_commit_hash || 'unknown'} " \
      "rails=#{Rails.version} ruby=#{RUBY_VERSION} " \
      "log_level=#{Rails.application.config.log_level} " \
      "hosts=#{hosts.join(',').presence || 'none'} " \
      "oauth=#{oauth_status(config)}"
  end

  # { error: [lines], warn: [lines] }, one line per unset setting, naming
  # it and what breaks; never a value. Development and test run without
  # these on purpose, so only production is checked.
  def problems(config:, production:)
    return { error: [], warn: [] } unless production

    config.unset.transform_values do |unset|
      unset.map { |name, effect| "#{name} is unset: #{effect}" }
    end
  end

  def oauth_status(config)
    AppConfig::OAUTH_CREDENTIALS.keys.map do |provider|
      "#{provider}:#{config.oauth_configured?(provider) ? 'configured' : 'missing'}"
    end.join(',')
  end
end
