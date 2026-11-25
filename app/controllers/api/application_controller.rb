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

    rescue_from ActiveRecord::RecordInvalid do |error|
      logger.info("API 422: #{error.class}: #{error.message}")
      head :unprocessable_content
    end
  end
end
