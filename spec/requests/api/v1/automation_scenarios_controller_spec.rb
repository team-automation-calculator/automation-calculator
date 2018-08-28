require 'rails_helper'

RSpec.describe API::V1::AutomationScenariosController, type: :request do
  context 'when a user is not logged in' do
    describe '.index' do
      before { v1_get '/api/automation_scenarios' }

      it_behaves_like 'an unauthenticated api request'
    end

    describe '.create' do
      before do
        v1_post '/api/automation_scenarios',
                params: { name: 'test' }
      end

      it_behaves_like 'an unauthenticated api request'
    end

    context 'when working with a scenario' do
      let!(:automation_scenario) { create :automation_scenario }

      describe '.show' do
        before { v1_get "/api/automation_scenarios/#{automation_scenario.id}" }

        it_behaves_like 'an unauthenticated api request'
      end

      describe '.update' do
        before do
          v1_put  "/api/automation_scenarios/#{automation_scenario.id}",
                  params: { name: 'test' }
        end

        it_behaves_like 'an unauthenticated api request'
      end

      describe '.destroy' do
        before do
          v1_delete "/api/automation_scenarios/#{automation_scenario.id}"
        end

        it_behaves_like 'an unauthenticated api request'
      end
    end
  end

  shared_examples_for 'a correct automation scenario owner' do
    let!(:automation_scenario) do
      create :automation_scenario, owner: current_member
    end

    describe '.index', focus: true do
      before { v1_get '/api/automation_scenarios' }

      xit { expect(json_response.size).to eq 1 }
      xit 'returns scenario data' do
        expect(json_response.first).to include(
          id: automation_scenario.id,
          display_name: automation_scenario.display_name,
          iteration_count: automation_scenario.iteration_count
        )
      end
      xit { expect(response.headers['Access-Token']).to be_present }
      it { expect(response).to be_successful }
      xit { expect(response).to match_json_schema('automation_scenario') }
    end

    describe '.create' do
      before do
        v1_post '/api/automation_scenarios',
                params: { name: 'test' }
      end

      it_behaves_like 'an unauthenticated api request'
    end

    context 'when working with a scenario' do
      describe '.show' do
        before { v1_get "/api/automation_scenarios/#{automation_scenario.id}" }

        it_behaves_like 'an unauthenticated api request'
      end

      describe '.update' do
        before do
          v1_put  "/api/automation_scenarios/#{automation_scenario.id}",
                  params: { name: 'test' }
        end

        it_behaves_like 'an unauthenticated api request'
      end

      describe '.destroy' do
        before do
          v1_delete "/api/automation_scenarios/#{automation_scenario.id}"
        end

        it_behaves_like 'an unauthenticated api request'
      end
    end
  end

  context 'when a user is logged in properly' do
    let!(:current_member) { v1_login_user }

    it_behaves_like 'a correct automation scenario owner'
  end

  xcontext 'when a visitor is logged in properly' do
    let!(:current_member) { v1_login_visitor }

    it_behaves_like 'a correct automation scenario owner'
  end
end
