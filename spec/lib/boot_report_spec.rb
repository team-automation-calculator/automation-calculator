require 'rails_helper'

RSpec.describe BootReport do
  let(:complete_env) do
    {
      'APP_HOSTNAME' => 'staging.example.io',
      'SHORT_COMMIT_HASH' => 'abc1234',
      'GITHUB_OAUTH_APP_ID' => 'id', 'GITHUB_OAUTH_APP_SECRET' => 'github-secret',
      'GOOGLE_OAUTH_APP_ID' => 'id', 'GOOGLE_OAUTH_APP_SECRET' => 'google-secret'
    }
  end

  describe '.summary' do
    subject(:summary) do
      described_class.summary(env: complete_env,
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
      env = complete_env.except('SHORT_COMMIT_HASH', 'GOOGLE_OAUTH_APP_SECRET')
      expect(described_class.summary(env: env, hosts: []))
        .to include('commit=unknown', 'hosts=none',
                    'oauth=github:configured,google:missing')
    end
  end

  describe '.warnings' do
    it 'is empty in production when everything is set' do
      expect(described_class.warnings(env: complete_env, production: true)).to eq([])
    end

    it 'is empty outside production, whatever is missing' do
      expect(described_class.warnings(env: {}, production: false)).to eq([])
    end

    it 'names every missing piece in production' do
      expect(described_class.warnings(env: {}, production: true)).to contain_exactly(
        /APP_HOSTNAME is unset/, /SHORT_COMMIT_HASH is unset/,
        /github OAuth credentials are unset/, /google OAuth credentials are unset/
      )
    end

    it 'treats a blank value as missing' do
      env = complete_env.merge('GITHUB_OAUTH_APP_ID' => '')
      expect(described_class.warnings(env: env, production: true))
        .to contain_exactly(/github OAuth credentials are unset/)
    end
  end

  describe '.log' do
    let(:logger) { instance_double(ActiveSupport::Logger, info: nil, warn: nil) }

    it 'writes the summary at info' do
      described_class.log(logger)
      expect(logger).to have_received(:info).with(/\ABoot: env=test /)
    end
  end
end
