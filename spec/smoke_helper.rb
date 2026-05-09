require 'net/http'
require 'net/https'
require 'json'
require 'nokogiri'
require 'json_schema'

module SmokeHttp
  BASE_URL = ENV.fetch('SMOKE_TARGET_URL', 'http://localhost:3001').freeze
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

  def create_smoke_scenario(attrs)
    path = '/api/automation_scenarios'
    response = smoke_v1_post(path, body: attrs, token: token)
    expect_smoke_created!(path, response)
    JSON.parse(response.body).fetch('id')
  end

  def create_smoke_solution(scenario_id, attrs)
    path = "/api/automation_scenarios/#{scenario_id}/solutions"
    response = smoke_v1_post(path, body: attrs, token: token)
    expect_smoke_created!(path, response)
    JSON.parse(response.body).fetch('id')
  end

  def expect_smoke_created!(path, response)
    msg = "POST #{path} failed: #{response.code} #{response.body}"
    expect(response.code.to_i).to eq(201), msg
  end

  private

  def smoke_http(uri)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = uri.scheme == 'https'
    http
  end
end

module SmokeSchema
  SCHEMA_DIR = File.expand_path('support/api_schemas', __dir__).freeze

  def validate_schema!(schema_name, body)
    data = body.is_a?(String) ? JSON.parse(body) : body
    schema = SmokeSchema.schemas.fetch(schema_name) do
      raise "Unknown schema: #{schema_name}"
    end
    valid, errors = schema.validate(data)
    return if valid

    raise "Schema mismatch for #{schema_name}: " \
          "#{errors.map(&:message).join(', ')}"
  end

  def self.schemas
    @schemas ||= load_schemas
  end

  # Parse every schema in SCHEMA_DIR, register them under canonical
  # `file:///<basename>` URIs, then expand $refs using a shared store.
  # Without canonical URIs, schemas missing an `id` collide on `"/"`
  # in the DocumentStore and $refs fail to resolve.
  def self.load_schemas
    store = JsonSchema::DocumentStore.new
    parsed = {}
    Dir[File.join(SCHEMA_DIR, '*.json')].each do |path|
      schema = JsonSchema.parse!(JSON.parse(File.read(path)))
      schema.uri = "file:///#{File.basename(path)}"
      store.add_schema(schema)
      parsed[File.basename(path)] = schema
    end
    parsed.each_value { |s| s.expand_references!(store: store) }
    parsed
  end
end

RSpec.configure do |config|
  config.include SmokeHttp, :smoke
  config.include SmokeSchema, :smoke
end
