require 'rails_helper'

# A request over a rate limit is answered 429 and logged once, as a
# warning. The test environment's null cache store never counts, so the
# counter is stubbed to be over every limit.
RSpec.describe 'A rate-limited request', type: :request do
  before do
    allow(Rails.cache).to receive(:increment).and_return(1_000)
    allow(Rails.logger).to receive(:warn)
    allow(Rails.logger).to receive(:error)
    allow(Rails.logger).to receive(:fatal)
  end

  shared_examples_for 'a quietly throttled request' do |line|
    it { expect(response).to have_http_status(:too_many_requests) }
    it { expect(response.body).to be_empty }

    it 'logs the rate-limit warning' do
      expect(Rails.logger).to have_received(:warn).with(line)
    end

    it 'does not log an exception' do
      expect(Rails.logger).not_to have_received(:error)
    end

    it 'does not log a fatal error' do
      expect(Rails.logger).not_to have_received(:fatal)
    end
  end

  context 'with the JSON API' do
    before do
      v1_post '/api/sign_in', params: { email: 'a@example.com', password: 'x' }
    end

    it_behaves_like 'a quietly throttled request',
                    %r{Rate limit exceeded: POST /api/sign_in count=1000 limit=10/60s}
  end

  context 'with the web interface' do
    before { post visitor_path }

    it_behaves_like 'a quietly throttled request',
                    %r{Rate limit exceeded: POST /visitor count=1000 limit=30/60s}
  end
end
