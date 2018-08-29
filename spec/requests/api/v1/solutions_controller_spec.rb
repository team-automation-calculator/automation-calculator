require 'rails_helper'

RSpec.describe API::V1::SolutionsController, type: :request do
  context 'when a user is not logged in' do
    let!(:automation_scenario) { create :automation_scenario }

    describe '.index' do
      before do
        v1_get "/api/automation_scenarios/#{automation_scenario.id}/solutions"
      end

      it_behaves_like 'an unauthenticated api request'
    end

    describe '.create' do
      before do
        v1_post "/api/automation_scenarios/#{automation_scenario.id}/solutions",
                params: { name: 'test' }
      end

      it_behaves_like 'an unauthenticated api request'
    end

    context 'when working with a scenario' do
      let!(:solution) do
        create :solution, automation_scenario: automation_scenario
      end

      describe '.show' do
        before { v1_get "/api/solutions/#{solution.id}" }

        it_behaves_like 'an unauthenticated api request'
      end

      describe '.update' do
        before do
          v1_put  "/api/solutions/#{solution.id}",
                  params: { name: 'test' }
        end

        it_behaves_like 'an unauthenticated api request'
      end

      describe '.destroy' do
        before do
          v1_delete "/api/solutions/#{solution.id}"
        end

        it_behaves_like 'an unauthenticated api request'
      end
    end
  end

  shared_examples_for 'a correct solution response' do
    it 'returns scenario data' do
      expect(json_response.symbolize_keys).to include solution_attributes
    end
    it { expect(response.headers['Access-Token']).to be_blank }
    it { expect(response).to have_http_status(:ok) }
    it { expect(response).to match_json_schema('solution') }
  end

  shared_examples_for 'correct solution endpoints' do
    let(:automation_scenario) { current_member.automation_scenarios.first }
    let!(:solution) do
      create :solution, automation_scenario: automation_scenario
    end

    describe '.index' do
      before do
        v1_get "/api/automation_scenarios/#{automation_scenario.id}/solutions"
      end

      it { expect(json_response.size).to eq 1 }
      it 'returns scenario data' do
        expect(json_response.first.symbolize_keys).to include(
          id: solution.id,
          display_name: solution.display_name,
          iteration_count: automation_scenario.iteration_count,
          initial_cost: solution.initial_cost,
          iteration_cost: solution.iteration_cost
        )
      end
      it { expect(response.headers['Access-Token']).to be_blank }
      it { expect(response).to have_http_status(:ok) }
      it { expect(response).to match_json_schema('solutions') }
    end

    describe '.create', focus: true do
      before do
        v1_post "/api/automation_scenarios/#{automation_scenario.id}/solutions",
          params: {
            name: 'test', initial_cost: 20, iteration_cost: 30
          }
      end

      it_behaves_like 'a correct solution response' do
        let(:solution_attributes) do
          {
            display_name: 'test',
            iteration_count: 10,
            initial_cost: 20,
            iteration_cost: 30
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

        it_behaves_like 'a correct solution response' do
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

        it_behaves_like 'a correct solution response' do
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

    it_behaves_like 'correct solution endpoints'
  end

  context 'when a visitor is logged in properly' do
    let!(:current_member) { v1_login_visitor }

    it_behaves_like 'correct solution endpoints'
  end
  # rubocop:enable RSpec/LetSetup
end
