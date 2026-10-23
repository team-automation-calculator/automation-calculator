require 'rails_helper'

# OmniAuth test mode (see spec/features/user_oauth2_spec.rb) skips the
# callback's token exchange, so it can't catch a broken HTTP client.
# Building the real strategy's Faraday stack does, without a network call.
RSpec.describe OAuth2::Client do
  {
    github: OmniAuth::Strategies::GitHub,
    google_oauth2: OmniAuth::Strategies::GoogleOauth2
  }.each do |provider, strategy_class|
    it "can build a Faraday connection for #{provider} token exchange" do
      client = strategy_class.new(nil, 'client_id', 'client_secret').client

      expect { client.connection.builder.app }.not_to raise_error
    end
  end
end
