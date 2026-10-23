require 'smoke_helper'

# OAuth sign-in checks that need no Google or GitHub account.
#
# Three layers, each stronger than the last:
#   1. the provider sign-in forms render on the sign-in page
#   2. the authorize redirect carries a client_id and a redirect_uri
#      that points back at the target being smoked
#   3. a callback with a bogus code round-trips the real token exchange
#      against the provider and lands on the failure redirect
#
# Layer 3 is the one that would have caught the faraday 2.0.0
# regression fixed in #210. OmniAuth test mode in
# spec/features/user_oauth2_spec.rb never exercises the HTTP client,
# so a broken Faraday stack only shows up as a 500 on a live callback.
#
# omniauth 2 only starts a flow from POST /users/auth/:provider carrying
# the Rails authenticity token (omniauth-rails_csrf_protection), so the
# authorize step is driven the way a browser does it: load the sign-in
# page, keep its session cookie, and submit the provider's button_to
# form with the token it rendered. The callback stays a GET.
RSpec.describe 'OAuth providers', :smoke do
  shared_examples_for 'an oauth provider' do |provider, button:, authorize:|
    let(:authorize_path) { "/users/auth/#{provider}" }
    let(:callback_path) { "#{authorize_path}/callback" }

    def sign_in_form(authorize_path)
      response = smoke_get('/users/sign_in')
      form = Nokogiri::HTML(response.body)
                     .at_css("form[action='#{authorize_path}']")
      expect(form).not_to be_nil, "Expected a form posting to #{authorize_path}"
      [form, smoke_cookie(response)]
    end

    def start_oauth(authorize_path)
      form, cookie = sign_in_form(authorize_path)
      token = form.at_css("input[name='authenticity_token']")&.[]('value')
      smoke_post_form(authorize_path, { 'authenticity_token' => token.to_s },
                      cookie: cookie)
    end

    describe 'GET /users/sign_in' do
      it "renders a POST form for #{button}" do
        form, = sign_in_form(authorize_path)
        expect(form['method'].to_s.downcase).to eq('post')
        submit = form.at_css("input[type='submit'][value='#{button}'], button")
        expect(submit).not_to be_nil, "Expected a '#{button}' submit control"
      end
    end

    describe "GET /users/auth/#{provider}" do
      it 'does not start the OAuth flow (omniauth 2 rejects GET)' do
        response = smoke_get(authorize_path)
        location = response['Location'].to_s
        msg = "GET must not start OAuth, got #{response.code} #{location}"
        expect(URI(location).host).not_to eq(URI(authorize).host), msg
      end
    end

    describe "POST /users/auth/#{provider}" do
      let(:response) { start_oauth(authorize_path) }
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
        start = start_oauth(authorize_path)
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
                  button: 'Sign in with GitHub',
                  authorize: 'https://github.com/login/oauth/authorize'

  it_behaves_like 'an oauth provider', 'google_oauth2',
                  button: 'Sign in with GoogleOauth2',
                  authorize: 'https://accounts.google.com/o/oauth2/auth'
end
