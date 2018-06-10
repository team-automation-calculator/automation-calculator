require 'rails_helper'

RSpec.describe HomeController, type: :controller do
  describe '#index' do
    it 'is protected from unauthorized users' do
      get :index
      expect(response).to redirect_to(new_user_session_path)
    end

    it 'is accessible to registered users' do
      sign_in create(:user)

      get :index
      expect(response).to be_successful
    end
  end
end
