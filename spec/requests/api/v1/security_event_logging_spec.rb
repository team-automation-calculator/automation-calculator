require 'rails_helper'

# The API answers these with a status that hides the reason (or with a
# plain success); who did what, and from where, is only in the log.
RSpec.describe 'API security event logging', type: :request do
  let(:user) { create :user }

  before do
    allow(Rails.logger).to receive(:info)
    allow(Rails.logger).to receive(:warn)
  end

  describe 'POST /api/sign_in' do
    before { v1_post '/api/sign_in', params: params }

    context 'with valid credentials' do
      let(:params) { { email: user.email, password: user.password } }

      it 'logs the sign-in with the user id' do
        expect(Rails.logger).to have_received(:info)
          .with(/API sign-in: user=#{user.id} ip=127\.0\.0\.1/)
      end
    end

    context 'with a wrong password' do
      let(:params) { { email: user.email, password: 'not-the-password' } }

      it 'warns and names the targeted user' do
        expect(Rails.logger).to have_received(:warn)
          .with(/API 401: sign-in failed: reason=wrong_password user=#{user.id} ip=/)
      end

      it 'does not log the email or the password' do
        expect(Rails.logger).not_to have_received(:warn)
          .with(/#{Regexp.escape(user.email)}|not-the-password/)
      end
    end

    context 'with an unknown email' do
      let(:params) { { email: 'nobody@example.com', password: 'whatever' } }

      it 'warns without the email' do
        expect(Rails.logger).to have_received(:warn)
          .with(/API 401: sign-in failed: reason=unknown_email ip=/)
      end
    end
  end

  describe 'POST /api/sign_up' do
    before do
      v1_post '/api/sign_up',
              params: { email: 'new@example.com', password: 'password123' }
    end

    it 'logs the new user id' do
      expect(Rails.logger).to have_received(:info)
        .with(/API sign-up: user=#{User.last.id} ip=/)
    end
  end

  describe 'POST /api/visitor' do
    before { v1_post '/api/visitor' }

    it 'logs the new visitor id' do
      expect(Rails.logger).to have_received(:info)
        .with(/API visitor created: visitor=#{Visitor.last.id} ip=/)
    end
  end

  describe 'PUT /api/reset_password' do
    before { v1_put '/api/reset_password', params: { email: email } }

    context 'with a registered email' do
      let(:email) { user.email }

      it { expect(response).to have_http_status(:ok) }

      it 'logs which user was sent instructions' do
        expect(Rails.logger).to have_received(:info)
          .with(/API password reset requested: user=#{user.id} ip=/)
      end
    end

    context 'with an unknown email' do
      let(:email) { 'nobody@example.com' }

      it { expect(response).to have_http_status(:ok) }

      it 'logs that nothing was sent' do
        expect(Rails.logger).to have_received(:info)
          .with(/API password reset requested: unknown_email ip=/)
      end
    end
  end

  describe 'PUT /api/users/profile/password' do
    before do
      v1_login_user user
      v1_put '/api/users/profile/password',
             params: { current_password: current_password,
                       password: 'new-password' }
    end

    context 'with the current password' do
      let(:current_password) { user.password }

      it { expect(response).to be_successful }

      it 'logs the change' do
        expect(Rails.logger).to have_received(:info)
          .with(/API password changed: user=#{user.id} ip=/)
      end
    end

    context 'with a wrong current password' do
      let(:current_password) { 'not-the-password' }

      it { expect(response).to have_http_status(:unauthorized) }

      it 'warns with the user id' do
        expect(Rails.logger).to have_received(:warn)
          .with(/API 401: current password rejected: user=#{user.id} ip=/)
      end
    end
  end

  describe 'PUT /api/users/profile' do
    before do
      v1_login_user user
      v1_put '/api/users/profile',
             params: { current_password: user.password,
                       email: 'changed@example.com' }
    end

    it { expect(response).to be_successful }

    it 'logs the change without the address' do
      expect(Rails.logger).to have_received(:info)
        .with(/API email changed: user=#{user.id} ip=[\d.]+\z/)
    end
  end

  describe "GET /api/solutions/:id for another member's solution" do
    let(:solution) { create :solution }

    before do
      v1_login_user user
      v1_get "/api/solutions/#{solution.id}"
    end

    it 'answers as if the solution did not exist' do
      expect(response).to have_http_status(:not_found)
    end

    it 'warns with the solution and the caller' do
      expect(Rails.logger).to have_received(:warn)
        .with(/API 404: .*NotOwnedError: solution=#{solution.id} is not owned by user=#{user.id} ip=/)
    end
  end

  describe 'a signed token that names neither a user nor a visitor' do
    before do
      v1_get '/api/automation_scenarios',
             headers: { 'Access-Token' => JwtTokenService.encode_token(admin: true) }
    end

    it { expect(response).to have_http_status(:not_found) }

    it 'logs why the token was not accepted' do
      expect(Rails.logger).to have_received(:info)
        .with(/API 404: .*token payload names neither a user nor a visitor/)
    end
  end

  describe 'POST /api/iterations with invalid attributes' do
    before do
      v1_login_user user
      v1_post '/api/iterations',
              params: { iteration: { cost: -1,
                                     automation_scenario_id: user.automation_scenarios.first.id } }
    end

    it { expect(response).to have_http_status(:unprocessable_content) }

    it 'logs the rejection with the reason' do
      expect(Rails.logger).to have_received(:info)
        .with(/API 422: iteration invalid: Cost must be greater than 0/)
    end
  end
end
