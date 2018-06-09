require 'rails_helper'

RSpec.describe VisitorsController, type: :controller do
  describe 'GET #create' do
    describe 'new visitor creation' do
      let(:create_get) { get :create }

      it 'creates a new visitor model' do
        expect { create_get }.to change(Visitor, :count).by 1
      end

      it 'creates a new automation_scenario model' do
        expect { create_get }.to change(AutomationScenario, :count).by 1
      end

      it 'redirects to visitor page' do
        create_get
        expect(response).to redirect_to(AutomationScenario.last)
      end
    end
  end

  describe 'GET #index' do
    it 'redirects to create' do
      get :index
      expect(response).to redirect_to(action: :create)
    end
  end

  describe 'GET #show' do
    let(:visitor) { create(:visitor) }

    it 'returns http success' do
      get :show, params: { id: visitor.id }
      expect(response).to have_http_status(:success)
    end
  end

  describe 'DELETE #destroy' do
    let(:visitor) { create(:visitor) }

    before do
      delete :destroy, params: { id: visitor.id }
    end

    it 'returns http success' do
      expect(response).to have_http_status(:success)
    end

    it 'removes model' do
      expect { Visitor.find(visitor.id) }
        .to raise_error(ActiveRecord::RecordNotFound)
    end
  end
end
