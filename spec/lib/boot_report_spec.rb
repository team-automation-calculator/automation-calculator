require 'rails_helper'

RSpec.describe BootReport do
  let(:complete_env) do
    {
      'APP_HOSTNAME' => 'staging.example.io',
      'SHORT_COMMIT_HASH' => 'abc1234',
      'GOOGLE_ANALYTICS_TRACKING_ID' => 'G-TEST',
      'GITHUB_OAUTH_APP_ID' => 'id', 'GITHUB_OAUTH_APP_SECRET' => 'github-secret',
      'GOOGLE_OAUTH_APP_ID' => 'id', 'GOOGLE_OAUTH_APP_SECRET' => 'google-secret'
    }
  end
  let(:complete_config) { AppConfig.new(complete_env) }
  let(:logger) { instance_double(ActiveSupport::Logger, info: nil, warn: nil) }

  describe '.summary' do
    subject(:summary) do
      described_class.summary(config: complete_config,
                              hosts: %w[staging.example.io www.staging.example.io])
    end

    it { is_expected.to start_with('Boot: env=test commit=abc1234 ') }
    it { is_expected.to include("rails=#{Rails.version} ruby=#{RUBY_VERSION}") }
    it { is_expected.to include('hosts=staging.example.io,www.staging.example.io') }
    it { is_expected.to end_with('oauth=github:configured,google:configured') }

    it 'does not include secret values' do
      expect(summary).not_to match(/github-secret|google-secret/)
    end

    it 'says so when the commit, the hosts and a provider are missing' do
      config = AppConfig.new(complete_env.except('SHORT_COMMIT_HASH', 'GOOGLE_OAUTH_APP_SECRET'))
      expect(described_class.summary(config: config, hosts: []))
        .to include('commit=unknown', 'hosts=none',
                    'oauth=github:configured,google:missing')
    end
  end

  describe '.warnings' do
    it 'is empty in production when everything is set' do
      expect(described_class.warnings(config: complete_config, production: true)).to eq([])
    end

    it 'is empty outside production, whatever is missing' do
      expect(described_class.warnings(config: AppConfig.new({}), production: false)).to eq([])
    end

    it 'names every missing setting and its effect in production' do
      config = AppConfig.new(complete_env.except('APP_HOSTNAME', 'SHORT_COMMIT_HASH'))
      expect(described_class.warnings(config: config, production: true)).to contain_exactly(
        /\AAPP_HOSTNAME is unset: host authorization is off/,
        %r{\ASHORT_COMMIT_HASH is unset: /health cannot report the build}
      )
    end
  end

  describe '.log' do
    it 'writes the summary at info' do
      described_class.log(config: complete_config, logger: logger)
      expect(logger).to have_received(:info).with(/\ABoot: env=test /)
    end

    it 'writes each warning at warn' do
      config = AppConfig.new(complete_env.except('SHORT_COMMIT_HASH'))
      described_class.log(config: config, production: true, logger: logger)
      expect(logger).to have_received(:warn).with(/\ABoot: SHORT_COMMIT_HASH is unset/)
    end
  end

  describe '.boot' do
    let(:incomplete_config) { AppConfig.new(complete_env.except('APP_HOSTNAME')) }

    it 'does nothing outside a server' do
      described_class.boot(server: nil, config: incomplete_config,
                           production: true, logger: logger)
      expect(logger).not_to have_received(:info)
    end

    it 'logs and starts when a production server has everything required' do
      described_class.boot(server: 'constant', config: complete_config,
                           production: true, logger: logger)
      expect(logger).to have_received(:info).with(/\ABoot: /)
    end

    it 'refuses a production server missing a required setting' do
      expect do
        described_class.boot(server: 'constant', config: incomplete_config,
                             production: true, logger: logger)
      end.to raise_error(AppConfig::MissingError, /APP_HOSTNAME/)
    end

    it 'logs what is unset before refusing' do
      suppress(AppConfig::MissingError) do
        described_class.boot(server: 'constant', config: incomplete_config,
                             production: true, logger: logger)
      end
      expect(logger).to have_received(:warn).with(/\ABoot: APP_HOSTNAME is unset/)
    end

    it 'starts a development or test server whatever is missing' do
      expect do
        described_class.boot(server: 'constant', config: AppConfig.new({}),
                             production: false, logger: logger)
      end.not_to raise_error
    end
  end
end
