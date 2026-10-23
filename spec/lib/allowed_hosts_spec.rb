require 'rails_helper'

RSpec.describe AllowedHosts do
  describe '.list' do
    it 'lists the deployment host and its www alias in production' do
      list = described_class.list(production: true,
                                  app_hostname: 'staging.example.io')
      expect(list).to eq(%w[staging.example.io www.staging.example.io])
    end

    it 'is empty in production when APP_HOSTNAME is unset' do
      list = described_class.list(production: true, app_hostname: nil)
      expect(list).to eq([])
    end

    it 'lists the local hosts outside production, whatever APP_HOSTNAME' do
      list = described_class.list(production: false,
                                  app_hostname: 'staging.example.io')
      expect(list).to eq(%w[localhost 127.0.0.1 dev www.example.com])
    end

    it 'is what config.hosts was set from' do
      expect(Rails.application.config.hosts).to eq(described_class.list)
    end
  end
end
