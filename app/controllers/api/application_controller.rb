module Api
  class ApplicationController < ActionController::API
    rescue_from ActiveRecord::RecordNotFound do
      head :not_found
    end

    rescue_from ActiveRecord::RecordInvalid do
      head :unprocessable_entity
    end
  end
end
