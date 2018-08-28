require 'rails_helper'

RSpec.describe API::V1::VisitorsController, type: :request do
  context 'with valid attributes' do
    before { v1_post '/api/visitor' }

    it 'returns correct visitor data' do
      expect(json_response)
        .to include(
          ip: '127.0.0.1'
        )
    end

    it { expect(response).to have_http_status(:success) }
    it { expect(response.headers['Access-Token']).to be_present }
    it { expect(response).to match_json_schema('visitor') }
  end
end
