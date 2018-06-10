require 'rails_helper'

RSpec.describe API::IterationsController, type: :request do
  describe 'GET to index' do
    let(:iteration) { create :iteration }

    it 'returns a success response' do
      get '/api/iterations'
      expect(response).to be_successful
    end
  end

  describe 'GET #show' do
    let(:expected_time) { Time.zone.now.yesterday }
    let(:expected_cost) { 5 }
    let(:iteration) do
      create :iteration, time: expected_time, cost: expected_cost
    end

    before { get "/api/iterations/#{iteration.id}" }

    it 'returns a success response' do
      expect(response).to be_successful
    end

    context 'when inspecting the response' do
      subject { OpenStruct.new JSON.parse(response.body) }

      its(:time)  { is_expected.to eq expected_time.strftime('%FT%T.%LZ') }
      its(:cost)  { is_expected.to eq expected_cost }
      its(:id)    { is_expected.to eq iteration.id }
      its(:automation_scenario_id) { is_expected.to be_present }
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
          post '/api/iterations', params: { iteration: valid_attributes }
        end.to change(Iteration, :count).by(1)
      end

      it 'returns a correct status code' do
        post '/api/iterations', params: { iteration: valid_attributes }
        expect(response.status).to eq 201
      end
    end

    context 'with invalid params' do
      let(:invalid_attributes) { { invalid_attribute: 5 } }

      it 'returns a failure response' do
        post '/api/iterations', params: { iteration: invalid_attributes }
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

      before do
        put "/api/iterations/#{iteration.id}",
            params: { iteration: attributes }
      end

      it 'updates the requested iteration' do
        iteration.reload
        expect(iteration.attributes).to include(new_attributes.stringify_keys)
      end

      it 'returns correct status code' do
        expect(response.status).to eq 204
      end
    end
  end

  describe 'DELETE #destroy' do
    let!(:iteration) { create :iteration }
    let!(:another_iteration) { create :iteration }

    it 'destroys the requested iteration' do
      expect do
        delete "/api/iterations/#{iteration.id}"
      end.to change(Iteration, :count).by(-1)
    end

    it 'returns the correct status code' do
      delete "/api/iterations/#{another_iteration.id}"
      expect(response).to be_successful
    end
  end
end
