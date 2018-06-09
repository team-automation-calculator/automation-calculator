require 'rails_helper'

RSpec.describe AutomationScenariosController, type: :controller do
  let(:automation_scenario) { create(:automation_scenario) }

  describe 'POST #create' do
    describe 'new automation_scenario creation' do
      let(:visitor) { create(:visitor) }
      let(:create_params) do
        {
          automation_scenario:
            { owner_type: 'Visitor', owner_id: visitor.id }
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
      end

      context 'with incorrect params' do
        context 'with incorrect params hash name' do
          let(:create_params) do
            {
              foobar_params:
                { owner_type: 'Visitor', owner_id: visitor.id }
            }
          end

          it 'throws strong params error' do
            expect { create_post }
              .to raise_error(ActionController::ParameterMissing)
          end
        end

        context 'with incorrect params key values' do
          let(:create_params) do
            {
              automation_scenario:
                { foobar_type: 'Foobar', foobar_id: visitor.id }
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
        expect(response).to have_http_status(:success)
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
        automation_scenario: { iteration_count: 10 }
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

    context 'with incorrect id' do
      let(:params) { { id: 0 } }

      it 'raises error' do
        expect { update_put }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end

  describe 'DELETE #destroy' do
    def destroy_delete
      delete :destroy, params: { id: automation_scenario.id }
    end

    it 'returns http success' do
      destroy_delete
      expect(response).to have_http_status(:success)
    end

    it 'deletes model' do
      destroy_delete
      expect { AutomationScenario.find(automation_scenario.id) }
        .to raise_error(ActiveRecord::RecordNotFound)
    end
  end
end
