require 'rails_helper'

# config/initializers/omniauth.rb lists the hosts OmniAuth may build a
# callback URL from; any other host fails the request phase with
# :invalid_host before an authorize URL exists. OmniAuth test mode
# (left on by the feature specs) short-circuits the request phase
# ahead of that check, so it is switched off here. Without OAuth app
# credentials a listed host fails later with :missing_client_id, which
# is enough to show the host check let it through.
RSpec.describe 'OmniAuth allowed hosts', type: :request do
  let(:forged_host) { 'attacker.example' }

  # example.run reports failures itself rather than raising, so the
  # previous mode is always restored.
  around do |example|
    test_mode = OmniAuth.config.test_mode
    OmniAuth.config.test_mode = false
    example.run
    OmniAuth.config.test_mode = test_mode
  end

  %w[github google_oauth2].each do |provider|
    describe "POST /users/auth/#{provider}" do
      let(:authorize_path) { "/users/auth/#{provider}" }

      it 'lets the integration test host through the host check' do
        post authorize_path
        expect(request.env['omniauth.error.type']).not_to eq(:invalid_host)
      end

      %w[Host X-Forwarded-Host].each do |header|
        context "with a forged #{header}" do
          before { post authorize_path, headers: { header => forged_host } }

          it 'fails the request phase as an invalid host' do
            expect(request.env['omniauth.error.type']).to eq(:invalid_host)
          end

          it 'answers with a redirect' do
            expect(response).to have_http_status(:found)
          end

          it 'redirects to the failure path, not the provider' do
            expect(URI(response.location).path).to eq('/')
          end
        end
      end
    end
  end
end
