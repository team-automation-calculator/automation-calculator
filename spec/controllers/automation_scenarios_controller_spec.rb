require 'rails_helper'

RSpec.describe AutomationScenariosController, type: :controller do
  let(:automation_scenario) { create(:automation_scenario) }

  describe 'POST #create' do
    describe 'new automation_scenario creation' do
      let(:visitor) { create(:visitor) }
      let(:create_params) { { owner_type: 'Visitor', owner_id: visitor.id } }
      let(:create_post) { post :create, params: { automation_scenario_create_params: create_params } }

      context 'with correct params' do
        it 'creates a new automation_scenario model' do
          expect { create_post }.to change(AutomationScenario, :count).by 1
        end
        it 'redirects to automation_scenario\'s page' do
          create_post
          expect(response).to redirect_to(action: :show, id: AutomationScenario.last.id)
        end
      end

      context 'with incorrect params' do
        context 'with incorrect params hash name' do
          let(:create_post) { post :create, params: { foobar_params: create_params } }

          it 'throws strong params error' do
            expect { create_post }.to raise_error(ActionController::ParameterMissing)
          end
        end

        context 'with incorrect params key values' do
          let(:create_params) { { foobar_type: 'Foobar', foobar_id: visitor.id } }

          it 'throws strong params error' do
            expect { create_post }.to raise_error(ActiveRecord::RecordInvalid)
          end
        end
      end
    end
  end

  describe 'GET #show' do
    let(:show_get) { get :show, params: { id: automation_scenario.id } }

    it 'routes correctly' do
      assert_generates '/automation_scenarios/1', controller: 'automation_scenarios', action: 'show', id: '1'
    end

    context 'with correct id' do
      it 'returns http success' do
        show_get
        expect(response).to have_http_status(:success)
      end
    end

    context 'with incorrect id' do
      let(:show_get) { get :show, params: { id: 0 } }

      it 'raises error' do
        expect { show_get }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end

  describe 'PUT #update' do
    let(:update_put) { put :update, params: { id: automation_scenario.id } }

    it 'routes correctly' do
      assert_generates '/automation_scenarios/1', controller: 'automation_scenarios', action: 'update', id: '1'
    end

    context 'with correct id' do
      it 'returns http success' do
        update_put
        expect(response).to have_http_status(:success)
      end
    end

    context 'with incorrect id' do
      let(:update_put) { put :update, params: { id: 0 } }

      it 'raises error' do
        expect { update_put }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end

  describe 'DELETE #destroy' do
    let(:destroy_delete) { delete :destroy, params: { id: automation_scenario.id } }

    it 'returns http success' do
      destroy_delete
      expect(response).to have_http_status(:success)
    end

    it 'deletes model' do
      destroy_delete
      expect { AutomationScenario.find(automation_scenario.id) }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end
end
