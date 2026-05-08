class HealthCheckController < ApplicationController
  def health
    db_ok = database_reachable?
    render json: {
      current_time_in_unix: Time.current.to_i,
      short_commit_hash: ENV['SHORT_COMMIT_HASH'],
      database: db_ok ? 'ok' : 'unavailable'
    }, status: db_ok ? :ok : :service_unavailable
  end

  private

  def database_reachable?
    ActiveRecord::Base.connection.execute('SELECT 1')
    true
  rescue StandardError
    false
  end
end
