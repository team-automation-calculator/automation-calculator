require 'rails_helper'

# config/initializers/host_authorization.rb lists the hosts Rails may
# serve. ActionDispatch::HostAuthorization answers 403 to any other
# Host or X-Forwarded-Host, except on /health, which the kubelet and
# the ALB probe by pod IP and so must stay reachable under any host.
RSpec.describe 'Rails host authorization', type: :request do
  let(:forged_host) { 'attacker.example' }

  describe 'GET /health' do
    %w[Host X-Forwarded-Host].each do |header|
      it "answers 200 with a forged #{header}, as the probes send one" do
        get '/health', headers: { header => forged_host }
        expect(response).to have_http_status(:ok)
      end
    end
  end

  describe 'GET /' do
    it 'answers 200 for the integration test host' do
      get '/'
      expect(response).to have_http_status(:ok)
    end

    %w[Host X-Forwarded-Host].each do |header|
      it "is blocked with a forged #{header}" do
        get '/', headers: { header => forged_host }
        expect(response).to have_http_status(:forbidden)
      end
    end
  end
end
