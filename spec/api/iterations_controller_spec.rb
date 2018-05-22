require 'rails_helper'

RSpec.describe API::IterationsController, type: :request do
  describe 'GET to index' do
    let(:iteration) { create :iteration }

    it 'returns a success response' do
      get '/api/iterations'
      expect(response).to be_success
    end
  end

  describe 'GET #show' do
    let(:iteration) { create :iteration }
    let(:expected_response_path) { '/expected_responses/iterations/getShow.json' }
    let(:expected_response_string) { File.read(File.dirname(__FILE__) + expected_response_path) }
    let(:expected_response) { JSON.parse(expected_response_string) }

    before { get "/api/iterations/#{iteration.id}" }

    it 'returns a success response' do
      expect(response).to be_success
    end

    it 'returns the correct time' do
      expect(json['time']).to eq expected_response['time']
    end

    it 'returns the correct cost' do
      expect(json['cost']).to eq expected_response['cost']
    end

    it 'has an id key/value' do
      expect(json['id']).to be_truthy
    end

    it 'has an automation scenario key/value' do
      expect(json['automation_scenario_id']).to be_truthy
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
        put "/api/iterations/#{iteration.id}", params: { id: iteration.id, iteration: attributes }
      end

      it 'updates the requested iteration' do
        iteration.reload
        expect(iteration.attributes).to include(new_attributes.stringify_keys)
      end

      it 'returns correct status code' do
        expect(response.status).to eq 204
      end
    end

    context 'with invalid params' do
      let(:invalid_attributes) { { cost: :string_value } }

      it 'returns an unprocessable entity response' do
        put "/api/iterations/#{iteration.id}", params: { id: iteration.id, iteration: invalid_attributes }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe 'DELETE #destroy' do
    let(:iteration) { create :iteration }
    let(:another_iteration) { create :iteration }

    before do
      iteration
      another_iteration
    end

    it 'destroys the requested iteration' do
      expect do
        delete "/api/iterations/#{iteration.id}"
      end.to change(Iteration, :count).by(-1)
    end

    it 'returns the correct status code' do
      delete "/api/iterations/#{another_iteration.id}"
      expect(response).to have_http_status(:success)
    end
  end
end
