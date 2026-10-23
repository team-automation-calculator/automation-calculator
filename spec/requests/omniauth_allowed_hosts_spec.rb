require 'rails_helper'

# config/initializers/omniauth.rb gives OmniAuth the same host list Rails
# host authorization uses, so a forged Host or X-Forwarded-Host is
# answered 403 by ActionDispatch::HostAuthorization before OmniAuth
# runs. OmniAuth's own check is exercised by emptying its list for the
# integration host: the request then fails the request phase with
# :invalid_host before an authorize URL exists. OmniAuth test mode (left
# on by the feature specs) short-circuits the request phase ahead of
# that check, so it is switched off here. Without OAuth app credentials
# a listed host fails later with :missing_client_id, which is enough to
# show the host check let it through.
RSpec.describe 'OmniAuth allowed hosts', type: :request do
  let(:forged_host) { 'attacker.example' }

  # example.run reports failures itself rather than raising, so the
  # previous settings are always restored.
  around do |example|
    test_mode = OmniAuth.config.test_mode
    allowed_hosts = OmniAuth.config.allowed_hosts
    OmniAuth.config.test_mode = false
    example.run
    OmniAuth.config.test_mode = test_mode
    OmniAuth.config.allowed_hosts = allowed_hosts
  end

  it 'shares the host list with Rails host authorization' do
    expect(OmniAuth.config.allowed_hosts).to eq(AllowedHosts.list)
  end

  shared_examples_for 'a host-checked request phase' do |provider|
    let(:authorize_path) { "/users/auth/#{provider}" }

    it 'lets the integration test host through the host check' do
      post authorize_path
      expect(request.env['omniauth.error.type']).not_to eq(:invalid_host)
    end

    context 'with a host OmniAuth does not allow' do
      before do
        OmniAuth.config.allowed_hosts = []
        post authorize_path
      end

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

    %w[Host X-Forwarded-Host].each do |header|
      context "with a forged #{header}" do
        before { post authorize_path, headers: { header => forged_host } }

        it 'is blocked by Rails host authorization before OmniAuth runs' do
          expect(response).to have_http_status(:forbidden)
        end

        it 'never reaches the OmniAuth request phase' do
          expect(request.env['omniauth.error.type']).to be_nil
        end
      end
    end
  end

  %w[github google_oauth2].each do |provider|
    describe "POST /users/auth/#{provider}" do
      include_examples 'a host-checked request phase', provider
    end
  end
end
