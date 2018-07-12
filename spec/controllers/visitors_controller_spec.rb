require 'rails_helper'

RSpec.describe VisitorsController, type: :controller do
  describe 'GET #create' do
    def perform_action
      post :create
    end

    it 'creates a new visitor model' do
      expect { perform_action }.to change(Visitor, :count).by 1
    end

    it 'creates a new automation_scenario model' do
      expect { perform_action }.to change(AutomationScenario, :count).by 1
    end

    it 'redirects to visitor page' do
      perform_action
      expect(response).to redirect_to(AutomationScenario.last)
    end
  end
end
