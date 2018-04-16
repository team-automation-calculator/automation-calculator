require 'rails_helper'

RSpec.describe SolutionsController, type: :controller do
  describe 'GET #show' do
    let(:solution) { create :solution }

    before { get :show, params: { id: solution.id } }

    it 'returns a success response' do
      expect(response).to be_success
    end
  end

  describe 'POST #create' do
    context 'with valid params' do
      let(:automation_scenario) { create :automation_scenario }
      let(:valid_attributes) do
        attributes_for(:solution).merge(
          automation_scenario_id: automation_scenario.id
        )
      end

      it 'creates a new Solution' do
        expect do
          post :create, params: { solution: valid_attributes }
        end.to change(Solution, :count).by(1)
      end

      it 'redirects to the created solution' do
        post :create, params: { solution: valid_attributes }
        expect(response).to redirect_to(automation_scenario)
      end
    end

    context 'with invalid params' do
      let(:invalid_attributes) { { invalid_attribute: 5 } }

      it 'returns a success response' do
        post :create, params: { solution: invalid_attributes }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe 'PUT #update' do
    let(:solution) { create :solution }

    context 'with valid params' do
      let(:new_attributes) do
        {
          initial_cost: 2,
          iteration_cost: 2,
          iteration_count: 2
        }
      end
      let(:wrong_attributes) do
        {
          wrong_attribute: 3,
          another_attribute: 5
        }
      end
      let(:attributes) { new_attributes.merge wrong_attributes }

      it 'updates the requested solution' do
        put :update, params: { id: solution.id, solution: attributes }
        solution.reload
        expect(solution.attributes).to include(new_attributes.stringify_keys)
      end

      it 'renders nothing on success' do
        put :update, params: { id: solution.id, solution: attributes }
        expect(response).to redirect_to(solution)
      end
    end

    context 'with invalid params' do
      let(:invalid_attributes) { { initial_cost: :string_value } }

      it "returns a success response (i.e. to display the 'edit' template)" do
        put :update, params: { id: solution.id, solution: invalid_attributes }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe 'DELETE #destroy' do
    let!(:solution) { create :solution }

    it 'destroys the requested solution' do
      expect do
        delete :destroy, params: { id: solution.id }
      end.to change(Solution, :count).by(-1)
    end

    it 'redirects to the solutions list' do
      delete :destroy, params: { id: solution.id }
      expect(response).to be_success
    end
  end
end
