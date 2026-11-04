require 'rails_helper'

RSpec.describe API::V1::Users::ProfilesController, type: :request do
  context 'when a user is not logged in' do
    describe '.show' do
      before { v1_get '/api/users/profile' }

      it_behaves_like 'an unauthenticated api request'
    end

    describe '.update' do
      before do
        v1_put '/api/users/profile', params: { email: 'test@test.com' }
      end

      it_behaves_like 'an unauthenticated api request'
    end

    context 'when a visitor is logged in' do
      before { v1_login_visitor }

      describe '.show' do
        before { v1_get '/api/users/profile' }

        it_behaves_like 'a not found api request'
      end

      describe '.update' do
        before do
          v1_put '/api/users/profile', params: { email: 'test@test.com' }
        end

        it_behaves_like 'a not found api request'
      end
    end
  end

  context 'when a user is logged in' do
    let!(:current_user) { v1_login_user }

    describe '.show' do
      before { v1_get '/api/users/profile' }

      it { expect(response).to have_http_status(:ok) }
      it { expect(response).to match_json_schema('user') }

      it 'returns correct user data' do
        expect(json_response)
          .to include(
            email: current_user.email
          )
      end
    end

    describe '.update' do
      let(:new_email) { 'test@test.com' }

      context 'with the correct current password' do
        before do
          v1_put(
            '/api/users/profile',
            params: {
              current_password: current_user.password,
              email: new_email
            }
          )
        end

        it { expect(response).to have_http_status(:ok) }
        it { expect(response).to match_json_schema('user') }

        it 'returns correct user data' do
          expect(json_response)
            .to include(
              email: new_email
            )
        end

        it 'does not return old user data' do
          expect(json_response)
            .not_to include(
              email: current_user.email
            )
        end
      end

      context 'without a current password' do
        before do
          v1_put '/api/users/profile', params: { email: new_email }
        end

        it { expect(response).to have_http_status(:unauthorized) }

        it 'does not change the email' do
          expect(current_user.reload.email)
            .not_to eq(new_email)
        end
      end

      context 'with an incorrect current password' do
        before do
          v1_put(
            '/api/users/profile',
            params: {
              current_password: 'wrong-password',
              email: new_email
            }
          )
        end

        it { expect(response).to have_http_status(:unauthorized) }

        it 'does not change the email' do
          expect(current_user.reload.email)
            .not_to eq(new_email)
        end
      end
    end
  end
end
