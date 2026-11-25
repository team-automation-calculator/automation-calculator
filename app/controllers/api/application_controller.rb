module API
  class ApplicationController < ActionController::API
    rescue_from ActiveRecord::RecordNotFound do |error|
      logger.info("API 404: #{error.class}: #{error.message}")
      head :not_found
    end

    rescue_from ActiveRecord::RecordInvalid do |error|
      logger.info("API 422: #{error.class}: #{error.message}")
      head :unprocessable_content
    end
  end
end
