require 'rails_helper'

RSpec.describe AutomationScenariosController, type: :controller do
  let(:visitor) { create(:visitor) }
  let(:automation_scenario) { create(:automation_scenario, owner: visitor) }

  # sign in the visitor
  # rubocop:disable RSpec/AnyInstance
  before do
    allow_any_instance_of(ApplicationController)
      .to receive(:current_visitor).and_return(visitor)
  end
  # rubocop:enable RSpec/AnyInstance

  describe 'POST #create' do
    describe 'new automation_scenario creation' do
      let(:create_params) do
        {
          automation_scenario: { iteration_count: 7, name: 'Test name' }
        }
      end

      def create_post
        post :create, params: create_params
      end

      context 'with correct params' do
        it 'creates a new automation_scenario model' do
          expect { create_post }.to change(AutomationScenario, :count).by 1
        end

        it 'redirects to automation_scenario\'s page' do
          create_post
          expect(response).to redirect_to(AutomationScenario.last)
        end

        context 'when inspecting the scenario attributes' do
          before { create_post }

          subject(:last_scenario) { AutomationScenario.last }

          its(:iteration_count) { is_expected.to eq 7 }
          its(:name) { is_expected.to eq 'Test name' }
          its(:display_name) { is_expected.to eq 'Test name' }

          context 'with empty name' do
            let(:create_params) do
              {
                automation_scenario: { iteration_count: 8 }
              }
            end

            its(:iteration_count) { is_expected.to eq 8 }
            its(:name) { is_expected.to be_blank }
            its(:display_name) do
              is_expected.to eq "Automation Scenario ##{last_scenario.id}"
            end
          end
        end
      end

      context 'with incorrect params' do
        context 'with incorrect params hash name' do
          let(:create_params) { { foobar_params: {} } }

          it 'throws strong params error' do
            expect { create_post }
              .to raise_error(ActionController::ParameterMissing)
          end
        end

        context 'with incorrect values' do
          let(:create_params) do
            {
              automation_scenario: { iteration_count: 'Foobar' }
            }
          end

          it 'throws strong params error' do
            expect { create_post }.to raise_error(ActiveRecord::RecordInvalid)
          end
        end
      end
    end
  end

  describe 'GET #show' do
    let(:params) { { id: automation_scenario.id } }

    def show_get
      get :show, params: params
    end

    context 'with correct id' do
      it 'returns http success' do
        show_get
        expect(response).to be_successful
      end
    end

    context 'with incorrect id' do
      let(:params) { { id: 0 } }

      it 'raises error' do
        expect { show_get }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end

  describe 'PUT #update' do
    let(:params) do
      {
        id: automation_scenario.id,
        automation_scenario: {
          iteration_count: 11,
          name: 'Another name'
        }
      }
    end

    def update_put
      put :update, params: params
    end

    context 'with correct id' do
      it 'returns http success' do
        update_put
        expect(response).to redirect_to(automation_scenario)
      end
    end

    context 'when inspecting the scenario attributes' do
      before { update_put }

      subject { automation_scenario.reload }

      its(:iteration_count) { is_expected.to eq 11 }
      its(:name) { is_expected.to eq 'Another name' }
      its(:display_name) { is_expected.to eq 'Another name' }
    end

    context 'with incorrect id' do
      let(:params) { { id: 0 } }

      it 'raises error' do
        expect { update_put }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context 'with a solution' do
      let(:params) do
        {
          id: automation_scenario.id,
          automation_scenario: {
            iteration_count: 11,
            name: 'Another name',
            solutions_attributes: [{
              initial_cost: 5,
              iteration_cost: 6,
              name: 'New solution'
            }]
          }
        }
      end

      it 'creates a solution' do
        expect { update_put }.to change(Solution, :count).by(1)
      end

      context 'when inspecting the solution attributes' do
        before { update_put }

        subject { Solution.last }

        its(:initial_cost) { is_expected.to eq 5 }
        its(:iteration_cost) { is_expected.to eq 6 }
        its(:name) { is_expected.to eq 'New solution' }
        its(:display_name) { is_expected.to eq 'New solution' }
        its(:automation_scenario_id) do
          is_expected.to eq automation_scenario.id
        end
        its(:cost) { is_expected.to eq 5 + 6 * 11 }
      end
    end
  end

  describe 'DELETE #destroy' do
    def destroy_delete
      delete :destroy, params: { id: automation_scenario.id }
    end

    it 'returns http success' do
      destroy_delete
      expect(response).to be_successful
    end

    it 'deletes model' do
      destroy_delete
      expect { AutomationScenario.find(automation_scenario.id) }
        .to raise_error(ActiveRecord::RecordNotFound)
    end
  end

  describe 'GET #index' do
    def index_get
      get :index
    end

    it 'returns http success' do
      index_get
      expect(response).to be_successful
    end
  end
end
