module Requests
  module JsonHelper
    def json_response(data = nil)
      data ||= JSON.parse(response.body)
      case data
      when Array
        data.map { |entry| json_response(entry) }
      when Hash
        data.with_indifferent_access
      else
        data
      end
    end
  end
end

RSpec.configure do |config|
  config.include Requests::JsonHelper, type: :request
end
