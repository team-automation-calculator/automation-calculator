require 'allowed_hosts'
require 'app_config'

# What this process booted with, for the first lines of a new pod's log:
# enough to tell which build is running and whether the environment gave
# it what it needs, without opening a shell in the pod. Names and
# presence only; no secret values. The names themselves live in
# AppConfig (lib/app_config.rb).
module BootReport
  module_function

  # Only a server reports and checks its environment: rake tasks, the
  # console and the asset precompile in the image build boot the app
  # too, without most of AppConfig set. In production a server missing a
  # required setting logs what is unset and then refuses to start, so a
  # rollout with a bad environment fails its readiness probe instead of
  # serving broken sign-ins.
  def boot(server:, config: AppConfig.current,
           production: Rails.env.production?, logger: Rails.logger)
    return unless server

    log(config: config, production: production, logger: logger)
    config.validate! if production
  end

  def log(config: AppConfig.current, production: Rails.env.production?,
          logger: Rails.logger)
    logger.info(summary(config: config))
    warnings(config: config, production: production)
      .each { |warning| logger.warn("Boot: #{warning}") }
  end

  def summary(config: AppConfig.current, hosts: AllowedHosts.list)
    'Boot: ' \
      "env=#{Rails.env} commit=#{config.short_commit_hash || 'unknown'} " \
      "rails=#{Rails.version} ruby=#{RUBY_VERSION} " \
      "log_level=#{Rails.application.config.log_level} " \
      "hosts=#{hosts.join(',').presence || 'none'} " \
      "oauth=#{oauth_status(config)}"
  end

  # Development and test run without these on purpose, so only
  # production is checked.
  def warnings(config:, production:)
    return [] unless production

    config.unset.map { |name, effect| "#{name} is unset: #{effect}" }
  end

  def oauth_status(config)
    AppConfig::OAUTH_CREDENTIALS.keys.map do |provider|
      "#{provider}:#{config.oauth_configured?(provider) ? 'configured' : 'missing'}"
    end.join(',')
  end
end
