require 'net/http'
require 'net/https'
require 'json'
require 'nokogiri'
require 'json_schema'

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

module SmokeSchema
  SCHEMA_DIR = File.expand_path("../support/api_schemas", __FILE__).freeze

  def validate_schema!(schema_name, body)
    data = body.is_a?(String) ? JSON.parse(body) : body
    valid, errors = schema_store.find("file:/#{schema_name}#").validate(data)
    raise "Schema mismatch for #{schema_name}: #{errors.map(&:message).join(', ')}" unless valid
  end

  private

  def schema_store
    @schema_store ||= JsonSchema::DocumentStore.new.tap do |store|
      Dir[File.join(SCHEMA_DIR, "*.json")].each do |path|
        schema = JsonSchema.parse!(JSON.parse(File.read(path)))
        store.add_schema(schema)
      end
      store.each { |_, s| s.expand_references!(store: store) }
    end
  end
end

RSpec.configure do |config|
  config.include SmokeHttp, :smoke
  config.include SmokeSchema, :smoke
end
