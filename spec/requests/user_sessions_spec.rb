require 'rails_helper'

RSpec.describe 'User sign in page', type: :request do
  describe 'GET /users/sign_in when already signed in' do
    # login_as triggers Devise's trackable hook, which increments
    # sign_in_count by one before the request is processed.
    let(:user) { create :user, sign_in_count: sign_in_count }

    before do
      login_as user, scope: :user
      get new_user_session_path
    end

    context 'when it is a returning user' do
      let(:sign_in_count) { 5 }

      it 'redirects to the default signed in path' do
        expect(response).to redirect_to(root_path)
      end
    end

    context 'when it is the first sign in and the user has a scenario' do
      let(:sign_in_count) { 0 }

      it 'redirects to the scenario' do
        expect(response).to redirect_to(user.automation_scenarios.first)
      end
    end

    context 'when it is the first sign in and the user has no scenarios' do
      let(:user) do
        create(:user, sign_in_count: 0).tap do |user|
          user.automation_scenarios.destroy_all
        end
      end

      it 'redirects to the default signed in path' do
        expect(response).to redirect_to(root_path)
      end
    end
  end
end
