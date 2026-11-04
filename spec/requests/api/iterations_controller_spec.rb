require 'rails_helper'

RSpec.describe API::IterationsController, type: :request do
  let(:member) { v1_login_user }
  let(:scenario) { create :automation_scenario, owner: member }
  let(:iteration) { create :iteration, automation_scenario: scenario }

  describe 'without authentication' do
    # A record owned by someone else; an anonymous caller must not reach it.
    let!(:other_iteration) { create :iteration }

    describe 'GET #index' do
      before { get '/api/iterations' }

      it_behaves_like 'an unauthenticated api request'
    end

    describe 'GET #show' do
      before { get "/api/iterations/#{other_iteration.id}" }

      it_behaves_like 'an unauthenticated api request'
    end

    describe 'POST #create' do
      before do
        post '/api/iterations',
             params: { iteration: {
               time: Time.zone.now, cost: 5,
               automation_scenario_id: other_iteration.automation_scenario_id
             } }
      end

      it_behaves_like 'an unauthenticated api request'

      it 'creates no iteration' do
        expect(Iteration.count).to eq 1
      end
    end

    describe 'PUT #update' do
      before do
        put "/api/iterations/#{other_iteration.id}",
            params: { iteration: { cost: 99 } }
      end

      it_behaves_like 'an unauthenticated api request'

      it 'does not change the iteration' do
        expect(other_iteration.reload.cost).not_to eq 99
      end
    end

    describe 'DELETE #destroy' do
      before { delete "/api/iterations/#{other_iteration.id}" }

      it_behaves_like 'an unauthenticated api request'

      it 'does not destroy the iteration' do
        expect(Iteration.exists?(other_iteration.id)).to be true
      end
    end
  end

  describe 'as an authenticated member' do
    before { member }

    describe 'GET #show' do
      before { v1_get "/api/iterations/#{iteration.id}" }

      it 'returns the iteration' do
        expect(response).to have_http_status(:ok)
        expect(JSON.parse(response.body)['id']).to eq iteration.id
      end
    end

    describe 'POST #create' do
      context 'with a scenario the member owns' do
        let(:params) do
          { iteration: {
            time: Time.zone.now, cost: 5,
            automation_scenario_id: scenario.id
          } }
        end

        it 'creates an iteration on that scenario' do
          expect { v1_post '/api/iterations', params: params }
            .to change(scenario.iterations, :count).by(1)
          expect(response).to have_http_status(:created)
        end
      end

      context 'with invalid attributes' do
        let(:params) do
          { iteration: { cost: -1, automation_scenario_id: scenario.id } }
        end

        it 'is unprocessable' do
          v1_post '/api/iterations', params: params
          expect(response).to have_http_status(:unprocessable_content)
        end
      end
    end

    describe 'PUT #update' do
      it 'updates the iteration' do
        v1_put "/api/iterations/#{iteration.id}",
               params: { iteration: { cost: 2 } }
        expect(response).to have_http_status(:ok)
        expect(iteration.reload.cost).to eq 2
      end
    end

    describe 'DELETE #destroy' do
      it 'destroys the iteration' do
        iteration
        expect { v1_delete "/api/iterations/#{iteration.id}" }
          .to change(Iteration, :count).by(-1)
      end
    end
  end

  describe "accessing another member's iteration" do
    let(:other_scenario) { create :automation_scenario, owner: create(:user) }
    let!(:other_iteration) { create :iteration, automation_scenario: other_scenario }

    before { member }

    it 'cannot be shown' do
      v1_get "/api/iterations/#{other_iteration.id}"
      expect(response).to have_http_status(:not_found)
    end

    it 'cannot be updated' do
      v1_put "/api/iterations/#{other_iteration.id}",
             params: { iteration: { cost: 99 } }
      expect(response).to have_http_status(:not_found)
      expect(other_iteration.reload.cost).not_to eq 99
    end

    it 'cannot be destroyed' do
      expect { v1_delete "/api/iterations/#{other_iteration.id}" }
        .not_to change(Iteration, :count)
      expect(response).to have_http_status(:not_found)
    end

    it 'cannot receive a new iteration on an unowned scenario' do
      v1_post '/api/iterations',
              params: { iteration: {
                time: Time.zone.now, cost: 5,
                automation_scenario_id: other_scenario.id
              } }
      expect(response).to have_http_status(:not_found)
    end
  end
end
