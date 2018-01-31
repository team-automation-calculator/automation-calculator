require 'devise'
RSpec.configure do |config|
  config.include Devise::Test::ControllerHelpers, type: :controller
  include Warden::Test::Helpers
end
