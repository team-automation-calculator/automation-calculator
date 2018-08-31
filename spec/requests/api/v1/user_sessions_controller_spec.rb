require 'rails_helper'

RSpec.describe API::V1::UserSessionsController, type: :request do
  before { v1_post '/api/sign_in', params: params.to_json }

  context 'with valid attributes' do
    let(:user) { create :user }
    let(:params) do
      {
        email: user.email,
        password: user.password
      }
    end

    it 'returns user data' do
      expect(json_response).to include(
        id: user.id,
        email: user.email
      )
    end

    it { expect(response.headers['Access-Token']).to be_present }
    it { expect(response).to be_successful }
    it { expect(response).to match_json_schema('user') }
  end

  context 'with invalid email' do
    let(:user) { create :user }
    let(:params) do
      {
        email: 'invalid',
        password: user.password
      }
    end

    it { expect(response.body).to be_blank }
    it { expect(response.headers['Access-Token']).to be_blank }
    it { expect(response).to have_http_status(:not_found) }
  end

  context 'with invalid password' do
    let(:user) { create :user }
    let(:params) do
      {
        email: user.email,
        password: 'password'
      }
    end

    it { expect(response.body).to be_blank }
    it { expect(response.headers['Access-Token']).to be_blank }
    it { expect(response).to have_http_status(:unauthorized) }
  end
end
