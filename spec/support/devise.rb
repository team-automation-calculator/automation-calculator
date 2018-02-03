require 'devise'
RSpec.configure do |config|
  config.include Devise::Test::ControllerHelpers, type: :controller

  include Warden::Test::Helpers
  config.after do
    Warden.test_reset!
  end
end
