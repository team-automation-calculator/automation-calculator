require 'rails_helper'

# Credentials that would reach the log through Rails' own logging rather
# than through a line this app writes.
RSpec.describe 'Secrets in the log', type: :request do
  describe 'a password-reset email' do
    let(:user) { create :user }
    let(:log) { StringIO.new }
    let(:reset_token) do
      ActionMailer::Base.deliveries.last.body.to_s[/reset_password_token=([\w-]+)/, 1]
    end

    around do |example|
      logger = ActionMailer::Base.logger
      ActionMailer::Base.logger = ActiveSupport::Logger.new(log, level: :debug)
      example.run
      ActionMailer::Base.logger = logger
    end

    before { v1_put '/api/reset_password', params: { email: user.email } }

    it 'is delivered with a reset link' do
      expect(reset_token).to be_present
    end

    it 'is logged as delivered' do
      expect(log.string).to match(/Delivered mail \S+ \(/)
    end

    it 'does not put the reset token in the log' do
      expect(log.string).not_to include(reset_token)
    end

    it 'does not put the recipient address in the log' do
      expect(log.string).not_to include(user.email)
    end
  end

  describe 'the OAuth callback query string' do
    let(:request) do
      ActionDispatch::Request.new(
        Rails.application.env_config.merge(
          Rack::MockRequest.env_for(
            '/users/auth/github/callback?code=4f9a&state=77bc&postal_code=1'
          )
        )
      )
    end

    it 'has the authorization code and state filtered from the logged path' do
      expect(request.filtered_path).to eq(
        '/users/auth/github/callback?code=[FILTERED]&state=[FILTERED]&postal_code=1'
      )
    end
  end
end
