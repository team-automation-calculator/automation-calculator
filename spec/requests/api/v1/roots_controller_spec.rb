require 'rails_helper'

RSpec.describe API::V1::RootsController, type: :request do
  describe 'show' do
    before { v1_get '/api' }

    it 'returns a success response' do
      expect(response).to be_successful
    end

    it 'returns an empty body' do
      expect(response.body).to be_blank
    end
  end
end
