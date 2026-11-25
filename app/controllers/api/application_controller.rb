module API
  class ApplicationController < ActionController::API
    # The record exists but belongs to someone else. The caller gets the
    # same 404 as for a missing id; the log line is a warning, because a
    # run of these is someone probing for other members' data.
    class NotOwnedError < ActiveRecord::RecordNotFound; end

    rescue_from ActiveRecord::RecordNotFound do |error|
      logger.public_send(
        error.is_a?(NotOwnedError) ? :warn : :info,
        "API 404: #{error.class}: #{error.message}"
      )
      head :not_found
    end

    # rate_limit raises this for a request over the limit. Unhandled, Rails
    # answers 429 but also logs the exception with a full backtrace at
    # ERROR, once per throttled request: a flood is exactly when that is
    # least wanted. The warn line from
    # config/initializers/security_event_logging.rb already records it.
    rescue_from ActionController::TooManyRequests do
      head :too_many_requests
    end

    rescue_from ActiveRecord::RecordInvalid do |error|
      logger.info("API 422: #{error.class}: #{error.message}")
      head :unprocessable_content
    end
  end
end
