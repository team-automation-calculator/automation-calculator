#! /usr/bin/env ruby

require 'json'
require 'net/http'
require 'uri'

MAX_REQUEST_RESPONSE_DELTA_IN_SECONDS = 5
TIMEOUT_ERROR_CODE = 1
REQUEST_FAILURE_ERROR_CODE = 2

DEVELOPMENT_HEALTH_CHECK_URI = URI::HTTP.build(host: 'localhost', path: '/health', port: 3001)
PRODUCTION_HEALTH_CHECK_URI = URI::HTTP.build(host: 'localhost', path: '/health', port: 3001)

def evaluate_successful_response(response_body, request_time)
  response_json = JSON.parse(response_body)
  request_response_delta = response_json['current_time_in_unix'] - request_time
  if(request_response_delta < MAX_REQUEST_RESPONSE_DELTA_IN_SECONDS)
    exit(0)
  else
    exit(TIMEOUT_ERROR_CODE)
  end
end

request_time = Time.now.to_i

response_content = nil

begin
  response_content = Net::HTTP.get_response(DEVELOPMENT_HEALTH_CHECK_URI)
rescue (StandardError)
  exit(REQUEST_FAILURE_ERROR_CODE)
end

if response_content.is_a? Net::HTTPSuccess
  evaluate_successful_response(response_content.body, request_time)
else
  exit(REQUEST_FAILURE_ERROR_CODE)
end


