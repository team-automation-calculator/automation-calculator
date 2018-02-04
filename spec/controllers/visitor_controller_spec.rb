require 'rails_helper'

RSpec.describe VisitorController, type: :controller do
  describe 'POST #create' do
    it 'returns http success' do
      post :create
      expect(response).to have_http_status(:success)
    end
  end

  describe 'GET #read' do
    it 'returns http success' do
      get :read
      expect(response).to have_http_status(:success)
    end
  end

  describe 'PUT #update' do
    it 'returns http success' do
      put :update
      expect(response).to have_http_status(:success)
    end
  end

  describe 'DELETE #delete' do
    it 'returns http success' do
      delete :delete
      expect(response).to have_http_status(:success)
    end
  end
end
