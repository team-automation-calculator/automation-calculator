require 'rails_helper'

RSpec.describe API::V1::UsersController, type: :request do
  let(:params) do
    attributes_for :user
  end

  context 'with valid attributes' do
    before { v1_post '/api/sign_up', params: params.to_json }

    it 'returns correct user data' do
      expect(json_response)
        .to include(
          email: params[:email]
        )
    end

    it 'is successful' do
      expect(response).to have_http_status(:success)
    end

    it { expect(response).to match_json_schema('user') }
  end

  context 'when a user exists' do
    let!(:user) { create :user }
    let(:params) { user.attributes }

    before { v1_post '/api/sign_up', params: params.to_json }

    it 'returns nothing' do
      expect(response.body).to be_blank
    end

    it 'is not successful' do
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end
end
