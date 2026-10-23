require 'net/http'
require 'net/https'
require 'json'
require 'nokogiri'
require 'json_schema'

module SmokeHttp
  BASE_URL = ENV.fetch('SMOKE_TARGET_URL', 'http://localhost:3001').freeze
  V1_HEADERS = {
    'Content-Type' => 'application/json',
    'Accept' => 'application/json; version=1'
  }.freeze

  # Plain GET. Redirects are not followed, so callers can assert on
  # the Location header. Pass `cookie:` to replay a session captured
  # with `smoke_cookie` on an earlier response. Extra request headers
  # (a forged X-Forwarded-Host, say) go in `headers`.
  def smoke_get(path, cookie: nil, headers: {})
    uri = URI("#{BASE_URL}#{path}")
    req = Net::HTTP::Get.new(uri.request_uri)
    req['Cookie'] = cookie if cookie
    headers.each { |name, value| req[name] = value }
    smoke_http(uri).request(req)
  end

  # HTML form submission (application/x-www-form-urlencoded), as a
  # browser sends a button_to form. omniauth 2 only starts an OAuth
  # flow from such a POST, so pass the Rails authenticity token in
  # `fields` and the session cookie it was issued under. Extra request
  # headers (a forged Host, say) go in `headers`; Net::HTTP keeps a
  # Host set here over the one it derives from the URL.
  def smoke_post_form(path, fields, cookie: nil, headers: {})
    uri = URI("#{BASE_URL}#{path}")
    req = Net::HTTP::Post.new(uri.request_uri)
    req['Cookie'] = cookie if cookie
    headers.each { |name, value| req[name] = value }
    req.set_form_data(fields)
    smoke_http(uri).request(req)
  end

  # Net::HTTP has no cookie jar. Collapse a response's Set-Cookie
  # headers into a single Cookie header value for the next request.
  def smoke_cookie(response)
    fields = response.get_fields('set-cookie') || []
    fields.map { |c| c.split(';', 2).first }.join('; ')
  end

  # Parse the query string of a URL into a Hash.
  def smoke_query(url)
    URI.decode_www_form(URI(url).query.to_s).to_h
  end

  # True when smoking a deployed environment (staging or prod), where
  # OAuth credentials are expected to be configured.
  def smoke_deployed_target?
    URI(BASE_URL).host.to_s.end_with?('automation-calculations.io')
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
