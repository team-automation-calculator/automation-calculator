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

  shared_examples_for 'a correct automation scenario response' do
    it 'returns scenario data' do
      expect(json_response.symbolize_keys).to include scenario_attributes
    end
    it { expect(response.headers['Access-Token']).to be_blank }
    it { expect(response).to have_http_status(:ok) }
    it { expect(response).to match_json_schema('automation_scenario') }
  end

  shared_examples_for 'a correct automation scenario owner' do
    let!(:automation_scenario) { current_member.automation_scenarios.first }

    describe '.index' do
      before { v1_get '/api/automation_scenarios' }

      it { expect(json_response.size).to eq 1 }
      it 'returns scenario data' do
        expect(json_response.first.symbolize_keys).to include(
          id: automation_scenario.id,
          display_name: automation_scenario.display_name,
          iteration_count: automation_scenario.iteration_count
        )
      end
      it { expect(response.headers['Access-Token']).to be_blank }
      it { expect(response).to have_http_status(:ok) }
      it { expect(response).to match_json_schema('automation_scenarios') }
    end

    describe '.create' do
      before do
        v1_post '/api/automation_scenarios', params: {
          name: 'test', iteration_count: 20
        }
      end

      it_behaves_like 'a correct automation scenario response' do
        let(:scenario_attributes) do
          {
            display_name: 'test',
            iteration_count: 20
          }
        end
      end

      context 'when inspecting the automation scenario attributes' do
        subject(:created_automation_scenario) do
          AutomationScenario.find json_response['id']
        end

        its(:owner_id) { is_expected.to eq current_member.id }
        its(:owner_type) { is_expected.to eq current_member.class.name }
      end
    end

    context 'when working with a scenario' do
      let!(:automation_scenario) { current_member.automation_scenarios.first }

      describe '.show' do
        before { v1_get "/api/automation_scenarios/#{automation_scenario.id}" }

        it_behaves_like 'a correct automation scenario response' do
          let(:scenario_attributes) do
            {
              id: automation_scenario.id,
              display_name: automation_scenario.display_name,
              iteration_count: automation_scenario.iteration_count
            }
          end
        end
      end

      describe '.update' do
        before do
          v1_put  "/api/automation_scenarios/#{automation_scenario.id}",
                  params: { name: 'updated_name', iteration_count: 35 }
        end

        it_behaves_like 'a correct automation scenario response' do
          let(:scenario_attributes) do
            {
              id: automation_scenario.id,
              display_name: 'updated_name',
              iteration_count: 35
            }
          end
        end
      end

      describe '.destroy' do
        before do
          v1_delete "/api/automation_scenarios/#{automation_scenario.id}"
        end

        it { expect(response.headers['Access-Token']).to be_blank }
        it { expect(response).to have_http_status(:ok) }
        it { expect(response.body).to be_blank }
      end
    end
  end

  # rubocop:disable RSpec/LetSetup
  context 'when a user is logged in properly' do
    let!(:current_member) { v1_login_user }

    it_behaves_like 'a correct automation scenario owner'
  end

  context 'when a visitor is logged in properly' do
    let!(:current_member) { v1_login_visitor }

    it_behaves_like 'a correct automation scenario owner'
  end
  # rubocop:enable RSpec/LetSetup
end
