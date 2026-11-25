require 'rails_helper'

# config/initializers/security_event_logging.rb and the web controllers:
# events Rails, Devise and Warden handle without a log line of their own.
RSpec.describe 'Security event logging', type: :request do
  let(:user) { create :user }

  before do
    allow(Rails.logger).to receive(:info)
    allow(Rails.logger).to receive(:warn)
  end

  describe 'POST /users/sign_in' do
    before do
      post user_session_path,
           params: { user: { email: user.email, password: password } }
    end

    context 'with the right password' do
      let(:password) { user.password }

      it 'logs the sign-in with the user id' do
        expect(Rails.logger).to have_received(:info)
          .with(/Sign-in: user=#{user.id} event=authentication ip=127\.0\.0\.1/)
      end
    end

    context 'with a wrong password' do
      let(:password) { 'not-the-password' }

      it 'warns about the failed attempt' do
        expect(Rails.logger).to have_received(:warn)
          .with(%r{Authentication failed: scope=user reason=invalid POST /users/sign_in ip=127\.0\.0\.1})
      end

      it 'does not log the email or the password' do
        expect(Rails.logger).not_to have_received(:warn)
          .with(/#{Regexp.escape(user.email)}|not-the-password/)
      end
    end
  end

  describe 'opening a protected page signed out' do
    before { get users_profile_path }

    it { expect(response).to redirect_to(new_user_session_path) }

    it 'logs at info, not as a failed credential check' do
      expect(Rails.logger).to have_received(:info)
        .with(%r{Authentication failed: scope=user reason=unauthenticated GET /users/profile})
    end
  end

  describe 'DELETE /users/sign_out' do
    before do
      login_as user, scope: :user
      delete destroy_user_session_path
    end

    it 'logs the sign-out' do
      expect(Rails.logger).to have_received(:info)
        .with(/Sign-out: user=#{user.id} ip=/)
    end
  end

  describe 'POST /users (sign-up)' do
    before do
      post user_registration_path,
           params: { user: { email: 'new@example.com',
                             password: 'password123',
                             password_confirmation: 'password123' } }
    end

    it 'logs the new user id' do
      expect(Rails.logger).to have_received(:info)
        .with(/Sign-up: user=#{User.last.id} ip=/)
    end
  end

  describe 'PATCH /users/profile/update_password' do
    before do
      login_as user, scope: :user
      patch update_password_users_profile_path,
            params: { user: { current_password: current_password,
                              password: 'new-password',
                              password_confirmation: 'new-password' } }
    end

    context 'with the current password' do
      let(:current_password) { user.password }

      it 'logs the change' do
        expect(Rails.logger).to have_received(:info)
          .with(/Password changed: user=#{user.id} ip=/)
      end
    end

    context 'with a wrong current password' do
      let(:current_password) { 'not-the-password' }

      it 'warns with the user id' do
        expect(Rails.logger).to have_received(:warn)
          .with(/Password change rejected: current_password: user=#{user.id} ip=/)
      end
    end
  end

  describe 'PATCH /users/profile' do
    before do
      login_as user, scope: :user
      patch users_profile_path, params: { user: { email: 'changed@example.com' } }
    end

    it 'logs the change without the address' do
      expect(Rails.logger).to have_received(:info)
        .with(/Email changed: user=#{user.id} ip=[\d.]+\z/)
    end
  end

  # OmniAuth test mode (left on by the feature specs) short-circuits the
  # request phase; with it off and no allowed hosts the request fails as
  # :invalid_host, see spec/requests/omniauth_allowed_hosts_spec.rb.
  describe 'a failed OAuth sign-in' do
    around do |example|
      test_mode = OmniAuth.config.test_mode
      allowed_hosts = OmniAuth.config.allowed_hosts
      OmniAuth.config.test_mode = false
      OmniAuth.config.allowed_hosts = []
      example.run
      OmniAuth.config.test_mode = test_mode
      OmniAuth.config.allowed_hosts = allowed_hosts
    end

    before { post '/users/auth/github' }

    it 'warns with the provider and the failure type' do
      expect(Rails.logger).to have_received(:warn)
        .with(/OAuth sign-in failed: provider=github type=invalid_host .* ip=127\.0\.0\.1/)
    end
  end

  # The test environment's null cache store never counts, so no request
  # here can go over a limit; publish the event Rails 8.1 instruments.
  describe 'a rate-limited request' do
    before do
      request = ActionDispatch::TestRequest.create(
        'REQUEST_METHOD' => 'POST', 'PATH_INFO' => '/api/sign_in'
      )
      ActiveSupport::Notifications.instrument(
        'rate_limit.action_controller',
        request: request, count: 11, to: 10, within: 1.minute, by: '203.0.113.7'
      )
    end

    it 'warns with the endpoint, the limit and the client' do
      expect(Rails.logger).to have_received(:warn)
        .with(%r{Rate limit exceeded: POST /api/sign_in count=11 limit=10/60s by=203\.0\.113\.7})
    end
  end
end
