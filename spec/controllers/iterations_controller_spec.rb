require 'rails_helper'

RSpec.describe IterationsController, type: :controller do
  describe 'GET to index' do
    let(:iteration) { create :iteration }

    it 'returns a success response' do
      get :index
      expect(response).to be_success
    end
  end

  describe 'GET #show' do
    let(:iteration) { create :iteration }

    before { get :show, params: { id: iteration.id } }

    it 'returns a success response' do
      expect(response).to be_success
    end
  end

  describe 'POST #create' do
    context 'with valid params' do
      let(:automation_scenario) { create :automation_scenario }
      let(:valid_attributes) do
        attributes_for(:iteration).merge(
          automation_scenario_id: automation_scenario.id
        )
      end

      it 'creates a new Iteration' do
        expect do
          post :create, params: { iteration: valid_attributes }
        end.to change(Iteration, :count).by(1)
      end

      it 'redirects to the created iteration' do
        post :create, params: { iteration: valid_attributes }
        expect(response).to redirect_to(iterations_path)
      end
    end

    context 'with invalid params' do
      let(:invalid_attributes) { { invalid_attribute: 5 } }

      it 'returns a success response' do
        post :create, params: { iteration: invalid_attributes }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe 'PUT #update' do
    let(:iteration) { create :iteration }

    context 'with valid params' do
      let(:new_attributes) do
        {
          cost: 2,
          time: Time.zone.today
        }
      end
      let(:wrong_attributes) do
        {
          wrong_attribute: 3,
          another_attribute: 5,
          iteration_count: 2
        }
      end
      let(:attributes) { new_attributes.merge wrong_attributes }

      it 'updates the requested iteration' do
        put :update, params: { id: iteration.id, iteration: attributes }
        iteration.reload
        expect(iteration.attributes).to include(new_attributes.stringify_keys)
      end

      it 'renders nothing on success' do
        put :update, params: { id: iteration.id, iteration: attributes }
        expect(response).to redirect_to(iterations_path)
      end
    end

    context 'with invalid params' do
      let(:invalid_attributes) { { cost: :string_value } }

      it 'returns a success response (i.e. to display the \'edit\' template)' do
        put :update, params: { id: iteration.id, iteration: invalid_attributes }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe 'DELETE #destroy' do
    let!(:iteration) { create :iteration }

    it 'destroys the requested iteration' do
      expect do
        delete :destroy, params: { id: iteration.id }
      end.to change(Iteration, :count).by(-1)
    end

    it 'redirects to the iterations list' do
      delete :destroy, params: { id: iteration.id }
      expect(response).to redirect_to(iterations_path)
    end
  end
end
