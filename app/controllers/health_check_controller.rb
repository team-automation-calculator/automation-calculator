class HealthCheckController < ApplicationController
  def health
    render json: {
      current_time_in_unix: Time.current.to_i,
      short_commit_hash: ENV['SHORT_COMMIT_HASH']
    }
  end
end
