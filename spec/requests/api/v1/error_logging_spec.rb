require 'rails_helper'

# The API answers a rescued error with a bare status or a generic body; the
# reason is only visible in the log.
RSpec.describe 'API error logging', type: :request do
  before do
    allow(Rails.logger).to receive(:info)
    allow(Rails.logger).to receive(:warn)
  end

  context 'when the access token is missing or malformed' do
    before { v1_get '/api/automation_scenarios', headers: { 'Access-Token' => 'not-a-token' } }

    it { expect(response).to have_http_status(:unauthorized) }

    it 'logs the rejection as a warning' do
      expect(Rails.logger).to have_received(:warn)
        .with(/API 401: access token rejected: JwtTokenService::DecodeError/)
    end

    it 'does not log the token' do
      expect(Rails.logger).not_to have_received(:warn).with(/not-a-token/)
    end
  end

  context 'when the access token has expired' do
    before do
      allow(JwtTokenService).to receive(:decode_token)
        .and_raise(JwtTokenService::ExpiredError, 'Signature has expired')
      v1_get '/api/automation_scenarios',
             headers: { 'Access-Token' => 'expired' }
    end

    it { expect(response).to have_http_status(:unauthorized) }

    it 'logs the rejection at info level' do
      expect(Rails.logger).to have_received(:info)
        .with(/API 401: access token rejected: JwtTokenService::ExpiredError/)
    end
  end

  context 'when the record does not exist' do
    before do
      v1_login_user
      v1_get '/api/automation_scenarios/0'
    end

    it { expect(response).to have_http_status(:not_found) }

    it 'logs the miss at info level' do
      expect(Rails.logger).to have_received(:info)
        .with(/API 404: ActiveRecord::RecordNotFound/)
    end
  end

  context 'when the record is invalid' do
    before do
      user = create(:user)
      v1_post '/api/sign_up',
              params: { email: user.email, password: 'password123' }
    end

    it { expect(response).to have_http_status(:unprocessable_content) }

    it 'logs the validation failure at info level' do
      expect(Rails.logger).to have_received(:info)
        .with(/API 422: ActiveRecord::RecordInvalid/)
    end
  end
end
