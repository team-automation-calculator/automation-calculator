module Requests
  module V1AuthHelper
    def v1_login_user(user = create(:user))
      params = { email: user.email, password: user.password }
      v1_post '/api/sign_in', params: params
      @current_token = response.headers['Access-Token']
      raise "v1_login_user failed with #{params}" unless @current_token

      user
    end

    def v1_login_visitor
      v1_post '/api/visitor'
      @current_token = response.headers['Access-Token']
      raise 'v1_login_visitor failed' unless @current_token
      visitor = Visitor.last

      visitor
    end
  end
end

RSpec.configure do |config|
  config.include Requests::V1AuthHelper, type: :request
end
