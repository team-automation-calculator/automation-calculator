require 'rails_helper'

RSpec.describe API::V1::Users::PasswordsController, type: :request do
  context 'when a user is not logged in' do
    describe '.update' do
      before do
        v1_put '/api/users/profile/password', params: { password: '111111' }
      end

      it_behaves_like 'an unauthenticated api request'
    end

    context 'when a visitor is logged in' do
      before { v1_login_visitor }

      describe '.update' do
        before do
          v1_put '/api/users/profile/password', params: { password: '111111' }
        end

        it_behaves_like 'a not found api request'
      end
    end
  end

  context 'when a user is logged in' do
    let!(:current_user) { v1_login_user }

    describe '.update' do
      let(:new_password) { '222222' }

      before do
        v1_put(
          '/api/users/profile/password',
          params: { password: new_password }
        )
      end

      it { expect(response).to have_http_status(:ok) }
      it { expect(response).to match_json_schema('user') }
      it 'returns old user data' do
        expect(json_response)
          .to include(
            email: current_user.email
          )
      end
      it 'fails to sign in with the old password' do
        expect { v1_login_user(current_user) }
          .to raise_error(/failed/)
      end
      it 'signs in with the new password' do
        current_user.password = new_password
        expect { v1_login_user(current_user) }
          .not_to raise_error
      end
      it 'has a valid password' do
        expect(current_user.reload)
          .to be_valid_password(new_password)
      end
    end
  end
end
