module Requests
  module V1Helper
    def v1_request(meth, path, request_options = {})
      headers = request_options[:headers] ||= {}
      headers.reverse_merge!(v1_default_headers)

      token = request_options.fetch(:token, @current_token)
      headers.reverse_merge!('Access-Token' => token) if token

      params = request_options[:params]
      if params.present? && !params.is_a?(String)
        request_options[:params] = params.to_json
      end

      public_send meth, path, request_options
    end

    %i[get post put patch delete].each do |meth|
      define_method "v1_#{meth}" do |*args|
        v1_request meth, *args
      end
    end

    def v1_default_headers
      {
        'content-type' => 'application/json',
        'accept' => 'application/json; version=1'
      }
    end
  end
end

RSpec.configure do |config|
  config.include Requests::V1Helper, type: :request
end
