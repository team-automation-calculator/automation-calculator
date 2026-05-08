require 'net/http'
require 'net/https'
require 'json'
require 'nokogiri'

module SmokeHttp
  BASE_URL = ENV.fetch("SMOKE_TARGET_URL", "http://localhost:3001").freeze
  V1_HEADERS = {
    'Content-Type' => 'application/json',
    'Accept'       => 'application/json; version=1'
  }.freeze

  def smoke_get(path)
    uri = URI("#{BASE_URL}#{path}")
    smoke_http(uri).request(Net::HTTP::Get.new(uri.request_uri))
  end

  def smoke_v1_get(path, token: nil)
    uri = URI("#{BASE_URL}#{path}")
    req = Net::HTTP::Get.new(uri.request_uri, V1_HEADERS)
    req['Access-Token'] = token if token
    smoke_http(uri).request(req)
  end

  def smoke_v1_post(path, body: {}, token: nil)
    uri = URI("#{BASE_URL}#{path}")
    req = Net::HTTP::Post.new(uri.request_uri, V1_HEADERS)
    req['Access-Token'] = token if token
    req.body = body.to_json
    smoke_http(uri).request(req)
  end

  private

  def smoke_http(uri)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = uri.scheme == 'https'
    http
  end
end

RSpec.configure do |config|
  config.include SmokeHttp, :smoke
end
