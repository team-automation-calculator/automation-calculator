require 'rails_helper'

RSpec.describe HealthCheckController, type: :controller do
  def expected_response
    {
      current_time_in_unix: Time.current.to_i,
      short_commit_hash: ENV['SHORT_COMMIT_HASH']
    }.to_json
  end

  describe '#health' do
    it 'returns response in json format' do
      get :health
      expect(response.content_type).to eq('application/json')
    end

    it 'returns git commit hash and unix timestamp' do
      get :health
      expect(response.body).to eq(expected_response)
    end
  end
end
