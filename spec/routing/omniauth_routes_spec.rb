require 'rails_helper'

# Devise 5 routes the OmniAuth authorize path with the verbs in
# OmniAuth.config.allowed_request_methods (POST only since omniauth 2),
# where Devise 4 always routed GET and POST. A GET to /users/auth/:provider
# therefore no longer reaches OmniauthCallbacksController#passthru (which
# answered 404 "Not found. Authentication passthru."); it has no route and
# Rails answers 404 itself. The callback keeps both verbs.
RSpec.describe 'OmniAuth routes', type: :routing do
  %w[github google_oauth2].each do |provider|
    describe "/users/auth/#{provider}" do
      let(:path) { "/users/auth/#{provider}" }

      it 'routes POST to passthru' do
        expect(post: path).to route_to('users/omniauth_callbacks#passthru')
      end

      it 'does not route GET' do
        expect(get: path).not_to be_routable
      end
    end

    describe "/users/auth/#{provider}/callback" do
      let(:path) { "/users/auth/#{provider}/callback" }
      let(:action) { "users/omniauth_callbacks##{provider}" }

      it 'routes GET to the provider action' do
        expect(get: path).to route_to(action)
      end

      it 'routes POST to the provider action' do
        expect(post: path).to route_to(action)
      end
    end
  end

  it 'matches the verbs OmniAuth accepts for the request phase' do
    expect(OmniAuth.config.allowed_request_methods).to eq([:post])
  end
end
