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
  let(:logger) { instance_double(ActiveSupport::Logger, info: nil, warn: nil, error: nil) }

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

  describe '.problems' do
    it 'is empty in production when everything is set' do
      expect(described_class.problems(config: complete_config, production: true))
        .to eq(error: [], warn: [])
    end

    it 'is empty outside production, whatever is missing' do
      expect(described_class.problems(config: AppConfig.new({}), production: false))
        .to eq(error: [], warn: [])
    end

    it 'puts a missing APP_HOSTNAME or OAuth key under error, with its effect' do
      config = AppConfig.new(complete_env.except('APP_HOSTNAME', 'GOOGLE_OAUTH_APP_ID'))
      expect(described_class.problems(config: config, production: true)[:error]).to contain_exactly(
        /\AAPP_HOSTNAME is unset: host authorization is off/,
        /\AGOOGLE_OAUTH_APP_ID is unset: sign-in with google will fail/
      )
    end

    it 'puts a missing recommended setting under warn' do
      config = AppConfig.new(complete_env.except('SHORT_COMMIT_HASH'))
      expect(described_class.problems(config: config, production: true)[:warn])
        .to contain_exactly(%r{\ASHORT_COMMIT_HASH is unset: /health cannot report the build})
    end
  end

  describe '.log' do
    let(:half_set_config) do
      AppConfig.new(complete_env.except('APP_HOSTNAME', 'SHORT_COMMIT_HASH', 'GITHUB_OAUTH_APP_ID'))
    end

    it 'writes the summary at info' do
      described_class.log(config: complete_config, logger: logger)
      expect(logger).to have_received(:info).with(/\ABoot: env=test /)
    end

    it 'writes a missing APP_HOSTNAME at error in production' do
      described_class.log(config: half_set_config, production: true, logger: logger)
      expect(logger).to have_received(:error).with(/\ABoot: APP_HOSTNAME is unset/)
    end

    it 'writes a missing recommended setting at warn in production' do
      described_class.log(config: half_set_config, production: true, logger: logger)
      expect(logger).to have_received(:warn).with(/\ABoot: SHORT_COMMIT_HASH is unset/)
    end

    it 'writes no warn outside production' do
      described_class.log(config: AppConfig.new({}), production: false, logger: logger)
      expect(logger).not_to have_received(:warn)
    end

    it 'never writes a value, only names' do
      lines = []
      allow(logger).to receive(:error) { |line| lines << line }
      allow(logger).to receive(:warn) { |line| lines << line }
      described_class.log(config: half_set_config, production: true, logger: logger)
      expect(lines.join("\n")).not_to match(/github-secret|google-secret|staging\.example\.io/)
    end
  end

  describe '.boot' do
    let(:no_hostname_config) { AppConfig.new(complete_env.except('APP_HOSTNAME')) }
    let(:no_oauth_config) { AppConfig.new(complete_env.except('GITHUB_OAUTH_APP_SECRET')) }

    it 'does nothing outside a server' do
      described_class.boot(server: nil, config: no_oauth_config,
                           production: true, logger: logger)
      expect(logger).not_to have_received(:info)
    end

    it 'logs and starts when a production server has everything required' do
      described_class.boot(server: 'constant', config: complete_config,
                           production: true, logger: logger)
      expect(logger).to have_received(:info).with(/\ABoot: /)
    end

    it 'starts a production server without APP_HOSTNAME' do
      expect do
        described_class.boot(server: 'constant', config: no_hostname_config,
                             production: true, logger: logger)
      end.not_to raise_error
    end

    it 'logs the missing APP_HOSTNAME at error when it starts' do
      described_class.boot(server: 'constant', config: no_hostname_config,
                           production: true, logger: logger)
      expect(logger).to have_received(:error).with(/\ABoot: APP_HOSTNAME is unset/)
    end

    it 'refuses a production server missing an OAuth key' do
      expect do
        described_class.boot(server: 'constant', config: no_oauth_config,
                             production: true, logger: logger)
      end.to raise_error(AppConfig::MissingError, /GITHUB_OAUTH_APP_SECRET/)
    end

    it 'logs what is unset before refusing' do
      suppress(AppConfig::MissingError) do
        described_class.boot(server: 'constant', config: no_oauth_config,
                             production: true, logger: logger)
      end
      expect(logger).to have_received(:error).with(/\ABoot: GITHUB_OAUTH_APP_SECRET is unset/)
    end

    it 'starts a development or test server whatever is missing, logging no error' do
      described_class.boot(server: 'constant', config: AppConfig.new({}),
                           production: false, logger: logger)
      expect(logger).not_to have_received(:error)
    end
  end
end
