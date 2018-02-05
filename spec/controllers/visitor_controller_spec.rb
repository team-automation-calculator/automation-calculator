require 'rails_helper'

RSpec.describe VisitorController, type: :controller do
  describe 'POST #create' do

    describe 'new visitor creation' do
      let(:create_post) { post :create }

      it 'creates a new visitor model' do
        expect { create_post }.to change(Visitor, :count).by 1
      end

      it 'returns http success' do
        create_post
        expect(response).to have_http_status(:success)
      end
    end
  end

  describe 'GET #index' do
    it 'returns http success' do
      get :index
      expect(response).to have_http_status(:success)
    end
  end

  describe 'PUT #update' do
    it 'returns http success' do
      put :update
      expect(response).to have_http_status(:success)
    end
  end

  describe 'DELETE #destroy' do
    it 'returns http success' do
      delete :destroy
      expect(response).to have_http_status(:success)
    end
  end
end
