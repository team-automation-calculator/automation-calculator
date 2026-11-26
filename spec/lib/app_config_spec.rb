require 'rails_helper'

RSpec.describe AppConfig do
  subject(:config) { described_class.new(complete_env) }

  let(:complete_env) do
    {
      'APP_HOSTNAME' => 'staging.example.io',
      'SHORT_COMMIT_HASH' => 'abc1234',
      'GOOGLE_ANALYTICS_TRACKING_ID' => 'G-TEST',
      'GITHUB_OAUTH_APP_ID' => 'github-id', 'GITHUB_OAUTH_APP_SECRET' => 'github-secret',
      'GOOGLE_OAUTH_APP_ID' => 'google-id', 'GOOGLE_OAUTH_APP_SECRET' => 'google-secret'
    }
  end

  describe 'readers' do
    it { expect(config.app_hostname).to eq('staging.example.io') }
    it { expect(config.short_commit_hash).to eq('abc1234') }
    it { expect(config.google_analytics_tracking_id).to eq('G-TEST') }
    it { expect(config.oauth_credentials(:github)).to eq(%w[github-id github-secret]) }
    it { expect(config.oauth_credentials(:google)).to eq(%w[google-id google-secret]) }

    it 'returns nil for an unset or blank value' do
      config = described_class.new('APP_HOSTNAME' => '  ')
      expect([config.app_hostname, config.short_commit_hash]).to eq([nil, nil])
    end

    it 'rejects an unknown OAuth provider' do
      expect { config.oauth_credentials(:twitter) }.to raise_error(KeyError)
    end
  end

  describe '#oauth_configured?' do
    it 'is true when both halves are set' do
      expect(config.oauth_configured?(:github)).to be(true)
    end

    it 'is false when either half is missing' do
      config = described_class.new(complete_env.except('GOOGLE_OAUTH_APP_SECRET'))
      expect(config.oauth_configured?(:google)).to be(false)
    end
  end

  describe '#unset' do
    it 'is empty when everything is set' do
      expect(config.unset).to eq(error: {}, warn: {})
    end

    it 'puts APP_HOSTNAME and every OAuth key under error when nothing is set' do
      expect(described_class.new({}).unset[:error].keys).to contain_exactly(
        'APP_HOSTNAME', *described_class::OAUTH_CREDENTIALS.values.flatten
      )
    end

    it 'puts recommended settings under warn when nothing is set' do
      expect(described_class.new({}).unset[:warn].keys)
        .to match_array(described_class::RECOMMENDED.keys)
    end
  end

  describe '.current' do
    it 'reads the process environment' do
      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:[]).with('SHORT_COMMIT_HASH').and_return('def5678')
      expect(described_class.current.short_commit_hash).to eq('def5678')
    end
  end
end
