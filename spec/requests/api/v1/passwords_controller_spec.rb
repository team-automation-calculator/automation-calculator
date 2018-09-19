require 'rails_helper'

RSpec.describe API::V1::PasswordsController, type: :request do
  include ActiveJob::TestHelper
  let!(:user) { create :user }

  def reset_password
    v1_put '/api/reset_password', params: params.to_json
  end

  context 'with valid attributes' do
    let(:params) { { email: user.email } }

    it 'sends an email' do
      perform_enqueued_jobs do
        expect { reset_password }
          .to change(ActionMailer::Base.deliveries, :length).by(1)
      end
    end

    context 'when inspecting the response' do
      before { reset_password }

      it { expect(response).to have_http_status(:ok) }
      it { expect(response.body).to be_blank }
    end
  end

  context 'when a user is missing' do
    let(:params) { { email: 'wrong@email.com' } }

    it 'does not send an email' do
      perform_enqueued_jobs do
        expect { reset_password }
          .not_to change(ActionMailer::Base.deliveries, :length)
      end
    end

    context 'when inspecting the response' do
      before { reset_password }

      it { expect(response).to have_http_status(:not_found) }
      it { expect(response.body).to be_blank }
    end
  end
end
