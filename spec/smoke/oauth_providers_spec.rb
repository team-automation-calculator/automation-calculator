require 'smoke_helper'

# OAuth sign-in checks that need no Google or GitHub account.
#
# Three layers, each stronger than the last:
#   1. the provider links render on the sign-in page
#   2. the authorize redirect carries a client_id and a redirect_uri
#      that points back at the target being smoked
#   3. a callback with a bogus code round-trips the real token exchange
#      against the provider and lands on the failure redirect
#
# Layer 3 is the one that would have caught the faraday 2.0.0
# regression fixed in #210. OmniAuth test mode in
# spec/features/user_oauth2_spec.rb never exercises the HTTP client,
# so a broken Faraday stack only shows up as a 500 on a live callback.
RSpec.describe 'OAuth providers', :smoke do
  shared_examples_for 'an oauth provider' do |provider, link:, authorize:|
    let(:authorize_path) { "/users/auth/#{provider}" }
    let(:callback_path) { "#{authorize_path}/callback" }

    describe 'GET /users/sign_in' do
      it "links to #{link}" do
        response = smoke_get('/users/sign_in')
        doc = Nokogiri::HTML(response.body)
        href = doc.at_xpath("//a[normalize-space(text())='#{link}']/@href")
        expect(href&.value).to eq(authorize_path)
      end
    end

    describe "GET /users/auth/#{provider}" do
      let(:response) { smoke_get(authorize_path) }
      let(:location) { response['Location'].to_s }
      let(:params) { smoke_query(location) }

      it 'redirects to the provider authorize endpoint' do
        expect(response.code.to_i).to eq(302),
                                      "Expected 302, got #{response.code}"
        expect(location).to start_with(authorize)
      end

      it 'sets a redirect_uri that points back at the smoke target' do
        target = URI(SmokeHttp::BASE_URL)
        redirect_uri = URI(params.fetch('redirect_uri', ''))
        expect(redirect_uri.scheme).to eq(target.scheme)
        expect(redirect_uri.host).to eq(target.host)
        expect(redirect_uri.path).to eq(callback_path)
      end

      it 'includes a CSRF state' do
        expect(params['state']).not_to be_nil
        expect(params['state']).not_to be_empty
      end

      it 'includes a client_id (deployed targets only)' do
        skip 'client_id is only expected on staging/prod' \
          unless smoke_deployed_target?
        expect(params['client_id'].to_s).not_to be_empty,
                                                'OAuth app id env var unset'
      end
    end

    describe "GET /users/auth/#{provider}/callback" do
      # The session cookie and the state from the authorize redirect
      # must be replayed, or omniauth-oauth2 rejects the callback as
      # CSRF before it ever attempts the token exchange.
      it 'rejects a bogus code via the failure redirect, not a 500' do
        start = smoke_get(authorize_path)
        state = smoke_query(start['Location'].to_s)['state']
        expect(state).not_to be_nil, 'Expected state in authorize redirect'

        response = smoke_get(
          "#{callback_path}?code=bogus&state=#{state}",
          cookie: smoke_cookie(start)
        )
        msg = "Expected 302 to /, got #{response.code}: " \
              "#{response.body.to_s[0, 300]}"
        expect(response.code.to_i).to eq(302), msg
        expect(URI(response['Location'].to_s).path).to eq('/')
      end
    end
  end

  it_behaves_like 'an oauth provider', 'github',
                  link: 'Sign in with GitHub',
                  authorize: 'https://github.com/login/oauth/authorize'

  it_behaves_like 'an oauth provider', 'google_oauth2',
                  link: 'Sign in with GoogleOauth2',
                  authorize: 'https://accounts.google.com/o/oauth2/auth'
end
