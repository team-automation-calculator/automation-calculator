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

      let(:solution_attributes) do
        {
          id: solution.id,
          display_name: solution.display_name,
          iteration_count: automation_scenario.iteration_count,
          initial_cost: solution.initial_cost,
          iteration_cost: solution.iteration_cost
        }
      end

      it { expect(json_response.size).to eq 1 }
      it 'returns scenario data' do
        expect(json_response.first.symbolize_keys)
          .to include(solution_attributes)
      end
      it { expect(response.headers['Access-Token']).to be_blank }
      it { expect(response).to have_http_status(:ok) }
      it { expect(response).to match_json_schema('solutions') }
    end

    describe '.create' do
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
    end

    context 'when working with a scenario' do
      describe '.show' do
        context 'when working with a correct solution' do
          before { v1_get "/api/solutions/#{solution.id}" }

          it_behaves_like 'a correct solution response' do
            let(:solution_attributes) do
              {
                id: solution.id,
                display_name: solution.display_name,
                iteration_count: automation_scenario.iteration_count,
                initial_cost: solution.initial_cost,
                iteration_cost: solution.iteration_cost
              }
            end
          end
        end

        context 'when working with another solution' do
          let(:another_solution) { create :solution }

          before { v1_get "/api/solutions/#{another_solution.id}" }

          it { expect(response.headers['Access-Token']).to be_blank }
          it { expect(response).to have_http_status(:not_found) }
          it { expect(response.body).to be_blank }
        end
      end

      describe '.update' do
        before do
          v1_put  "/api/solutions/#{solution.id}",
                  params: {
                    name: 'updated_name',
                    initial_cost: 20,
                    iteration_cost: 30
                  }
        end

        it_behaves_like 'a correct solution response' do
          let(:solution_attributes) do
            {
              id: solution.id,
              display_name: 'updated_name',
              iteration_count: 10,
              initial_cost: 20,
              iteration_cost: 30
            }
          end
        end
      end

      describe '.destroy' do
        before do
          v1_delete "/api/solutions/#{solution.id}"
        end

        it { expect(response.headers['Access-Token']).to be_blank }
        it { expect(response).to have_http_status(:ok) }
        it { expect(response.body).to be_blank }
        specify do
          expect { solution.reload }
            .to raise_error(ActiveRecord::RecordNotFound)
        end
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
