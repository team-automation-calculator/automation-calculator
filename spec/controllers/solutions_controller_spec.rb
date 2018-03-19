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
      let(:valid_attributes) { attributes_for :solution }

      it 'creates a new Solution' do
        expect do
          post :create, params: { solution: valid_attributes }
        end.to change(Solution, :count).by(1)
      end

      it 'redirects to the created solution' do
        post :create, params: { solution: valid_attributes }
        expect(response).to redirect_to(Solution.last)
      end
    end

    context 'with invalid params' do
      let(:invalid_attributes) { {} }

      it 'returns a success response' do
        post :create, params: { solution: invalid_attributes }
        expect(response).to be_success
      end
    end
  end

  describe 'PUT #update' do
    context 'with valid params' do
      let(:solution) { create :solution }

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

      it 'updates the requested solution' do
        attributes = new_attributes.merge wrong_attributes
        put :update, params: { id: solution.id, solution: attributes }
        solution.reload
        expect(solution.attributes).to include(new_attributes)
      end

      it 'renders nothing on success' do
        put :update, params: { id: solution.id, solution: valid_attributes }
        expect(response).to be_success
      end
    end

    context 'with invalid params' do
      it "returns a success response (i.e. to display the 'edit' template)" do
        solution = Solution.create! valid_attributes
        put :update, params: { id: solution.to_param, solution: invalid_attributes }
        expect(response).to be_success
      end
    end
  end

  describe 'DELETE #destroy' do
    let(:solution) { create :solution }

    it 'destroys the requested solution' do
      expect do
        delete :destroy, params: { id: solution.id }
      end.to change(Solution, :count).by(-1)
    end

    it 'redirects to the solutions list' do
      delete :destroy, params: { id: solution.to_param }
      expect(response).to be_success
    end
  end
end
